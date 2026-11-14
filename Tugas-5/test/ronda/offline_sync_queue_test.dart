import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/offline_sync_queue.dart';

void main() {
  group('OfflineSyncQueue Tests (Mekanisme Offline-First Check-in)', () {
    late OfflineSyncQueue queue;

    setUp(() {
      queue = OfflineSyncQueue();
    });

    PatrolCheckin createSampleCheckin(String id) => PatrolCheckin(
          id: id,
          checkpointId: 'CP-POS-01',
          userId: 'user-petugas-01',
          scannedAt: DateTime.now(),
          latitudeUser: -7.281970,
          longitudeUser: 112.795323,
          distanceMeter: 12.5,
          accuracy: 6.0,
          batteryLevel: 85.0,
        );

    test('Enqueue menyimpan rekaman dengan status pending', () {
      final item = createSampleCheckin('chk-001');
      queue.enqueue(item);

      expect(queue.pendingCount, equals(1));
      expect(queue.syncedCount, equals(0));
      expect(item.syncStatus, equals(SyncStatus.pending));
    });

    test('ProcessQueue mengirim seluruh rekaman pending dan menandai status synced', () async {
      queue.enqueue(createSampleCheckin('chk-001'));
      queue.enqueue(createSampleCheckin('chk-002'));

      expect(queue.pendingCount, equals(2));

      // Mock handler: Semua berhasil terkirim
      final syncedCount = await queue.processQueue((checkin) async {
        return true;
      });

      expect(syncedCount, equals(2));
      expect(queue.pendingCount, equals(0));
      expect(queue.syncedCount, equals(2));
    });

    test('Jika server gagal merespon, status diubah menjadi failed dan tetap di antrean pending', () async {
      final item = createSampleCheckin('chk-fail');
      queue.enqueue(item);

      final syncedCount = await queue.processQueue((checkin) async {
        return false; // Server down
      });

      expect(syncedCount, equals(0));
      expect(item.syncStatus, equals(SyncStatus.failed));
      expect(queue.pendingCount, equals(1));
    });

    test('PurgeSynced hanya membersihkan rekaman yang berstatus synced', () async {
      final item1 = createSampleCheckin('chk-ok');
      final item2 = createSampleCheckin('chk-fail');

      queue.enqueue(item1);
      queue.enqueue(item2);

      await queue.processQueue((checkin) async {
        return checkin.id == 'chk-ok'; // Hanya item1 yang sukses
      });

      expect(queue.pendingCount, equals(1));
      expect(queue.syncedCount, equals(1));

      queue.purgeSynced();

      expect(queue.allItems.length, equals(1));
      expect(queue.allItems.first.id, equals('chk-fail'));
    });
  });
}
