import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/schedule.dart';

/// Contract for shift templates, patrol rosters, peer shift swaps, and Buku Mutasi handovers.
abstract interface class ScheduleRepository {
  Stream<List<ShiftTemplate>> watchShiftTemplates(String siteId);

  Future<ShiftTemplate> saveShiftTemplate({
    String? templateId,
    required String siteId,
    required String name,
    required String startTime,
    required String endTime,
    required bool isOvernight,
    bool isActive = true,
  });

  Stream<List<PatrolSchedule>> watchSchedules({
    required String siteId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  Future<List<PatrolSchedule>> generateAutoSchedule({
    required String siteId,
    required AutoScheduleConfig config,
  });

  Future<PatrolSchedule> assignManualShift({
    required String siteId,
    required String officerId,
    String? templateId,
    required String shiftName,
    required DateTime shiftDate,
    required DateTime startsAt,
    required DateTime endsAt,
  });

  Future<void> updateScheduleStatus({
    required String scheduleId,
    required ScheduleStatus status,
  });

  Future<void> deleteSchedule(String scheduleId);

  Stream<List<ShiftSwap>> watchShiftSwaps(String siteId);

  Future<ShiftSwap> requestShiftSwap({
    required String siteId,
    required String scheduleId,
    required String targetOfficerId,
    String? targetScheduleId,
    required String reason,
  });

  Future<ShiftSwap> respondShiftSwap({
    required String swapId,
    required bool accept,
  });

  Stream<List<ShiftHandover>> watchHandovers(String siteId);

  Future<ShiftHandover> submitHandover({
    required String siteId,
    String? fromScheduleId,
    required String summary,
    String assetStatus = '',
    String? localPhotoPath,
    String? clientEventId,
  });

  Future<ShiftHandover> acknowledgeHandover(String handoverId);
}
