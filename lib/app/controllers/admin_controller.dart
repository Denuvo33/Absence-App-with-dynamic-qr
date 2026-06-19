import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  final defaultPoints = 60.obs;

  // Data lists
  final allUsers = <Map<String, dynamic>>[].obs;
  final todayAttendance = <Map<String, dynamic>>[].obs;
  final pendingLeaves = <Map<String, dynamic>>[].obs;
  final allLeaves = <Map<String, dynamic>>[].obs;

  // Divisions
  final divisionsList = <Map<String, String>>[].obs;

  // Asal suggestions
  final asalSuggestions = <String>[].obs;

  // QR Session
  final qrCode = ''.obs;
  final isQrActive = false.obs;
  StreamSubscription? _qrSub;

  // Loading states
  final isLoading = false.obs;
  final isCreatingUser = false.obs;

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
      loadDivisions(),
      loadAsalSuggestions(),
    ]);
    // Check if QR session is active
    _listenQrSession();
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
        defaultPoints.value =
            int.tryParse(data['defaultPoints'].toString()) ?? 60;
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  Future<void> updateSchedule(
      String clockIn, String clockOut, int tol, int points) async {
    try {
      await _db.child('absence').set({
        'clockIn': clockIn,
        'clockOut': clockOut,
        'tolerance': tol,
        'defaultPoints': points,
      });
      scheduleClockIn.value = clockIn;
      scheduleClockOut.value = clockOut;
      tolerance.value = tol;
      defaultPoints.value = points;

      Get.snackbar(
        'Berhasil',
        'Pengaturan berhasil diperbarui!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui pengaturan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ─── QR Session ────────────────────────────────────────────

  Future<void> startQrSession() async {
    try {
      final code =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      await _db.child('qr_session').set({
        'code': code,
        'createdAt': ServerValue.timestamp,
        'active': true,
      });
      qrCode.value = code;
      isQrActive.value = true;

      // Start listening for changes
      _listenQrSession();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memulai sesi QR.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> stopQrSession() async {
    try {
      await _db.child('qr_session').remove();
      qrCode.value = '';
      isQrActive.value = false;
      _qrSub?.cancel();
      _qrSub = null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menutup sesi QR.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _listenQrSession() {
    _qrSub?.cancel();
    _qrSub = _db.child('qr_session').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        qrCode.value = data['code']?.toString() ?? '';
        isQrActive.value = data['active'] == true;
      } else {
        qrCode.value = '';
        isQrActive.value = false;
      }
    });
  }

  // ─── Divisions ─────────────────────────────────────────────

  Future<void> loadDivisions() async {
    try {
      final snapshot = await _db.child('divisions').get();
      if (!snapshot.exists) {
        divisionsList.clear();
        return;
      }
      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Map<String, String>>[];
      data.forEach((key, value) {
        list.add({
          'id': key.toString(),
          'name': value.toString(),
        });
      });
      list.sort(
          (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      divisionsList.assignAll(list);
    } catch (e) {
      debugPrint('Error loading divisions: $e');
    }
  }

  Future<void> addDivision(String name) async {
    if (name.trim().isEmpty) return;
    try {
      await _db.child('divisions').push().set(name.trim());
      await loadDivisions();
      Get.snackbar(
        'Berhasil',
        'Divisi "$name" berhasil ditambahkan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menambahkan divisi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> deleteDivision(String id) async {
    try {
      await _db.child('divisions').child(id).remove();
      await loadDivisions();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus divisi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ─── Asal Suggestions ─────────────────────────────────────

  Future<void> loadAsalSuggestions() async {
    try {
      final snapshot = await _db.child('users').get();
      if (!snapshot.exists) return;
      final data = snapshot.value as Map<dynamic, dynamic>;
      final asalSet = <String>{};
      data.forEach((_, value) {
        if (value is Map && value['asal'] != null) {
          final asal = value['asal'].toString().trim();
          if (asal.isNotEmpty) asalSet.add(asal);
        }
      });
      asalSuggestions.assignAll(asalSet.toList()..sort());
    } catch (e) {
      debugPrint('Error loading asal suggestions: $e');
    }
  }

  // ─── Create User ──────────────────────────────────────────

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String divisi,
    required String asal,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Nama, email, dan password harus diisi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isCreatingUser.value = true;

    try {
      // Use secondary Firebase app to create user without signing out admin
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      // Update display name
      await credential.user?.updateDisplayName(name.trim());

      // Save user data to Realtime Database
      await _db.child('users').child(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'user',
        'divisi': divisi.trim(),
        'asal': asal.trim(),
        'createdAt': ServerValue.timestamp,
      });

      // Sign out from secondary app
      await secondaryAuth.signOut();

      // Reload lists
      await loadAllUsers();
      await loadAsalSuggestions();

      Get.snackbar(
        'Berhasil',
        'Akun "${name.trim()}" berhasil dibuat!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Email sudah terdaftar.';
          break;
        case 'invalid-email':
          msg = 'Format email tidak valid.';
          break;
        case 'weak-password':
          msg = 'Password terlalu lemah (min. 6 karakter).';
          break;
        default:
          msg = 'Terjadi kesalahan (${e.code}).';
      }
      Get.snackbar(
        'Error',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal membuat akun: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isCreatingUser.value = false;
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
            'divisi': value['divisi']?.toString() ?? '-',
            'asal': value['asal']?.toString() ?? '-',
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

        // Attendance now lives under users/{uid}/attendance/{date}
        final attSnapshot = await _db
            .child('users')
            .child(uid)
            .child('attendance')
            .child(_todayKey)
            .get();

        String status = 'belum';
        String clockInStr = '--:--';
        String clockOutStr = '--:--';
        String clockInLoc = '-';
        String clockOutLoc = '-';
        int lateMin = 0;
        int points = 0;

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
          points = (att['points'] as int?) ?? 0;
          clockInLoc = att['clockInLocation']?.toString() ?? '-';
          clockOutLoc = att['clockOutLocation']?.toString() ?? '-';
          if (lateMin > 0) telat++;
        }

        list.add({
          'uid': uid,
          'name': userData['name']?.toString() ?? '',
          'email': userData['email']?.toString() ?? '',
          'divisi': userData['divisi']?.toString() ?? '-',
          'clockIn': clockInStr,
          'clockOut': clockOutStr,
          'clockInLocation': clockInLoc,
          'clockOutLocation': clockOutLoc,
          'status': status,
          'lateMinutes': lateMin,
          'points': points,
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
    int totalPoints = 0;

    for (var item in filteredUserHistory) {
      if (item['recordType'] == 'attendance') {
        totalHadir++;
        totalPoints += item['points'] as int? ?? 0;
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
      'totalPoints': totalPoints,
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
          'divisi': data['divisi']?.toString() ?? '-',
          'asal': data['asal']?.toString() ?? '-',
        };
      }

      // Load attendance history — now under users/{uid}/attendance
      final historySnap =
          await _db.child('users').child(uid).child('attendance').get();

      final list = <Map<String, dynamic>>[];

      if (historySnap.exists) {
        final attData = historySnap.value as Map<dynamic, dynamic>;

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
            final points = value['points'] as int? ?? 0;

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
              'points': points,
            });
          }
        });
      }

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

  @override
  void onClose() {
    _qrSub?.cancel();
    super.onClose();
  }
}
