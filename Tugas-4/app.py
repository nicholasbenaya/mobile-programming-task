"""SensorLog: local GPS and photo capture server (standard library only)."""

from __future__ import annotations

import base64
import csv
import io
import json
import mimetypes
import re
import sqlite3
import uuid
import os
import urllib.request
import socket
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parent
STATIC = ROOT / "static"
DATA = ROOT / "data"
UPLOADS = ROOT / "uploads"
DB = DATA / "sensorlog.sqlite3"
MAX_BODY = 11 * 1024 * 1024
MAX_IMAGE = 8 * 1024 * 1024
IMAGE_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
PNG = b"\x89PNG\r\n\x1a\n"
JPEG = b"\xff\xd8\xff"
WEBP = b"RIFF"


def database():
    connection = sqlite3.connect(DB)
    connection.row_factory = sqlite3.Row
    return connection


def initialize():
    DATA.mkdir(exist_ok=True)
    UPLOADS.mkdir(exist_ok=True)
    with database() as db:
        db.execute("""CREATE TABLE IF NOT EXISTS records (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            note TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            image_filename TEXT NOT NULL,
            compass REAL,
            tilt REAL,
            battery REAL,
            ai_suggestion TEXT,
            sync_status TEXT NOT NULL DEFAULT 'local'
        )""")
        # Keep existing installations compatible after upgrading.
        for column, definition in (("compass", "REAL"), ("tilt", "REAL"), ("battery", "REAL"), ("ai_suggestion", "TEXT"), ("sync_status", "TEXT NOT NULL DEFAULT 'local'")):
            try:
                db.execute(f"ALTER TABLE records ADD COLUMN {column} {definition}")
            except sqlite3.OperationalError:
                pass


def supabase_sync(record):
    """Best-effort metadata sync using Supabase REST; local save always wins."""
    base, key = os.getenv("SUPABASE_URL", "").rstrip("/"), os.getenv("SUPABASE_ANON_KEY", "")
    if not base or not key:
        return "local"
    body = json.dumps(record).encode("utf-8")
    request = urllib.request.Request(base + "/rest/v1/records", data=body, method="POST", headers={"apikey": key, "Authorization": "Bearer " + key, "Content-Type": "application/json", "Prefer": "return=minimal"})
    try:
        with urllib.request.urlopen(request, timeout=5):
            return "supabase"
    except Exception:
        return "local"


def check_image(data_url):
    if not isinstance(data_url, str):
        raise ValueError("Foto wajib diisi.")
    match = re.fullmatch(r"data:(image/jpeg|image/png|image/webp);base64,([A-Za-z0-9+/=]+)", data_url)
    if not match:
        raise ValueError("Format foto harus JPEG, PNG, atau WebP.")
    mime, encoded = match.groups()
    if len(encoded) > MAX_IMAGE * 4 // 3 + 8:
        raise ValueError("Ukuran foto maksimal 8 MB.")
    try:
        image = base64.b64decode(encoded, validate=True)
    except (ValueError, base64.binascii.Error):
        raise ValueError("Data foto tidak valid.") from None
    if not image or len(image) > MAX_IMAGE:
        raise ValueError("Ukuran foto maksimal 8 MB.")
    valid = ((mime == "image/jpeg" and image.startswith(JPEG)) or
             (mime == "image/png" and image.startswith(PNG)) or
             (mime == "image/webp" and image.startswith(WEBP) and image[8:12] == b"WEBP"))
    if not valid:
        raise ValueError("Isi foto tidak cocok dengan formatnya.")
    return image, IMAGE_TYPES[mime]


def number(value, label, low, high):
    try:
        result = float(value)
    except (TypeError, ValueError):
        raise ValueError(f"{label} tidak valid.") from None
    if not low <= result <= high:
        raise ValueError(f"{label} di luar rentang yang diizinkan.")
    return result


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, body, content_type="application/json; charset=utf-8"):
        if isinstance(body, (dict, list)):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/api/records":
            with database() as db:
                rows = db.execute("SELECT * FROM records ORDER BY created_at DESC").fetchall()
            self.respond(200, [dict(row) for row in rows])
            return
        if path == "/api/export.csv":
            with database() as db:
                rows = db.execute("SELECT * FROM records ORDER BY created_at DESC").fetchall()
            stream = io.StringIO()
            fields = ["id", "created_at", "title", "category", "note", "latitude", "longitude", "accuracy", "image_filename"]
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(dict(row) for row in rows)
            self.respond(200, "\ufeff".encode("utf-8") + stream.getvalue().encode("utf-8"), "text/csv; charset=utf-8")
            return
        if path.startswith("/uploads/"):
            filename = unquote(path.split("/")[-1])
            if not re.fullmatch(r"[0-9a-f]{32}\.(jpg|png|webp)", filename):
                self.send_error(404)
                return
            file = UPLOADS / filename
        else:
            relative = "index.html" if path == "/" else unquote(path).lstrip("/")
            if relative not in {"index.html", "style.css", "app.js"}:
                self.send_error(404)
                return
            file = STATIC / relative
        if not file.is_file():
            self.send_error(404)
            return
        self.respond(200, file.read_bytes(), mimetypes.guess_type(file.name)[0] or "application/octet-stream")

    def do_POST(self):
        if urlparse(self.path).path != "/api/records":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > MAX_BODY:
                raise ValueError("Data terlalu besar atau kosong.")
            payload = json.loads(self.rfile.read(length))
            title = str(payload.get("title", "")).strip()
            category = str(payload.get("category", "")).strip()
            note = str(payload.get("note", "")).strip()
            if not 1 <= len(title) <= 100:
                raise ValueError("Judul harus berisi 1–100 karakter.")
            if category not in {"Observasi", "Lingkungan", "Infrastruktur", "Lainnya"}:
                raise ValueError("Kategori tidak valid.")
            if len(note) > 1000:
                raise ValueError("Catatan maksimal 1000 karakter.")
            latitude = number(payload.get("latitude"), "Latitude", -90, 90)
            longitude = number(payload.get("longitude"), "Longitude", -180, 180)
            accuracy = number(payload.get("accuracy"), "Akurasi", 0, 100000) if payload.get("accuracy") is not None else None
            compass = number(payload.get("compass"), "Kompas", 0, 360) if payload.get("compass") is not None else None
            tilt = number(payload.get("tilt"), "Kemiringan", -180, 180) if payload.get("tilt") is not None else None
            battery = number(payload.get("battery"), "Baterai", 0, 100) if payload.get("battery") is not None else None
            ai_suggestion = str(payload.get("ai_suggestion", ""))[:500]
            image, suffix = check_image(payload.get("image"))
        except (ValueError, TypeError, json.JSONDecodeError) as exc:
            self.respond(400, {"error": str(exc)})
            return

        record_id = uuid.uuid4().hex
        filename = record_id + suffix
        created_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
        file = UPLOADS / filename
        try:
            file.write_bytes(image)
            record = {"id": record_id, "created_at": created_at, "title": title, "category": category, "note": note, "latitude": latitude, "longitude": longitude, "accuracy": accuracy, "image_filename": filename, "compass": compass, "tilt": tilt, "battery": battery, "ai_suggestion": ai_suggestion}
            sync_status = supabase_sync(record)
            with database() as db:
                db.execute("""INSERT INTO records (id,created_at,title,category,note,latitude,longitude,accuracy,image_filename,compass,tilt,battery,ai_suggestion,sync_status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)""", tuple(record.values()) + (sync_status,))
        except Exception:
            file.unlink(missing_ok=True)
            self.respond(500, {"error": "Gagal menyimpan data. Silakan coba lagi."})
            return
        self.respond(201, {"id": record_id, "image_filename": filename, "sync_status": sync_status})


if __name__ == "__main__":
    initialize()
    address = ("0.0.0.0", 8000)
    try:
        local_ip = socket.gethostbyname(socket.gethostname())
    except OSError:
        local_ip = "IP-KOMPUTER-ANDA"
    print(f"SensorLog lokal: http://127.0.0.1:{address[1]}")
    print(f"Buka dari HP (Wi-Fi yang sama): http://{local_ip}:{address[1]}")
    try:
        ThreadingHTTPServer(address, Handler).serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
