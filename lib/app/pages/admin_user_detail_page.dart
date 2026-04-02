import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/admin_controller.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({super.key});

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  final AdminController adminC = Get.find<AdminController>();
  late String uid;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    uid = Get.arguments as String;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminC.loadUserDetail(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Detail Karyawan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: Obx(() {
        if (adminC.isUserDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = adminC.selectedUserInfo;
        if (user.isEmpty) {
          return const Center(child: Text('Data tidak ditemukan.'));
        }

        final stats = adminC.filteredUserStats;
        final totalHadir = stats['totalHadir'] ?? 0;
        final totalLate = stats['late'] ?? 0;
        final totalOnTime = stats['onTime'] ?? 0;
        final lateMins = stats['totalLateMinutes'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(
                        0xFF4A6CF7,
                      ).withValues(alpha: 0.1),
                      child: Text(
                        user['name'] != null &&
                                user['name'].toString().isNotEmpty
                            ? user['name'].toString()[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A6CF7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Overall Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Total Hadir',
                      value: '$totalHadir',
                      icon: Icons.event_available,
                      color: const Color(0xFF00897B),
                      isSelected: _filter == 'hadir',
                      onTap: () {
                        setState(() {
                          _filter = _filter == 'hadir' ? 'all' : 'hadir';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Izin/Cuti',
                      value: '${stats['totalLeaves'] ?? 0}',
                      icon: Icons.fact_check_outlined,
                      color: Colors.blue.shade600,
                      isSelected: _filter == 'leave',
                      onTap: () {
                        setState(() {
                          _filter = _filter == 'leave' ? 'all' : 'leave';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Tepat Waktu',
                      value: '$totalOnTime',
                      icon: Icons.check_circle,
                      color: Colors.green.shade600,
                      isSelected: _filter == 'on_time',
                      onTap: () {
                        setState(() {
                          _filter = _filter == 'on_time' ? 'all' : 'on_time';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Terlambat',
                      value: '$totalLate',
                      icon: Icons.warning_rounded,
                      color: Colors.orange.shade600,
                      isSelected: _filter == 'late',
                      onTap: () {
                        setState(() {
                          _filter = _filter == 'late' ? 'all' : 'late';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Total late minutes info card spanning full width
              _InfoCard(
                title: 'Total Waktu Keterlambatan',
                value: '${lateMins ~/ 60}j ${lateMins % 60}m',
                icon: Icons.timer_off,
                color: Colors.red.shade600,
                isSelected: false,
              ),
              const SizedBox(height: 32),

              // Month Selector
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(() {
                  final month = adminC.selectedMonthAdmin.value;
                  final label = DateFormat('MMMM yyyy', 'id_ID').format(month);
                  final isCurrentMonth =
                      month.month == DateTime.now().month &&
                      month.year == DateTime.now().year;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: adminC.previousAdminMonth,
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
                            : adminC.nextAdminMonth,
                        icon: Icon(
                          Icons.chevron_right,
                          color: isCurrentMonth ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // Attendance History
              const Text(
                'Riwayat Absensi Lengkap',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              if (adminC.filteredUserHistory.isEmpty)
                const Center(child: Text('Belum ada riwayat absensi.'))
              else
                Builder(
                  builder: (context) {
                    final filteredList = adminC.filteredUserHistory.where((
                      item,
                    ) {
                      if (_filter == 'all') return true;
                      if (_filter == 'hadir')
                        return item['recordType'] == 'attendance';
                      if (_filter == 'leave')
                        return item['recordType'] == 'leave';
                      if (_filter == 'late')
                        return item['recordType'] == 'attendance' &&
                            item['status'] == 'late';
                      if (_filter == 'on_time')
                        return item['recordType'] == 'attendance' &&
                            item['status'] == 'on_time';
                      return true;
                    }).toList();

                    if (filteredList.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Tidak ada set data pada filter ini.'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final isLeave = item['recordType'] == 'leave';
                        final date = item['date'] as DateTime?;

                        final dateStr = date != null
                            ? DateFormat(
                                'EEEE, d MMM yyyy',
                                'id_ID',
                              ).format(date)
                            : item['dateKey'];
                        if (isLeave) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['leaveType']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'IZIN',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Alasan: ${item['reason']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Normal Attendance Rendering
                        final isComplete = item['isComplete'] == true;
                        final isLate = item['status'] == 'late';

                        final clockIn = item['clockIn'] != null
                            ? DateFormat('HH:mm').format(item['clockIn'])
                            : '--:--';
                        final clockOut = item['clockOut'] != null
                            ? DateFormat('HH:mm').format(item['clockOut'])
                            : '--:--';
                        final clockInLoc =
                            item['clockInLocation']?.toString() ?? '-';
                        final clockOutLoc =
                            item['clockOutLocation']?.toString() ?? '-';

                        return Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isComplete)
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
                                          fontSize: 11,
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
                                        'Belum Pulang',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.login,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        clockIn,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isLate
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: Colors.purple,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        clockOut,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['duration'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (clockInLoc != '-' || clockOutLoc != '-') ...[
                                const SizedBox(height: 12),
                                if (clockInLoc != '-')
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Masuk: $clockInLoc',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (clockOutLoc != '-') ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Pulang: $clockOutLoc',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _exportToCSV() async {
    final user = adminC.selectedUserInfo;
    if (user.isEmpty) {
      Get.snackbar('Gagal', 'Data pengguna belum tersedia');
      return;
    }

    final stats = adminC.filteredUserStats;
    final totalHadir = stats['totalHadir'] ?? 0;
    final totalLate = stats['late'] ?? 0;
    final totalOnTime = stats['onTime'] ?? 0;
    final lateMins = stats['totalLateMinutes'] ?? 0;
    final totalLeaves = stats['totalLeaves'] ?? 0;

    List<List<dynamic>> rows = [];

    // Header Laporan
    rows.add(['LAPORAN ABSENSI KARYAWAN']);
    rows.add([]);

    // Profil
    rows.add(['DATA PROFIL']);
    rows.add(['Nama', user['name']]);
    rows.add(['Email', user['email']]);
    rows.add([]);

    // Rekapitulasi
    rows.add(['REKAPITULASI']);
    rows.add(['Total Hadir', totalHadir]);
    rows.add(['Izin/Cuti', totalLeaves]);
    rows.add(['Tepat Waktu', totalOnTime]);
    rows.add(['Terlambat', totalLate]);
    rows.add(['Total Menit Telat', lateMins]);
    rows.add([]);

    // Header Riwayat
    rows.add(['DETAIL RIWAYAT ABSENSI & IZIN']);
    rows.add([
      'Tanggal',
      'Tipe',
      'Status',
      'Jam Masuk',
      'Lokasi Masuk',
      'Jam Keluar',
      'Lokasi Keluar',
      'Durasi',
      'Menit Telat',
      'Keterangan/Alasan',
    ]);

    // Data Riwayat
    final history = adminC.filteredUserHistory;
    for (var item in history) {
      final isLeave = item['recordType'] == 'leave';
      final date = item['date'] as DateTime?;
      final dateStr = date != null
          ? DateFormat('yyyy-MM-dd').format(date)
          : (item['dateKey'] ?? '-');

      if (isLeave) {
        final type = item['leaveType']?.toString().toUpperCase() ?? 'IZIN';
        final reason = item['reason'] ?? '-';
        rows.add([
          dateStr,
          'Izin/Cuti',
          type,
          '-',
          '-',
          '-',
          '-',
          '-',
          '-',
          reason,
        ]);
      } else {
        final clockInStr = item['clockIn'] != null
            ? DateFormat('HH:mm').format(item['clockIn'])
            : '-';
        final clockInLoc = item['clockInLocation']?.toString() ?? '-';
        final clockOutStr = item['clockOut'] != null
            ? DateFormat('HH:mm').format(item['clockOut'])
            : '-';
        final clockOutLoc = item['clockOutLocation']?.toString() ?? '-';

        final isLate = item['status'] == 'late';
        final statusStr = isLate ? 'Terlambat' : 'Tepat Waktu';

        final duration = item['duration'] ?? '-';
        final lateMinutesStr = item['lateMinutes']?.toString() ?? '0';

        rows.add([
          dateStr,
          'Absensi',
          statusStr,
          clockInStr,
          clockInLoc,
          clockOutStr,
          clockOutLoc,
          duration,
          lateMinutesStr,
          '-',
        ]);
      }
    }

    try {
      String csvData = Csv().encode(rows);

      final String userName = user['name'].toString().replaceAll(' ', '_');
      final fileName =
          'Rekap_Absensi_$userName'
          '-${adminC.selectedMonthAdmin.value}  ';

      Uint8List bytes = Uint8List.fromList(utf8.encode(csvData));

      String savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );

      if (savedPath.isNotEmpty) {
        Get.snackbar(
          'Berhasil Diunduh',
          'File tersimpan di: $savedPath',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          mainButton: TextButton(
            onPressed: () {
              Share.shareXFiles([
                XFile(savedPath),
              ], text: 'Rekap Absensi $userName');
            },
            child: const Text(
              'BAGIKAN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else {
        Get.snackbar('Informasi', 'Penyimpanan CSV dibatalkan');
      }
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan saat menyimpan data: $e');
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
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
            color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              if (!isSelected)
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
