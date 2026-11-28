import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Persistent OS-native SQLite database (`rondadigital_offline.db`) storing offline queues.
class OfflineDatabase {
  OfflineDatabase({
    this._customDatabasePath,
    this._databaseFactory,
  });

  static const String databaseFileName = 'rondadigital_offline.db';
  static const int schemaVersion = 1;

  static const String checkinQueueTable = 'offline_checkin_queue';
  static const String reportQueueTable = 'offline_report_queue';
  static const String handoverQueueTable = 'offline_handover_queue';

  final String? _customDatabasePath;
  final DatabaseFactory? _databaseFactory;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbPath = _customDatabasePath ??
        p.join(await getDatabasesPath(), databaseFileName);
    final factory = _databaseFactory;
    if (factory != null) {
      return factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: createSchema,
        ),
      );
    }
    return openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: createSchema,
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $checkinQueueTable (
        client_event_id TEXT PRIMARY KEY,
        site_id TEXT NOT NULL,
        checkpoint_id TEXT NOT NULL,
        schedule_id TEXT,
        officer_id TEXT NOT NULL,
        qr_raw_payload TEXT NOT NULL,
        local_photo_path TEXT NOT NULL,
        photo_sha256 TEXT NOT NULL,
        captured_at_client TEXT NOT NULL,
        monotonic_ms INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy_m REAL NOT NULL,
        is_mocked INTEGER NOT NULL DEFAULT 0,
        device_model TEXT,
        officer_note TEXT NOT NULL DEFAULT '',
        checkpoint_name TEXT,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_offline_checkin_site_state
      ON $checkinQueueTable (site_id, sync_state, created_at)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $reportQueueTable (
        client_event_id TEXT PRIMARY KEY,
        site_id TEXT NOT NULL,
        reporter_id TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        local_photo_path TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_offline_report_site_state
      ON $reportQueueTable (site_id, sync_state, created_at)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $handoverQueueTable (
        client_event_id TEXT PRIMARY KEY,
        site_id TEXT NOT NULL,
        from_schedule_id TEXT,
        author_id TEXT NOT NULL,
        summary TEXT NOT NULL,
        asset_status TEXT NOT NULL DEFAULT '',
        local_photo_path TEXT,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_offline_handover_site_state
      ON $handoverQueueTable (site_id, sync_state, created_at)
    ''');
  }

  Future<void> close() async {
    final existing = _database;
    _database = null;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
  }
}
