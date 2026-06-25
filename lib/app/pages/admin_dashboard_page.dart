import 'package:absence/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AdminController>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminC = Get.find<AdminController>();

    final pages = [
      _buildHomeTab(context, adminC),
      _buildQrTab(context, adminC),
      _buildLeavesTab(context, adminC),
      _buildUsersTab(context, adminC),
      _buildSettingsTab(context, adminC),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Obx(() {
        if (adminC.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return pages[_currentIndex];
      }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A6CF7),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_rounded),
            label: 'QR Absensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Pengajuan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Kelola User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: DASHBOARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildHomeTab(BuildContext context, AdminController adminC) {
    final today = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());
    final authC = Get.find<AuthController>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: adminC.loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A6CF7), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: adminC.loadAll,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showLogoutDialog(authC),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats
              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Anak Magang',
                          value: '${adminC.totalUsers.value}',
                          icon: Icons.people_alt,
                          color: const Color(0xFF4A6CF7),
                          onTap: () => Get.toNamed('/admin/users'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Hadir Hari Ini',
                          value: '${adminC.totalHadirToday.value}',
                          icon: Icons.check_circle,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Terlambat',
                          value: '${adminC.totalLatToday.value}',
                          icon: Icons.warning_rounded,
                          color: Colors.red.shade500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Izin Menunggu',
                          value: '${adminC.totalPendingLeaves.value}',
                          icon: Icons.pending_actions,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Today's Attendance List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Absensi Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: adminC.loadTodayAttendance,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (adminC.todayAttendance.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Belum ada data absensi hari ini.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: adminC.todayAttendance.length,
                  itemBuilder: (context, index) {
                    final item = adminC.todayAttendance[index];
                    final isLate = item['lateMinutes'] > 0;
                    final isHadir = item['status'] != 'belum';
                    final points = item['points'] ?? 0;

                    return InkWell(
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.adminUserDetail,
                          arguments: item['uid'],
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isLate
                              ? Border.all(color: Colors.red.shade200)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isHadir)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLate
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isLate
                                          ? 'Telat ${item['lateMinutes']}m'
                                          : 'Tepat Waktu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLate
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Belum Absen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.login,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(item['clockIn']),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.logout,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(item['clockOut']),
                                if (isHadir) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$points poin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (item['clockInLocation'] != '-' ||
                                item['clockOutLocation'] != '-') ...[
                              const SizedBox(height: 8),
                              if (item['clockInLocation'] != '-')
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.blue.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'M: ${item['clockInLocation']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (item['clockOutLocation'] != '-') ...[
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.purple.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'P: ${item['clockOutLocation']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 24),
              // Today's Logbook List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Logbook Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: adminC.loadTodayLogbooks,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (adminC.todayLogbooks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Center(child: Text('Belum ada logbook hari ini.')),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: adminC.todayLogbooks.length,
                  itemBuilder: (context, index) {
                    final item = adminC.todayLogbooks[index];
                    final time = DateFormat('HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                        item['createdAt'] as int,
                      ),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['userName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['content'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EAF6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['divisi'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4A6CF7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item['points']} Poin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: QR ABSENSI
  // ═══════════════════════════════════════════════════════════

  Widget _buildQrTab(BuildContext context, AdminController adminC) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QR Code Absensi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await adminC.loadSchedule();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate QR untuk absensi anak magang',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            Obx(() {
              if (!adminC.isQrActive.value) {
                // Show generate button
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada sesi QR aktif',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: adminC.startQrSession,
                        icon: const Icon(Icons.qr_code_rounded),
                        label: const Text(
                          'Generate QR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6CF7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Show active QR
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sesi QR Aktif',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // QR Code
                        QrImageView(
                          data: adminC.qrCode.value,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF4A6CF7),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2D3436),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info text
                        Text(
                          'QR berubah otomatis setiap scan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stop button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStopQrDialog(adminC),
                      icon: const Icon(Icons.stop_circle_rounded),
                      label: const Text(
                        'Tutup Sesi QR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showStopQrDialog(AdminController adminC) {
    Get.defaultDialog(
      title: 'Tutup Sesi QR',
      middleText:
          'QR Code akan dinonaktifkan dan tidak bisa di-scan lagi. Lanjutkan?',
      textCancel: 'Batal',
      textConfirm: 'Tutup',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () {
        Get.back();
        adminC.stopQrSession();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: PENGAJUAN (LEAVES)
  // ═══════════════════════════════════════════════════════════

  Widget _buildLeavesTab(BuildContext context, AdminController adminC) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pengajuan Izin / Cuti',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: adminC.loadAllLeaveRequests,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6CF7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Obx(() {
                    final month = adminC.selectedMonthLeaves.value;
                    final label = DateFormat(
                      'MMMM yyyy',
                      'id_ID',
                    ).format(month);
                    final isCurrentMonth =
                        month.month == DateTime.now().month &&
                        month.year == DateTime.now().year;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: adminC.previousLeavesMonth,
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: isCurrentMonth
                              ? null
                              : adminC.nextLeavesMonth,
                          icon: Icon(
                            Icons.chevron_right,
                            color: isCurrentMonth
                                ? Colors.white38
                                : Colors.white,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (adminC.filteredLeaves.isEmpty) {
                return const Center(child: Text('Tidak ada data pengajuan.'));
              }
              return RefreshIndicator(
                onRefresh: adminC.loadAllLeaveRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: adminC.filteredLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = adminC.filteredLeaves[index];
                    final isPending = leave['status'] == 'pending';
                    Color statusColor;
                    String statusLabel;
                    switch (leave['status']) {
                      case 'approved':
                        statusColor = Colors.green;
                        statusLabel = 'Disetujui';
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        statusLabel = 'Ditolak';
                        break;
                      default:
                        statusColor = Colors.orange;
                        statusLabel = 'Menunggu';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                leave['userName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  leave['type'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${leave['startDate']} - ${leave['endDate']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Alasan: ${leave['reason']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (isPending) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => adminC.updateLeaveStatus(
                                      leave['uid'],
                                      leave['id'],
                                      'rejected',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => adminC.updateLeaveStatus(
                                      leave['uid'],
                                      leave['id'],
                                      'approved',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4: KELOLA USER
  // ═══════════════════════════════════════════════════════════

  Widget _buildUsersTab(BuildContext context, AdminController adminC) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final asalCtrl = TextEditingController();
    final divisiCtrl = TextEditingController();
    final selectedDivisi = ''.obs;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kelola User',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    await adminC.loadAllUsers();
                    await adminC.loadDivisions();
                    await adminC.loadAsalSuggestions();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Buat akun user dan kelola divisi',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            // ─── Manage Divisi Section ───────────────────────
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Divisi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: divisiCtrl,
                          decoration: InputDecoration(
                            hintText: 'Nama divisi baru',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (divisiCtrl.text.trim().isNotEmpty) {
                            adminC.addDivision(divisiCtrl.text.trim());
                            divisiCtrl.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6CF7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (adminC.divisionsList.isEmpty) {
                      return Text(
                        'Belum ada divisi. Tambahkan di atas.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: adminC.divisionsList.map((div) {
                        return Chip(
                          label: Text(div['name'] ?? ''),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => adminC.deleteDivision(div['id']!),
                          backgroundColor: const Color(0xFFE8EAF6),
                          labelStyle: const TextStyle(
                            color: Color(0xFF4A6CF7),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Create User Form ────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buat Akun User Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pwCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Divisi dropdown
                  Obx(() {
                    final divisions = adminC.divisionsList;
                    if (divisions.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tambahkan divisi terlebih dahulu',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: selectedDivisi.value.isEmpty
                            ? null
                            : selectedDivisi.value,
                        decoration: InputDecoration(
                          labelText: 'Divisi',
                          prefixIcon: const Icon(
                            Icons.business_center_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: divisions.map((div) {
                          return DropdownMenuItem(
                            value: div['name'],
                            child: Text(div['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          selectedDivisi.value = val ?? '';
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Asal with autocomplete
                  Obx(() {
                    final suggestions = adminC.asalSuggestions.toList();
                    return Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return suggestions;
                        }
                        return suggestions.where(
                          (s) => s.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (val) {
                        asalCtrl.text = val;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            // Sync the autocomplete controller with asalCtrl
                            asalCtrl.addListener(() {
                              if (controller.text != asalCtrl.text) {
                                controller.text = asalCtrl.text;
                              }
                            });
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onEditingComplete: onEditingComplete,
                              onChanged: (val) => asalCtrl.text = val,
                              decoration: InputDecoration(
                                labelText: 'Asal (Instansi/Sekolah)',
                                prefixIcon: const Icon(
                                  Icons.location_city_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                    );
                  }),

                  const SizedBox(height: 20),

                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: adminC.isCreatingUser.value
                            ? null
                            : () async {
                                final success = await adminC.createUser(
                                  name: nameCtrl.text,
                                  email: emailCtrl.text,
                                  password: pwCtrl.text,
                                  divisi: selectedDivisi.value,
                                  asal: asalCtrl.text,
                                );
                                if (success) {
                                  // Clear form on success
                                  nameCtrl.clear();
                                  emailCtrl.clear();
                                  pwCtrl.clear();
                                  asalCtrl.clear();
                                  selectedDivisi.value = '';
                                }
                              },
                        icon: adminC.isCreatingUser.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(
                          adminC.isCreatingUser.value
                              ? 'Membuat...'
                              : 'Buat Akun',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6CF7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── User List ───────────────────────────────────
            const Text(
              'Daftar User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final users = adminC.allUsers
                  .where((u) => u['role'] != 'admin')
                  .toList();
              if (users.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('Belum ada user terdaftar.')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.adminUserDetail,
                              arguments: user['uid'],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFE8EAF6),
                                    child: Text(
                                      (user['name'] as String).isNotEmpty
                                          ? user['name'][0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A6CF7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${user['email']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8EAF6),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          user['divisi'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF4A6CF7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user['asal'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'detail') {
                              Get.toNamed(
                                AppRoutes.adminUserDetail,
                                arguments: user['uid'],
                              );
                            } else if (value == 'edit') {
                              _showEditProfileDialog(context, adminC, user);
                            } else if (value == 'reset') {
                              _showResetPasswordDialog(
                                context,
                                adminC,
                                user['email'],
                              );
                            } else if (value == 'delete') {
                              _showDeleteUserDialog(context, adminC, user);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Detail'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Edit Profil'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_reset,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Reset PW'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Hapus'),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 5: PENGATURAN
  // ═══════════════════════════════════════════════════════════

  Widget _buildSettingsTab(BuildContext context, AdminController adminC) {
    final cinCtrl = TextEditingController(text: adminC.scheduleClockIn.value);
    final coutCtrl = TextEditingController(text: adminC.scheduleClockOut.value);
    final tolCtrl = TextEditingController(
      text: adminC.tolerance.value.toString(),
    );
    final pointsCtrl = TextEditingController(
      text: adminC.defaultPoints.value.toString(),
    );
    final logbookPointsCtrl = TextEditingController(
      text: adminC.defaultLogbookPoints.value.toString(),
    );

    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _selectTime(
      BuildContext context,
      TextEditingController ctrl,
    ) async {
      TimeOfDay initialTime = const TimeOfDay(hour: 7, minute: 0);
      try {
        final parts = ctrl.text.split(':');
        if (parts.length == 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}

      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (picked != null) {
        final String hour = picked.hour.toString().padLeft(2, '0');
        final String minute = picked.minute.toString().padLeft(2, '0');
        ctrl.text = '$hour:$minute';
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pengaturan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    await adminC.loadSchedule();
                    await adminC.loadPublicHolidays();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal & Absensi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cinCtrl,
                    readOnly: true,
                    onTap: () => _selectTime(context, cinCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Jam Masuk',
                      prefixIcon: Icon(Icons.login_rounded),
                      hintText: 'Pilih Jam Masuk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: coutCtrl,
                    readOnly: true,
                    onTap: () => _selectTime(context, coutCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Jam Pulang',
                      prefixIcon: Icon(Icons.logout_rounded),
                      hintText: 'Pilih Jam Pulang',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tolCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Toleransi Keterlambatan (menit)',
                      hintText: '10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poin Default Absensi',
                      hintText: '60',
                      prefixIcon: Icon(Icons.stars_rounded),
                      border: OutlineInputBorder(),
                      helperText:
                          'Poin dikurangi per menit keterlambatan (di luar toleransi)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: logbookPointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poin Default Logbook',
                      hintText: '60',
                      prefixIcon: Icon(Icons.book_rounded),
                      border: OutlineInputBorder(),
                      helperText:
                          'Poin yang diberikan setiap user mengirim logbook',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        adminC.updateSchedule(
                          cinCtrl.text.trim(),
                          coutCtrl.text.trim(),
                          int.tryParse(tolCtrl.text.trim()) ?? 10,
                          int.tryParse(pointsCtrl.text.trim()) ?? 60,
                          int.tryParse(logbookPointsCtrl.text.trim()) ?? 60,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simpan Pengaturan'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Pengaturan Hari (Per Hari) ─────────────────
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_week_rounded,
                        color: const Color(0xFF4A6CF7),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pengaturan Hari',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atur status tiap hari dalam seminggu (berlaku setiap bulan)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    const dayEntries = [
                      {'key': 'monday', 'label': 'Senin'},
                      {'key': 'tuesday', 'label': 'Selasa'},
                      {'key': 'wednesday', 'label': 'Rabu'},
                      {'key': 'thursday', 'label': 'Kamis'},
                      {'key': 'friday', 'label': 'Jumat'},
                      {'key': 'saturday', 'label': 'Sabtu'},
                      {'key': 'sunday', 'label': 'Minggu'},
                    ];

                    return Column(
                      children: dayEntries.map((entry) {
                        final dayKey = entry['key']!;
                        final dayLabel = entry['label']!;
                        final currentStatus =
                            adminC.daySettings[dayKey] ?? 'masuk';

                        IconData icon;
                        Color iconColor;
                        switch (currentStatus) {
                          case 'holiday':
                            icon = Icons.beach_access_rounded;
                            iconColor = Colors.red.shade500;
                            break;
                          case 'wfh':
                            icon = Icons.home_work_rounded;
                            iconColor = Colors.blue.shade500;
                            break;
                          default:
                            icon = Icons.business_rounded;
                            iconColor = Colors.green.shade500;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: currentStatus == 'holiday'
                                ? Colors.red.shade50
                                : currentStatus == 'wfh'
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentStatus == 'holiday'
                                  ? Colors.red.shade200
                                  : currentStatus == 'wfh'
                                  ? Colors.blue.shade200
                                  : Colors.green.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: iconColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dayLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                value: currentStatus,
                                underline: const SizedBox(),
                                isDense: true,
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'masuk',
                                    child: Text(
                                      'Masuk',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'holiday',
                                    child: Text(
                                      'Libur',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'wfh',
                                    child: Text(
                                      'WFH',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null && value != currentStatus) {
                                    adminC.updateDaySettings(dayKey, value);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Kelola Hari Libur (Tgl Merah) ─────────────
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        color: Colors.red.shade600,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kelola Hari Libur (Tgl Merah)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tanggal libur yang ditambahkan akan ditandai di rekap absensi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  _HolidayAddWidget(adminC: adminC),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (adminC.publicHolidays.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Belum ada hari libur. Tambahkan di atas.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: adminC.publicHolidays.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final holiday = adminC.publicHolidays[index];
                        final dateStr = holiday['date'] ?? '';
                        final name = holiday['name'] ?? '';
                        // Format display date
                        String displayDate = dateStr;
                        try {
                          final d = DateTime.parse(dateStr);
                          displayDate = DateFormat(
                            'dd MMM yyyy',
                            'id_ID',
                          ).format(d);
                        } catch (_) {}

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.celebration,
                                size: 18,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                    Text(
                                      displayDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Hapus Hari Libur',
                                    middleText: 'Hapus "$name" ($displayDate)?',
                                    textConfirm: 'Hapus',
                                    textCancel: 'Batal',
                                    confirmTextColor: Colors.white,
                                    buttonColor: Colors.red.shade600,
                                    onConfirm: () {
                                      Get.back();
                                      adminC.deletePublicHoliday(dateStr);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════

  void _showLogoutDialog(AuthController authC) {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Apakah kamu yakin ingin keluar dari Admin Panel?',
      textCancel: 'Batal',
      textConfirm: 'Keluar',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () {
        Get.back();
        authC.logout();
      },
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    AdminController adminC,
    Map<String, dynamic> user,
  ) {
    final nameCtrl = TextEditingController(text: user['name']);
    final asalCtrl = TextEditingController(text: user['asal']);
    final selectedDivisi = (user['divisi'] ?? '').toString().obs;

    Get.defaultDialog(
      title: 'Edit Profil Anak Magang',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: asalCtrl,
              decoration: const InputDecoration(
                labelText: 'Asal Sekolah/Instansi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final divisions = adminC.divisionsList;
              return DropdownButtonFormField<String>(
                initialValue:
                    selectedDivisi.value.isEmpty ||
                        !divisions.any(
                          (div) => div['name'] == selectedDivisi.value,
                        )
                    ? null
                    : selectedDivisi.value,
                decoration: const InputDecoration(
                  labelText: 'Divisi',
                  border: OutlineInputBorder(),
                ),
                items: divisions.map((div) {
                  return DropdownMenuItem(
                    value: div['name'],
                    child: Text(div['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) {
                  selectedDivisi.value = val ?? '';
                },
              );
            }),
          ],
        ),
      ),
      textConfirm: 'Simpan',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF4A6CF7),
      onConfirm: () {
        if (nameCtrl.text.trim().isEmpty) {
          Get.snackbar('Error', 'Nama tidak boleh kosong');
          return;
        }
        Get.back();
        adminC.updateUserInfo(
          user['uid'],
          name: nameCtrl.text.trim(),
          divisi: selectedDivisi.value,
          asal: asalCtrl.text.trim(),
        );
      },
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    AdminController adminC,
    String email,
  ) {
    Get.defaultDialog(
      title: 'Reset Password',
      middleText: 'Kirim email instruksi reset password ke $email?',
      textConfirm: 'Kirim',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange.shade800,
      onConfirm: () {
        Get.back();
        adminC.sendPasswordReset(email);
      },
    );
  }

  void _showDeleteUserDialog(
    BuildContext context,
    AdminController adminC,
    Map<String, dynamic> user,
  ) {
    Get.defaultDialog(
      title: 'Hapus Anak Magang',
      middleText:
          'Apakah Anda yakin ingin menghapus akun "${user['name']}"? Semua data di database akan hilang dan aksi ini tidak bisa dibatalkan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () {
        Get.back();
        adminC.deleteUser(user['uid']);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HolidayAddWidget extends StatefulWidget {
  final AdminController adminC;
  const _HolidayAddWidget({required this.adminC});

  @override
  State<_HolidayAddWidget> createState() => _HolidayAddWidgetState();
}

class _HolidayAddWidgetState extends State<_HolidayAddWidget> {
  final _nameCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!)
        : 'Pilih Tanggal';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Nama hari libur',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (_selectedDate == null || _nameCtrl.text.trim().isEmpty) {
                  Get.snackbar(
                    'Peringatan',
                    'Pilih tanggal dan isi nama hari libur.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.orange.shade600,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                  return;
                }
                final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                widget.adminC.addPublicHoliday(dateKey, _nameCtrl.text.trim());
                _nameCtrl.clear();
                setState(() => _selectedDate = null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
