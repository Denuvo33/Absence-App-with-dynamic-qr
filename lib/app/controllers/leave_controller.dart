import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final isLoading = false.obs;
  final leaveList = <Map<String, dynamic>>[].obs;
  final isListLoading = false.obs;

  // Form fields
  final selectedType = 'izin'.obs;
  final reasonController = TextEditingController();
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  String get _uid => _auth.currentUser?.uid ?? '';

  // Submit leave request
  Future<void> submitLeave() async {
    if (_uid.isEmpty) return;

    if (startDate.value == null || endDate.value == null) {
      _showError('Pilih tanggal mulai dan selesai.');
      return;
    }
    if (reasonController.text.trim().isEmpty) {
      _showError('Isi alasan pengajuan.');
      return;
    }
    if (endDate.value!.isBefore(startDate.value!)) {
      _showError('Tanggal selesai harus setelah tanggal mulai.');
      return;
    }

    try {
      isLoading.value = true;

      final ref = _db.child('leave_requests').child(_uid).push();
      await ref.set({
        'type': selectedType.value,
        'startDate': startDate.value!.toIso8601String().substring(0, 10),
        'endDate': endDate.value!.toIso8601String().substring(0, 10),
        'reason': reasonController.text.trim(),
        'status': 'pending',
        'createdAt': ServerValue.timestamp,
      });

      reasonController.clear();
      startDate.value = null;
      endDate.value = null;
      selectedType.value = 'izin';

      Get.snackbar(
        'Berhasil',
        'Pengajuan berhasil dikirim!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      loadLeaveRequests();
    } catch (e) {
      _showError('Gagal mengirim pengajuan.');
    } finally {
      isLoading.value = false;
    }
  }

  // Load leave requests
  Future<void> loadLeaveRequests() async {
    if (_uid.isEmpty) return;
    try {
      isListLoading.value = true;
      final snapshot = await _db.child('leave_requests').child(_uid).get();
      if (!snapshot.exists) {
        leaveList.clear();
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        if (value is Map) {
          list.add({
            'id': key.toString(),
            'type': value['type']?.toString() ?? '',
            'startDate': value['startDate']?.toString() ?? '',
            'endDate': value['endDate']?.toString() ?? '',
            'reason': value['reason']?.toString() ?? '',
            'status': value['status']?.toString() ?? 'pending',
            'createdAt': value['createdAt'],
          });
        }
      });

      // Sort newest first
      list.sort((a, b) {
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return (bTime as int).compareTo(aTime as int);
      });

      leaveList.assignAll(list);
    } catch (e) {
      debugPrint('Error loading leave requests: $e');
    } finally {
      isListLoading.value = false;
    }
  }

  // Cancel a pending request
  Future<void> cancelRequest(String requestId) async {
    try {
      await _db.child('leave_requests').child(_uid).child(requestId).remove();
      loadLeaveRequests();
      Get.snackbar(
        'Dihapus',
        'Pengajuan berhasil dibatalkan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      _showError('Gagal membatalkan pengajuan.');
    }
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
