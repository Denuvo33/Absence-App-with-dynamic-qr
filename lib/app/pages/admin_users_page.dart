import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../routes/app_routes.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminC = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Daftar Anak Magang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (adminC.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = adminC.allUsers.where((u) => u['role'] != 'admin').toList();

        if (users.isEmpty) {
          return const Center(child: Text('Belum ada anak magang terdaftar.'));
        }

        // Group by asal
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var u in users) {
          final asal = (u['asal']?.toString() ?? '-').trim();
          final key = asal.isEmpty ? '-' : asal;
          grouped.putIfAbsent(key, () => []).add(u);
        }

        final sortedAsals = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: sortedAsals.length,
          itemBuilder: (context, index) {
            final asal = sortedAsals[index];
            final groupUsers = grouped[asal]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    asal,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${groupUsers.length} Anak Magang',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  leading: const Icon(
                    Icons.location_city,
                    color: Color(0xFF4A6CF7),
                  ),
                  children: groupUsers.map((user) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF4A6CF7).withValues(alpha: 0.1),
                        child: Text(
                          user['name'].isNotEmpty ? user['name'][0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A6CF7),
                          ),
                        ),
                      ),
                      title: Text(
                        user['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        user['email'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                        Get.toNamed(AppRoutes.adminUserDetail, arguments: user['uid']);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
