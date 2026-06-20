import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'absence_controller.dart';
import 'admin_controller.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Observables
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userRole = ''.obs;
  final userDivisi = ''.obs;

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  StreamSubscription<User?>? _authSub;

  bool get isAdmin => userRole.value == 'admin';

  @override
  void onReady() async {
    var locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }
    if (locationPermission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Error',
        'Lokasi tidak di Izinkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
    super.onReady();
    // Check initial auth state once
    if (_auth.currentUser != null) {
      _loadUserDataAndNavigate();
    }
    // Listen for subsequent auth state changes
    _authSub = _auth.authStateChanges().skip(1).listen((user) {
      if (user != null) {
        _loadUserDataAndNavigate();
      } else {
        userName.value = '';
        userEmail.value = '';
        userRole.value = '';
        userDivisi.value = '';
        Get.find<AbsenceController>().resetState();
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  User? get currentUser => _auth.currentUser;

  // Load user data and navigate based on role
  Future<void> _loadUserDataAndNavigate() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await _db.child('users').child(uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        userName.value = data['name'] ?? '';
        userEmail.value = data['email'] ?? '';
        userRole.value = (data['role'] ?? 'user').toString();
        userDivisi.value = (data['divisi'] ?? '').toString();
      } else {
        userName.value = _auth.currentUser?.displayName ?? '';
        userEmail.value = _auth.currentUser?.email ?? '';
        userRole.value = 'user';
        userDivisi.value = '';
      }
    } catch (_) {
      userName.value = _auth.currentUser?.displayName ?? '';
      userEmail.value = _auth.currentUser?.email ?? '';
      userRole.value = 'user';
      userDivisi.value = '';
    }

    // Navigate based on role
    if (userRole.value == 'admin') {
      Get.find<AdminController>().loadAll();
      Get.offAllNamed(AppRoutes.admin);
    } else {
      final absenceC = Get.find<AbsenceController>();
      absenceC.resetState();
      absenceC.loadSchedule();
      absenceC.loadTodayAttendance();
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  // Reset password visibility when navigating
  void resetPasswordVisibility() {
    isPasswordHidden.value = true;
  }

  // Login
  Future<void> login(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      _clearFields();
      // Navigation handled by auth state listener → _loadUserDataAndNavigate
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _showError('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Clear text fields
  void _clearFields() {
    emailController.clear();
    passwordController.clear();
  }

  // Show error snackbar
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  // Map Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter).';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan ($code).';
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
