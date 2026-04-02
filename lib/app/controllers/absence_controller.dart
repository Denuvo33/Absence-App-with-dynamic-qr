import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AbsenceController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Observables
  final isLoading = false.obs;
  final clockInTime = Rxn<DateTime>();
  final clockOutTime = Rxn<DateTime>();
  final hasClockIn = false.obs;
  final hasClockOut = false.obs;
  final clockInLocationStr = ''.obs;
  final clockOutLocationStr = ''.obs;

  // Schedule from Firebase /absence
  final scheduleClockIn = ''.obs; // e.g. "07:00"
  final scheduleClockOut = ''.obs; // e.g. "16:00"
  final tolerance = 0.obs; // in minutes
  final isScheduleLoaded = false.obs;

  // Today's lateness
  final lateMinutes = 0.obs;
  final isLate = false.obs;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onReady() {
    super.onReady();
    loadSchedule();
    loadTodayAttendance();
  }

  // Reset state when switching accounts
  void resetState() {
    clockInTime.value = null;
    clockOutTime.value = null;
    hasClockIn.value = false;
    hasClockOut.value = false;
    lateMinutes.value = 0;
    isLate.value = false;
    clockInLocationStr.value = '';
    clockOutLocationStr.value = '';
    historyList.clear();
    isLoading.value = false;
  }

  // ─── Location Helpers ────────────────────────────────────────

  Future<String?> _getLocationAndAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek GPS aktif tidak
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('GPS Nonaktif', 'Layanan lokasi (GPS) tidak aktif. Mohon nyalakan GPS untuk absen.',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Izin Ditolak', 'Akses lokasi dibutuhkan untuk validasi absensi.',
            backgroundColor: Colors.red.shade600, colorText: Colors.white);
        return null; // Ditolak
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Izin Permanen Ditolak', 'Akses lokasi diblokir. Silakan izinkan dari pengaturan sistem.',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Translate ke address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final street = place.street ?? '';
          final subLocality = place.subLocality ?? '';
          final locality = place.locality ?? '';
          
          List<String> addressParts = [];
          if (street.isNotEmpty) addressParts.add(street);
          if (subLocality.isNotEmpty) addressParts.add(subLocality);
          if (locality.isNotEmpty) addressParts.add(locality);
          
          if (addressParts.isNotEmpty) {
            return addressParts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('Geocoding fail: $e');
      }

      // Fallback
      return 'Geocoding Timeout/Fail (Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)})';

    } catch (e) {
      Get.snackbar('Gagal Melacak Lokasi', 'Terjadi masalah jaringan atau GPS timeout.',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return null;
    }
  }

  // ─── Schedule ──────────────────────────────────────────────

  // Load schedule from Firebase /absence
  Future<void> loadSchedule() async {
    try {
      final snapshot = await _db.child('absence').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        scheduleClockIn.value = (data['clockIn'] ?? '07:00').toString();
        scheduleClockOut.value = (data['clockOut'] ?? '16:00').toString();
        tolerance.value = int.tryParse(data['tolerance'].toString()) ?? 10;
        isScheduleLoaded.value = true;
      } else {
        // Default values if not set
        scheduleClockIn.value = '07:00';
        scheduleClockOut.value = '16:00';
        tolerance.value = 10;
        isScheduleLoaded.value = true;
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      scheduleClockIn.value = '07:00';
      scheduleClockOut.value = '16:00';
      tolerance.value = 10;
      isScheduleLoaded.value = true;
    }
  }

  // Parse "HH:mm" string to DateTime today (null-safe)
  DateTime? _parseScheduleTime(String timeStr) {
    if (timeStr.isEmpty || !timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  // Check if clock in is allowed right now
  // Allowed: from 30 minutes before schedule until end of day (if not already clocked in)
  bool get canClockIn {
    if (!isScheduleLoaded.value || hasClockIn.value) return false;
    final scheduleIn = _parseScheduleTime(scheduleClockIn.value);
    if (scheduleIn == null) return false;
    final earliest = scheduleIn.subtract(const Duration(minutes: 30));
    return DateTime.now().isAfter(earliest);
  }

  // Check if clock out is allowed right now
  // Allowed: from schedule clock out time onwards
  bool get canClockOut {
    if (!isScheduleLoaded.value || !hasClockIn.value || hasClockOut.value) {
      return false;
    }
    final scheduleOut = _parseScheduleTime(scheduleClockOut.value);
    if (scheduleOut == null) return false;
    final now = DateTime.now();
    return now.isAfter(scheduleOut) || now.isAtSameMomentAs(scheduleOut);
  }

  // Get message for why clock in/out is not allowed
  String getClockInMessage() {
    if (hasClockIn.value) return 'Sudah clock in hari ini';
    final scheduleIn = _parseScheduleTime(scheduleClockIn.value);
    if (scheduleIn == null) return 'Jadwal belum dimuat';
    final earliest = scheduleIn.subtract(const Duration(minutes: 30));
    final now = DateTime.now();
    if (now.isBefore(earliest)) {
      return 'Clock in dibuka pukul ${DateFormat("HH:mm").format(earliest)}';
    }
    return '';
  }

  String getClockOutMessage() {
    if (!hasClockIn.value) return 'Belum clock in';
    if (hasClockOut.value) return 'Sudah clock out hari ini';
    final scheduleOut = _parseScheduleTime(scheduleClockOut.value);
    if (scheduleOut == null) return 'Jadwal belum dimuat';
    final now = DateTime.now();
    if (now.isBefore(scheduleOut)) {
      return 'Clock out dibuka pukul ${scheduleClockOut.value}';
    }
    return '';
  }

  // ─── Load Today ────────────────────────────────────────────

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
        if (data['lateMinutes'] != null) {
          lateMinutes.value = data['lateMinutes'] as int;
          isLate.value = lateMinutes.value > 0;
        }
        if (data['clockInLocation'] != null) {
          clockInLocationStr.value = data['clockInLocation'].toString();
        }
        if (data['clockOutLocation'] != null) {
          clockOutLocationStr.value = data['clockOutLocation'].toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
  }

  // ─── Clock In ──────────────────────────────────────────────

  Future<void> clockIn() async {
    if (_uid.isEmpty || hasClockIn.value) return;

    if (!canClockIn) {
      Get.snackbar(
        'Belum Waktunya',
        getClockInMessage(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;
    final address = await _getLocationAndAddress();
    if (address == null) {
      isLoading.value = false;
      return; 
    }

    try {
      final now = DateTime.now();

      // Calculate lateness
      final scheduleIn = _parseScheduleTime(scheduleClockIn.value);
      int late = 0;
      String status = 'on_time';

      if (scheduleIn != null) {
        final deadlineIn = scheduleIn.add(Duration(minutes: tolerance.value));
        if (now.isAfter(deadlineIn)) {
          late = now.difference(scheduleIn).inMinutes;
          status = 'late';
        }
      }

      await _db.child('attendance').child(_uid).child(_todayKey).update({
        'clockIn': now.millisecondsSinceEpoch,
        'date': _todayKey,
        'lateMinutes': late,
        'status': status,
        'clockInLocation': address,
      });

      clockInTime.value = now;
      hasClockIn.value = true;
      clockInLocationStr.value = address;
      lateMinutes.value = late;
      isLate.value = late > 0;

      final lateStr = late > 0 ? ' (Telat ${late} menit)' : '';
      Get.snackbar(
        'Clock In Berhasil',
        'Absen masuk pukul ${DateFormat("HH:mm").format(now)}$lateStr',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: late > 0
            ? Colors.orange.shade600
            : Colors.green.shade600,
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

  // ─── Clock Out ─────────────────────────────────────────────

  Future<void> clockOut() async {
    if (_uid.isEmpty || !hasClockIn.value || hasClockOut.value) return;

    if (!canClockOut) {
      Get.snackbar(
        'Belum Waktunya',
        getClockOutMessage(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;
    final address = await _getLocationAndAddress();
    if (address == null) {
      isLoading.value = false;
      return; // Berhenti jika lokasi gagal diset
    }

    try {
      final now = DateTime.now();

      await _db.child('attendance').child(_uid).child(_todayKey).update({
        'clockOut': now.millisecondsSinceEpoch,
        'clockOutLocation': address,
      });

      clockOutTime.value = now;
      hasClockOut.value = true;
      clockOutLocationStr.value = address;

      Get.snackbar(
        'Clock Out Berhasil',
        'Absen pulang pukul ${DateFormat("HH:mm").format(now)}',
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

  // ─── Helpers ───────────────────────────────────────────────

  String formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('HH:mm').format(time);
  }

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
          final late = value['lateMinutes'] as int? ?? 0;
          final status = value['status']?.toString() ?? 'on_time';

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
            'lateMinutes': late,
            'status': status,
            'clockInLocation': value['clockInLocation']?.toString() ?? '-',
            'clockOutLocation': value['clockOutLocation']?.toString() ?? '-',
          });
        }
      });

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
