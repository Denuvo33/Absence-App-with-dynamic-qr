import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'absence_controller.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Observables
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;

  // Flag to prevent auto-navigation during registration
  bool _isRegistering = false;

  // Text controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  StreamSubscription<User?>? _authSub;

  @override
  void onReady() {
    super.onReady();
    // Check initial auth state once
    if (_auth.currentUser != null) {
      _loadUserData();
      Get.offAllNamed(AppRoutes.home);
    }
    // Listen for subsequent auth state changes
    _authSub = _auth.authStateChanges().skip(1).listen((user) {
      if (user != null) {
        if (!_isRegistering) {
          _loadUserData();
          final absenceC = Get.find<AbsenceController>();
          absenceC.resetState();
          absenceC.loadTodayAttendance();
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        userName.value = '';
        userEmail.value = '';
        Get.find<AbsenceController>().resetState();
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  User? get currentUser => _auth.currentUser;

  // Load user data from Realtime Database
  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await _db.child('users').child(uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        userName.value = data['name'] ?? '';
        userEmail.value = data['email'] ?? '';
      } else {
        // Fallback to FirebaseAuth data
        userName.value = _auth.currentUser?.displayName ?? '';
        userEmail.value = _auth.currentUser?.email ?? '';
      }
    } catch (_) {
      userName.value = _auth.currentUser?.displayName ?? '';
      userEmail.value = _auth.currentUser?.email ?? '';
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

  // Register
  Future<void> register(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      _isRegistering = true;

      final name = nameController.text.trim();
      final email = emailController.text.trim();

      // Create user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      // Update display name
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      // Save user data to Realtime Database
      await _db.child('users').child(credential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': ServerValue.timestamp,
      });

      // Set reactive user data directly
      userName.value = name;
      userEmail.value = email;

      _clearFields();
      _isRegistering = false;

      // Navigate manually after everything is set
      Get.offAllNamed(AppRoutes.home);

      Get.snackbar(
        'Berhasil',
        'Akun berhasil dibuat!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } on FirebaseAuthException catch (e) {
      _isRegistering = false;
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _isRegistering = false;
      _showError('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      isLoading.value = false;
    }
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
    nameController.clear();
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
