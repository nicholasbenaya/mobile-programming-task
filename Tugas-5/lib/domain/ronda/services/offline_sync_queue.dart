import '../models/ronda_models.dart';

/// Antrean & Mesin Sinkronisasi Data Check-in Patroli Saat Sinyal Terputus (Offline-First)
class OfflineSyncQueue {
  OfflineSyncQueue();

  final List<PatrolCheckin> _queue = [];

  List<PatrolCheckin> get allItems => List.unmodifiable(_queue);

  List<PatrolCheckin> get pendingItems =>
      _queue.where((item) => item.syncStatus == SyncStatus.pending || item.syncStatus == SyncStatus.failed).toList();

  int get pendingCount => pendingItems.length;

  int get syncedCount => _queue.where((item) => item.syncStatus == SyncStatus.synced).length;

  /// Memasukkan catatan patroli offline ke antrean lokal
  void enqueue(PatrolCheckin checkin) {
    checkin.syncStatus = SyncStatus.pending;
    _queue.add(checkin);
  }

  /// Memproses pengiriman antrean ke server saat koneksi internet pulih
  Future<int> processQueue(Future<bool> Function(PatrolCheckin checkin) syncHandler) async {
    var successCount = 0;
    final toSync = pendingItems;

    for (final item in toSync) {
      item.syncStatus = SyncStatus.syncing;
      try {
        final isSuccess = await syncHandler(item);
        if (isSuccess) {
          item.syncStatus = SyncStatus.synced;
          successCount++;
        } else {
          item.syncStatus = SyncStatus.failed;
        }
      } catch (_) {
        item.syncStatus = SyncStatus.failed;
      }
    }

    return successCount;
  }

  /// Menghapus rekaman yang sudah berhasil disinkronisasi dari memori antrean
  void purgeSynced() {
    _queue.removeWhere((item) => item.syncStatus == SyncStatus.synced);
  }

  /// Mengosongkan seluruh antrean (misal saat logout ganti akun)
  void clear() {
    _queue.clear();
  }
}
