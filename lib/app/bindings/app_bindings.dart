import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/absence_controller.dart';
import '../controllers/leave_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<AbsenceController>(AbsenceController(), permanent: true);
    Get.put<LeaveController>(LeaveController(), permanent: true);
  }
}
