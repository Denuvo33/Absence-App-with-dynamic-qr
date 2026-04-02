import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminController extends GetxController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Schedule settings
  final scheduleClockIn = '07:00'.obs;
  final scheduleClockOut = '16:00'.obs;
  final tolerance = 10.obs;

  // Data lists
  final allUsers = <Map<String, dynamic>>[].obs;
  final todayAttendance = <Map<String, dynamic>>[].obs;
  final pendingLeaves = <Map<String, dynamic>>[].obs;
  final allLeaves = <Map<String, dynamic>>[].obs;

  // Loading states
  final isLoading = false.obs;

  // Stats
  final totalUsers = 0.obs;
  final totalHadirToday = 0.obs;
  final totalLatToday = 0.obs;
  final totalPendingLeaves = 0.obs;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await Future.wait([
      loadSchedule(),
      loadAllUsers(),
      loadTodayAttendance(),
      loadAllLeaveRequests(),
    ]);
    isLoading.value = false;
  }

  // ─── Schedule ──────────────────────────────────────────────

  Future<void> loadSchedule() async {
    try {
      final snapshot = await _db.child('absence').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        scheduleClockIn.value = (data['clockIn'] ?? '07:00').toString();
        scheduleClockOut.value = (data['clockOut'] ?? '16:00').toString();
        tolerance.value = int.tryParse(data['tolerance'].toString()) ?? 10;
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  Future<void> updateSchedule(String clockIn, String clockOut, int tol) async {
    try {
      await _db.child('absence').set({
        'clockIn': clockIn,
        'clockOut': clockOut,
        'tolerance': tol,
      });
      scheduleClockIn.value = clockIn;
      scheduleClockOut.value = clockOut;
      tolerance.value = tol;

      Get.snackbar(
        'Berhasil',
        'Jadwal berhasil diperbarui!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui jadwal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ─── Users ─────────────────────────────────────────────────

  Future<void> loadAllUsers() async {
    try {
      final snapshot = await _db.child('users').get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];

      data.forEach((uid, value) {
        if (value is Map) {
          list.add({
            'uid': uid.toString(),
            'name': value['name']?.toString() ?? '',
            'email': value['email']?.toString() ?? '',
            'role': value['role']?.toString() ?? 'user',
          });
        }
      });

      // Sort: admins first, then by name
      list.sort((a, b) {
        if (a['role'] == 'admin' && b['role'] != 'admin') return -1;
        if (a['role'] != 'admin' && b['role'] == 'admin') return 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      allUsers.assignAll(list);
      totalUsers.value = list.where((u) => u['role'] != 'admin').length;
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  // ─── Today Attendance ──────────────────────────────────────

  Future<void> loadTodayAttendance() async {
    try {
      final usersSnapshot = await _db.child('users').get();
      if (!usersSnapshot.exists) return;

      final users = usersSnapshot.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];
      int hadir = 0;
      int telat = 0;

      for (final entry in users.entries) {
        final uid = entry.key.toString();
        final userData = entry.value as Map<dynamic, dynamic>;
        final role = userData['role']?.toString() ?? 'user';
        if (role == 'admin') continue; // Skip admin users

        final attSnapshot =
            await _db.child('attendance').child(uid).child(_todayKey).get();

        String status = 'belum';
        String clockInStr = '--:--';
        String clockOutStr = '--:--';
        String clockInLoc = '-';
        String clockOutLoc = '-';
        int lateMin = 0;

        if (attSnapshot.exists) {
          final att = attSnapshot.value as Map<dynamic, dynamic>;
          hadir++;
          if (att['clockIn'] != null) {
            final cin =
                DateTime.fromMillisecondsSinceEpoch(att['clockIn'] as int);
            clockInStr = DateFormat('HH:mm').format(cin);
          }
          if (att['clockOut'] != null) {
            final cout =
                DateTime.fromMillisecondsSinceEpoch(att['clockOut'] as int);
            clockOutStr = DateFormat('HH:mm').format(cout);
          }
          lateMin = (att['lateMinutes'] as int?) ?? 0;
          status = att['status']?.toString() ?? 'on_time';
          clockInLoc = att['clockInLocation']?.toString() ?? '-';
          clockOutLoc = att['clockOutLocation']?.toString() ?? '-';
          if (lateMin > 0) telat++;
        }

        list.add({
          'uid': uid,
          'name': userData['name']?.toString() ?? '',
          'email': userData['email']?.toString() ?? '',
          'clockIn': clockInStr,
          'clockOut': clockOutStr,
          'clockInLocation': clockInLoc,
          'clockOutLocation': clockOutLoc,
          'status': status,
          'lateMinutes': lateMin,
        });
      }

      // Sort: hadir first, then belum
      list.sort((a, b) {
        if (a['status'] == 'belum' && b['status'] != 'belum') return 1;
        if (a['status'] != 'belum' && b['status'] == 'belum') return -1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      todayAttendance.assignAll(list);
      totalHadirToday.value = hadir;
      totalLatToday.value = telat;
    } catch (e) {
      debugPrint('Error loading today attendance: $e');
    }
  }

  // ─── Leave Requests ────────────────────────────────────────

  final selectedMonthLeaves = DateTime.now().obs;

  List<Map<String, dynamic>> get filteredLeaves {
    final month = selectedMonthLeaves.value.month;
    final year = selectedMonthLeaves.value.year;

    return allLeaves.where((leave) {
      if (leave['status'] == 'pending') return true;
      final createdAt = leave['createdAt'];
      if (createdAt != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(createdAt as int);
        return date.month == month && date.year == year;
      }
      return false;
    }).toList();
  }

  void previousLeavesMonth() {
    selectedMonthLeaves.value = DateTime(
      selectedMonthLeaves.value.year,
      selectedMonthLeaves.value.month - 1,
    );
  }

  void nextLeavesMonth() {
    final now = DateTime.now();
    final next = DateTime(
      selectedMonthLeaves.value.year,
      selectedMonthLeaves.value.month + 1,
    );
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      selectedMonthLeaves.value = next;
    }
  }

  Future<void> loadAllLeaveRequests() async {
    try {
      final usersSnapshot = await _db.child('users').get();
      if (!usersSnapshot.exists) return;

      final users = usersSnapshot.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];
      int pending = 0;

      for (final entry in users.entries) {
        final uid = entry.key.toString();
        final userData = entry.value as Map<dynamic, dynamic>;
        final userName = userData['name']?.toString() ?? '';

        final leavesSnapshot =
            await _db.child('leave_requests').child(uid).get();
        if (!leavesSnapshot.exists) continue;

        final leaves = leavesSnapshot.value as Map<dynamic, dynamic>;
        leaves.forEach((key, value) {
          if (value is Map) {
            final status = value['status']?.toString() ?? 'pending';
            if (status == 'pending') pending++;
            list.add({
              'id': key.toString(),
              'uid': uid,
              'userName': userName,
              'type': value['type']?.toString() ?? '',
              'startDate': value['startDate']?.toString() ?? '',
              'endDate': value['endDate']?.toString() ?? '',
              'reason': value['reason']?.toString() ?? '',
              'status': status,
              'createdAt': value['createdAt'],
            });
          }
        });
      }

      // Sort: pending first, then by createdAt desc
      list.sort((a, b) {
        if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
        if (a['status'] != 'pending' && b['status'] == 'pending') return 1;
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return (bTime as int).compareTo(aTime as int);
      });

      allLeaves.assignAll(list);
      pendingLeaves.assignAll(list.where((l) => l['status'] == 'pending'));
      totalPendingLeaves.value = pending;
    } catch (e) {
      debugPrint('Error loading leave requests: $e');
    }
  }

  // Approve / Reject leave
  Future<void> updateLeaveStatus(
      String uid, String requestId, String newStatus) async {
    try {
      await _db
          .child('leave_requests')
          .child(uid)
          .child(requestId)
          .update({'status': newStatus});

      Get.snackbar(
        newStatus == 'approved' ? 'Disetujui' : 'Ditolak',
        'Pengajuan berhasil ${newStatus == "approved" ? "disetujui" : "ditolak"}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: newStatus == 'approved'
            ? Colors.green.shade600
            : Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      loadAllLeaveRequests();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui status.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ─── Individual User Detail ────────────────────────────────

  final selectedUserHistory = <Map<String, dynamic>>[].obs;
  final selectedUserInfo = {}.obs;
  final isUserDetailLoading = false.obs;

  final selectedMonthAdmin = DateTime.now().obs;

  List<Map<String, dynamic>> get filteredUserHistory {
    final month = selectedMonthAdmin.value.month;
    final year = selectedMonthAdmin.value.year;
    return selectedUserHistory.where((e) {
      final date = e['date'] as DateTime?;
      if (date == null) return false;
      return date.month == month && date.year == year;
    }).toList();
  }

  Map<String, dynamic> get filteredUserStats {
    int totalHadir = 0;
    int onTime = 0;
    int late = 0;
    int totalLateMinutes = 0;
    int totalLeaves = 0;

    for (var item in filteredUserHistory) {
      if (item['recordType'] == 'attendance') {
        totalHadir++;
        if (item['status'] == 'late') {
          late++;
          totalLateMinutes += item['lateMinutes'] as int? ?? 0;
        } else {
          onTime++;
        }
      } else if (item['recordType'] == 'leave') {
        totalLeaves++;
      }
    }

    return {
      'totalHadir': totalHadir,
      'onTime': onTime,
      'late': late,
      'totalLateMinutes': totalLateMinutes,
      'totalLeaves': totalLeaves,
    };
  }

  void previousAdminMonth() {
    selectedMonthAdmin.value = DateTime(
      selectedMonthAdmin.value.year,
      selectedMonthAdmin.value.month - 1,
    );
  }

  void nextAdminMonth() {
    final now = DateTime.now();
    final next = DateTime(
      selectedMonthAdmin.value.year,
      selectedMonthAdmin.value.month + 1,
    );
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      selectedMonthAdmin.value = next;
    }
  }

  Future<void> loadUserDetail(String uid) async {
    try {
      isUserDetailLoading.value = true;
      selectedUserHistory.clear();
      selectedUserInfo.clear();
      selectedMonthAdmin.value = DateTime.now();

      // Load user basic info
      final userSnap = await _db.child('users').child(uid).get();
      if (userSnap.exists) {
        final data = userSnap.value as Map<dynamic, dynamic>;
        selectedUserInfo.value = {
          'name': data['name']?.toString() ?? '',
          'email': data['email']?.toString() ?? '',
        };
      }

      // Load attendance history
      final historySnap = await _db.child('attendance').child(uid).get();
      if (!historySnap.exists) {
        return;
      }

      final attData = historySnap.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];

      attData.forEach((dateKey, value) {
        if (value is Map) {
          final clockInLoc = value['clockInLocation']?.toString() ?? '-';
          final clockOutLoc = value['clockOutLocation']?.toString() ?? '-';

          final clockIn = value['clockIn'] != null
              ? DateTime.fromMillisecondsSinceEpoch(value['clockIn'] as int)
              : null;
          final clockOut = value['clockOut'] != null
              ? DateTime.fromMillisecondsSinceEpoch(value['clockOut'] as int)
              : null;
          final lateMin = value['lateMinutes'] as int? ?? 0;
          final status = value['status']?.toString() ?? 'on_time';

          String duration = '-';
          if (clockIn != null) {
            final end = clockOut ?? clockIn;
            final diff = end.difference(clockIn);
            duration = '${diff.inHours}j ${diff.inMinutes % 60}m';
          }

          final date = DateTime.tryParse(dateKey.toString());
          list.add({
            'recordType': 'attendance',
            'dateKey': dateKey.toString(),
            'date': date,
            'clockIn': clockIn,
            'clockOut': clockOut,
            'clockInLocation': clockInLoc,
            'clockOutLocation': clockOutLoc,
            'duration': duration,
            'isComplete': clockIn != null && clockOut != null,
            'lateMinutes': lateMin,
            'status': status,
          });
        }
      });

      // Fetch leave requests
      final leaveSnap = await _db.child('leave_requests').child(uid).get();
      if (leaveSnap.exists) {
        final leavesData = leaveSnap.value as Map<dynamic, dynamic>;
        leavesData.forEach((key, value) {
          if (value is Map && value['status'] == 'approved') {
            final startStr = value['startDate']?.toString();
            final endStr = value['endDate']?.toString();
            if (startStr != null && endStr != null) {
              DateTime start = DateFormat('yyyy-MM-dd').parse(startStr);
              DateTime end = DateFormat('yyyy-MM-dd').parse(endStr);
              
              // Normalize to start of day
              start = DateTime(start.year, start.month, start.day);
              end = DateTime(end.year, end.month, end.day);
              
              int diffDays = end.difference(start).inDays;
              if (diffDays < 0) diffDays = 0;

              // Generate an entry for each day of the leave
              for (int i = 0; i <= diffDays; i++) {
                final currentDate = start.add(Duration(days: i));
                // Only consider weekday as valid leave day (Mon=1, Sun=7)
                if (currentDate.weekday >= 1 && currentDate.weekday <= 5) {
                  list.add({
                    'recordType': 'leave',
                    'dateKey': DateFormat('yyyy-MM-dd').format(currentDate),
                    'date': currentDate,
                    'leaveType': value['type']?.toString() ?? 'Izin',
                    'reason': value['reason']?.toString() ?? '',
                  });
                }
              }
            }
          }
        });
      }

      // Sort chronological descending
      list.sort((a, b) =>
          (b['dateKey'] as String).compareTo(a['dateKey'] as String));

      selectedUserHistory.assignAll(list);
    } catch (e) {
      debugPrint('Error loading user detail: $e');
    } finally {
      isUserDetailLoading.value = false;
    }
  }
}
