import 'package:hive_flutter/hive_flutter.dart';
import 'package:health_connector/health_connector.dart';
import 'package:health_connector/health_connector_internal.dart';
import '../models/vital_data.dart';
import 'dart:developer' as developer;

class VitalsRepository {
  static const String boxName = 'vitals_data_box';
  final HealthConnector? _healthConnector;

  VitalsRepository({HealthConnector? healthConnector}) : _healthConnector = healthConnector;

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  Future<void> saveVitalData(VitalData data) async {
    final box = await _getBox();
    // Key by timestamp to allow multiple entries per day
    final key = data.date.millisecondsSinceEpoch.toString();
    await box.put(key, data.toMap());

    // Write heart rate to Health Connect if available and initialized
    if (data.heartRate != null && _healthConnector != null) {
      try {
        final record = HeartRateRecord(
          startTime: data.date,
          endTime: data.date.add(const Duration(minutes: 1)), // Point in time
          samples: [
            HeartRateSample(
              time: data.date,
              beatsPerMinute: data.heartRate!.toDouble(),
            ),
          ],
          metadata: Metadata.manualEntry(),
        );

        await _healthConnector!.writeRecords([record]);
      } catch (e) {
        print('Error writing heart rate to Health Connect: $e');
      }
    }
  }

  Future<List<VitalData>> getVitalsHistory() async {
    final box = await _getBox();
    final List<VitalData> hiveList = [];
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i) as Map<dynamic, dynamic>;
      hiveList.add(VitalData.fromMap(map));
    }

    // Fetch Heart Rate from Health Connect
    List<VitalData> hcList = [];
    if (_healthConnector != null) {
      try {
        final now = DateTime.now();
        final startTime = now.subtract(const Duration(days: 30));

        final response = await _healthConnector!.readRecords(
          ReadRecordsInTimeRangeRequest(
            dataType: HealthDataType.heartRate,
            startTime: startTime,
            endTime: now,
          ),
        );

        final records = response.records.whereType<HeartRateRecord>().toList();

        for (var r in records) {
           // Average BPM if multiple samples
           if (r.samples.isNotEmpty) {
             final avgBpm = r.samples.map((s) => s.beatsPerMinute).reduce((a, b) => a + b) / r.samples.length;
             hcList.add(VitalData(
               date: r.startTime,
               heartRate: avgBpm.toInt(),
               stressLevel: 0, // Not available in HC
               mood: "", // Not available in HC
             ));
           }
        }
      } catch (e) {
        print('Error fetching heart rate from Health Connect: $e');
      }
    }

    // Merge lists
    // We prioritize Hive data for Mood/Stress, but we want to merge Heart Rate.
    // Since timestamps won't match exactly, we can list them all or try to group by day?
    // The dashboard shows "Vitals & Mood".
    // If we have separate entries (one for HR, one for Mood), that's fine.
    // Or we can try to merge if they are close in time.
    // For simplicity, let's combine and sort.

    final combined = [...hiveList, ...hcList];

    // Sort by date descending
    combined.sort((a, b) => b.date.compareTo(a.date));

    return combined;
  }
}
