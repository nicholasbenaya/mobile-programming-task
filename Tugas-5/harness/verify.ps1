# =====================================================================
# SCRIPT VERIFIKASI & HARNESS RONDA DIGITAL (KELOMPOK 4 TEKNIK KOMPUTER ITS)
# =====================================================================

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  MEMULAI VERIFIKASI HARNESS RONDA DIGITAL (SISKAMLING RT/RW)       " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Pastikan PATH aman dari spasi Windows
$env:PATH = "C:\Users\kegz\flutter\bin;$env:PATH"

# 2. Jalankan Test Suite Otomatis
Write-Host "`n[1/3] Menjalankan Unit & Integration Test Suite..." -ForegroundColor Yellow
flutter test --no-pub test/ronda/

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Ada pengujian yang gagal!" -ForegroundColor Red
    exit 1
}

# 3. Jalankan Skenario Integrasi Lengkap
Write-Host "`n[2/3] Menjalankan Skenario Simulasi Malam Patroli Lengkap..." -ForegroundColor Yellow
dart run harness/run_simulation.dart

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Simulasi malam patroli mengalami kegagalan!" -ForegroundColor Red
    exit 1
}

# 4. Analisis Kode (Linter & Static Analysis)
Write-Host "`n[3/3] Melakukan Analisis Statis Kode (Flutter Analyze)..." -ForegroundColor Yellow
flutter analyze lib/domain/ronda/ harness/ test/ronda/

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[WARNING] Ditemukan peringatan kode pada Flutter Analyze." -ForegroundColor DarkYellow
} else {
    Write-Host "`n[OK] Analisis statis bersih tanpa error!" -ForegroundColor Green
}

Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host "  SELURUH HARNESS TERVERIFIKASI SEMPURNA! SIAP UNTUK DEVELOPMENT UI " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
