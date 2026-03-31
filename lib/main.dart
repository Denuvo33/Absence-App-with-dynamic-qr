import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/app_bindings.dart';
import 'app/controllers/auth_controller.dart';
import 'app/pages/login_page.dart';
import 'app/pages/register_page.dart';
import 'app/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Absence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4A6CF7),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialBinding: AuthBinding(),
      initialRoute: AppRoutes.login,
      getPages: [
        GetPage(name: AppRoutes.login, page: () => const LoginPage()),
        GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
        GetPage(name: AppRoutes.home, page: () => const HomePage()),
      ],
    );
  }
}
