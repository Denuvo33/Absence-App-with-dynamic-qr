import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AbsenceController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Observables
  final isLoading = false.obs;
  final clockInTime = Rxn<DateTime>();
  final clockOutTime = Rxn<DateTime>();
  final hasClockIn = false.obs;
  final hasClockOut = false.obs;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onReady() {
    super.onReady();
    loadTodayAttendance();
  }

  // Reset state when switching accounts
  void resetState() {
    clockInTime.value = null;
    clockOutTime.value = null;
    hasClockIn.value = false;
    hasClockOut.value = false;
    historyList.clear();
    isLoading.value = false;
  }

  // Load today's attendance data
  Future<void> loadTodayAttendance() async {
    if (_uid.isEmpty) return;
    try {
      final snapshot = await _db
          .child('attendance')
          .child(_uid)
          .child(_todayKey)
          .get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data['clockIn'] != null) {
          clockInTime.value = DateTime.fromMillisecondsSinceEpoch(
            data['clockIn'] as int,
          );
          hasClockIn.value = true;
        }
        if (data['clockOut'] != null) {
          clockOutTime.value = DateTime.fromMillisecondsSinceEpoch(
            data['clockOut'] as int,
          );
          hasClockOut.value = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
  }

  // Clock In
  Future<void> clockIn() async {
    if (_uid.isEmpty || hasClockIn.value) return;
    try {
      isLoading.value = true;
      final now = DateTime.now();

      await _db.child('attendance').child(_uid).child(_todayKey).update({
        'clockIn': now.millisecondsSinceEpoch,
        'date': _todayKey,
      });

      clockInTime.value = now;
      hasClockIn.value = true;

      Get.snackbar(
        'Clock In Berhasil',
        'Absen masuk tercatat pukul ${DateFormat('HH:mm').format(now)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal melakukan clock in.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clock Out
  Future<void> clockOut() async {
    if (_uid.isEmpty || !hasClockIn.value || hasClockOut.value) return;
    try {
      isLoading.value = true;
      final now = DateTime.now();

      await _db.child('attendance').child(_uid).child(_todayKey).update({
        'clockOut': now.millisecondsSinceEpoch,
      });

      clockOutTime.value = now;
      hasClockOut.value = true;

      Get.snackbar(
        'Clock Out Berhasil',
        'Absen pulang tercatat pukul ${DateFormat('HH:mm').format(now)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal melakukan clock out.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get formatted time
  String formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('HH:mm').format(time);
  }

  // Get work duration
  String getWorkDuration() {
    if (clockInTime.value == null) return '-';
    final end = clockOutTime.value ?? DateTime.now();
    final duration = end.difference(clockInTime.value!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}j ${minutes}m';
  }

  // ─── History ───────────────────────────────────────────────

  final historyList = <Map<String, dynamic>>[].obs;
  final isHistoryLoading = false.obs;
  final selectedMonth = DateTime.now().obs;

  List<Map<String, dynamic>> get filteredHistory {
    final month = selectedMonth.value.month;
    final year = selectedMonth.value.year;
    return historyList
        .where((e) => e['month'] == month && e['year'] == year)
        .toList();
  }

  // Load all attendance history
  Future<void> loadHistory() async {
    if (_uid.isEmpty) return;
    try {
      isHistoryLoading.value = true;
      final snapshot = await _db.child('attendance').child(_uid).get();
      if (!snapshot.exists) {
        historyList.clear();
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];

      data.forEach((dateKey, value) {
        if (value is Map) {
          final clockIn = value['clockIn'] != null
              ? DateTime.fromMillisecondsSinceEpoch(value['clockIn'] as int)
              : null;
          final clockOut = value['clockOut'] != null
              ? DateTime.fromMillisecondsSinceEpoch(value['clockOut'] as int)
              : null;

          String duration = '-';
          if (clockIn != null) {
            final end = clockOut ?? clockIn;
            final diff = end.difference(clockIn);
            duration = '${diff.inHours}j ${diff.inMinutes % 60}m';
          }

          final date = DateTime.tryParse(dateKey.toString());
          list.add({
            'dateKey': dateKey.toString(),
            'date': date,
            'month': date?.month,
            'year': date?.year,
            'clockIn': clockIn,
            'clockOut': clockOut,
            'duration': duration,
            'isComplete': clockIn != null && clockOut != null,
          });
        }
      });

      // Sort by date descending (newest first)
      list.sort(
        (a, b) => (b['dateKey'] as String).compareTo(a['dateKey'] as String),
      );

      historyList.assignAll(list);
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      isHistoryLoading.value = false;
    }
  }

  // Change selected month
  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
  }

  void nextMonth() {
    final now = DateTime.now();
    final next = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      selectedMonth.value = next;
    }
  }
}
