import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
  String _currentTab = 'absensi'; // 'absensi' or 'logbook'

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
          'Detail Anak Magang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Unduh Rekapan',
            onSelected: (value) {
              if (value == 'csv') {
                _exportToCSV();
              } else if (value == 'pdf') {
                _exportLogbookToPDF();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Rekap Absensi (CSV)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Rekap Logbook (PDF)'),
                  ],
                ),
              ),
            ],
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
                      backgroundColor: const Color(0xFF4A6CF7).withValues(alpha: 0.1),
                      child: Text(
                        user['name'] != null && user['name'].toString().isNotEmpty
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(
                          label: Text('Divisi: ${user['divisi']}'),
                          backgroundColor: const Color(0xFFE8EAF6),
                          labelStyle: const TextStyle(
                            color: Color(0xFF4A6CF7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Chip(
                          label: Text('Asal: ${user['asal']}'),
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Tindakan Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showEditProfileDialog(user.cast<String, dynamic>()),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Profil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6CF7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showResetPasswordDialog(user['email']),
                          icon: const Icon(Icons.lock_reset, size: 16),
                          label: const Text('Reset PW'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            side: BorderSide(color: Colors.orange.shade800),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteUserDialog(user.cast<String, dynamic>()),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Hapus'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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
                      isSelected: _filter == 'hadir' && _currentTab == 'absensi',
                      onTap: () {
                        setState(() {
                          _currentTab = 'absensi';
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
                      isSelected: _filter == 'leave' && _currentTab == 'absensi',
                      onTap: () {
                        setState(() {
                          _currentTab = 'absensi';
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
                      isSelected: _filter == 'on_time' && _currentTab == 'absensi',
                      onTap: () {
                        setState(() {
                          _currentTab = 'absensi';
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
                      isSelected: _filter == 'late' && _currentTab == 'absensi',
                      onTap: () {
                        setState(() {
                          _currentTab = 'absensi';
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
              const SizedBox(height: 16),

              // Points Summary card
              Container(
                width: double.infinity,
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
                      'Informasi Poin Bulan Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _PointColumn(
                          title: 'Poin Absensi',
                          points: adminC.totalPointsAbsen,
                          color: const Color(0xFF00897B),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _PointColumn(
                          title: 'Poin Logbook',
                          points: adminC.totalPointsLogbook,
                          color: const Color(0xFF4A6CF7),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _PointColumn(
                          title: 'Total Poin',
                          points: adminC.totalPointsBoth,
                          color: Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                        onPressed: isCurrentMonth ? null : adminC.nextAdminMonth,
                        icon: Icon(
                          Icons.chevron_right,
                          color: isCurrentMonth ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // Segmented Tab Selector
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentTab = 'absensi'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _currentTab == 'absensi'
                                  ? const Color(0xFF4A6CF7)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Absensi & Izin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _currentTab == 'absensi'
                                ? const Color(0xFF4A6CF7)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentTab = 'logbook'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _currentTab == 'logbook'
                                  ? const Color(0xFF4A6CF7)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Logbook Anak Magang',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _currentTab == 'logbook'
                                ? const Color(0xFF4A6CF7)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Conditional Rendering
              _currentTab == 'absensi' ? _buildAttendanceList() : _buildLogbookList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAttendanceList() {
    if (adminC.filteredUserHistory.isEmpty) {
      return const Center(child: Text('Belum ada riwayat absensi.'));
    }

    final filteredList = adminC.filteredUserHistory.where((item) {
      if (_filter == 'all') return true;
      if (_filter == 'hadir') {
        return item['recordType'] == 'attendance';
      }
      if (_filter == 'leave') {
        return item['recordType'] == 'leave';
      }
      if (_filter == 'late') {
        return item['recordType'] == 'attendance' && item['status'] == 'late';
      }
      if (_filter == 'on_time') {
        return item['recordType'] == 'attendance' && item['status'] == 'on_time';
      }
      return true;
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data pada filter ini.'),
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
            ? DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        item['leaveType']?.toString().toUpperCase() ?? 'IZIN',
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

        final clockIn = item['clockIn'] != null ? DateFormat('HH:mm').format(item['clockIn']) : '--:--';
        final clockOut = item['clockOut'] != null ? DateFormat('HH:mm').format(item['clockOut']) : '--:--';
        final clockInLoc = item['clockInLocation']?.toString() ?? '-';
        final clockOutLoc = item['clockOutLocation']?.toString() ?? '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isLate ? Border.all(color: Colors.red.shade200) : null,
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
                        color: isLate ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLate ? 'Telat ${item['lateMinutes']}m' : 'Tepat Waktu',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLate ? Colors.red.shade700 : Colors.green.shade700,
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          color: isLate ? Colors.red : Colors.black87,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
  }

  Widget _buildLogbookList() {
    final month = adminC.selectedMonthAdmin.value.month;
    final year = adminC.selectedMonthAdmin.value.year;

    final filteredLogs = adminC.selectedUserLogbooks.where((item) {
      final createdAt = item['createdAt'] as int? ?? 0;
      if (createdAt > 0) {
        final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
        return date.month == month && date.year == year;
      }
      return false;
    }).toList();

    if (filteredLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text('Belum ada logbook pada bulan ini.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final item = filteredLogs[index];
        final createdAt = DateTime.fromMillisecondsSinceEpoch(
          item['createdAt'] as int,
        );
        final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt);
        final isEdited = (item['updatedAt'] as int) > (item['createdAt'] as int);

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
                    dateStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditLogbookDialog(item);
                      } else if (value == 'delete') {
                        _showDeleteLogbookDialog(item['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade400,
                      size: 20,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  if (isEdited) ...[
                    const Spacer(),
                    Text(
                      'diedit',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(Map<String, dynamic> user) {
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
                initialValue: selectedDivisi.value.isEmpty ||
                        !divisions.any((div) => div['name'] == selectedDivisi.value)
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
          uid,
          name: nameCtrl.text.trim(),
          divisi: selectedDivisi.value,
          asal: asalCtrl.text.trim(),
        );
      },
    );
  }

  void _showResetPasswordDialog(String email) {
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

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    Get.defaultDialog(
      title: 'Hapus Anak Magang',
      middleText:
          'Apakah Anda yakin ingin menghapus akun "${user['name']}"? Semua data di database akan hilang dan aksi ini tidak bisa dibatalkan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () {
        Get.back(); // close dialog
        Get.back(); // go back to previous page
        adminC.deleteUser(uid);
      },
    );
  }

  void _showEditLogbookDialog(Map<String, dynamic> item) {
    final contentCtrl = TextEditingController(text: item['content']);
    final pointsCtrl = TextEditingController(text: item['points'].toString());
    final selectedDivisi = (item['divisi'] ?? '').toString().obs;

    Get.defaultDialog(
      title: 'Edit Logbook',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi Aktivitas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final divisions = adminC.divisionsList;
              return DropdownButtonFormField<String>(
                initialValue: selectedDivisi.value.isEmpty ||
                        !divisions.any((div) => div['name'] == selectedDivisi.value)
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
        final pts = int.tryParse(pointsCtrl.text.trim()) ?? 0;
        Get.back();
        adminC.updateLogbookForUser(
          uid,
          item['id'],
          content: contentCtrl.text.trim(),
          divisi: selectedDivisi.value,
          points: pts,
        );
      },
    );
  }

  void _showDeleteLogbookDialog(String logbookId) {
    Get.defaultDialog(
      title: 'Hapus Logbook',
      middleText: 'Apakah Anda yakin ingin menghapus logbook ini?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () {
        Get.back();
        adminC.deleteLogbookForUser(uid, logbookId);
      },
    );
  }

  Future<void> _exportLogbookToPDF() async {
    final user = adminC.selectedUserInfo;
    if (user.isEmpty) {
      Get.snackbar('Gagal', 'Data pengguna belum tersedia');
      return;
    }

    final doc = pw.Document();

    final month = adminC.selectedMonthAdmin.value.month;
    final year = adminC.selectedMonthAdmin.value.year;
    final filteredLogs = adminC.selectedUserLogbooks.where((item) {
      final createdAt = item['createdAt'] as int? ?? 0;
      if (createdAt > 0) {
        final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
        return date.month == month && date.year == year;
      }
      return false;
    }).toList();

    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(adminC.selectedMonthAdmin.value);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('REKAPITULASI LOGBOOK ANAK MAGANG',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(monthName, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('DATA PROFIL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FixedColumnWidth(10),
                2: const pw.FixedColumnWidth(300),
              },
              children: [
                pw.TableRow(children: [pw.Text('Nama'), pw.Text(':'), pw.Text(user['name'] ?? '')]),
                pw.TableRow(children: [pw.Text('Email'), pw.Text(':'), pw.Text(user['email'] ?? '')]),
                pw.TableRow(children: [pw.Text('Divisi'), pw.Text(':'), pw.Text(user['divisi'] ?? '')]),
                pw.TableRow(children: [pw.Text('Asal'), pw.Text(':'), pw.Text(user['asal'] ?? '')]),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('RIWAYAT LOGBOOK',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            if (filteredLogs.isEmpty)
              pw.Text('Tidak ada logbook untuk bulan ini.')
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['No', 'Tanggal', 'Divisi', 'Isi Aktivitas', 'Poin'],
                data: List<List<String>>.generate(filteredLogs.length, (index) {
                  final item = filteredLogs[index];
                  final date = DateTime.fromMillisecondsSinceEpoch(item['createdAt']);
                  final dateStr = DateFormat('dd-MM-yyyy HH:mm').format(date);
                  return [
                    '${index + 1}',
                    dateStr,
                    item['divisi'] ?? '-',
                    item['content'] ?? '',
                    '${item['points']} Poin',
                  ];
                }),
              ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('TOTAL POIN REKAPITULASI',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Poin Absensi:'),
                pw.Text('${adminC.totalPointsAbsen} Poin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Poin Logbook:'),
                pw.Text('${adminC.totalPointsLogbook} Poin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Nilai Keseluruhan:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('${adminC.totalPointsBoth} Poin',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final Uint8List bytes = await doc.save();
      final String userName = user['name'].toString().replaceAll(' ', '_');
      final monthStr = monthName.replaceAll(' ', '_');
      final fileName = 'Rekap_Logbook_${userName}_$monthStr';

      String savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
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
              // ignore: deprecated_member_use
              Share.shareXFiles([
                XFile(savedPath),
              ], text: 'Rekap Logbook $userName');
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
        Get.snackbar('Informasi', 'Penyimpanan PDF dibatalkan');
      }
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan saat menyimpan PDF: $e');
    }
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
    rows.add(['LAPORAN ABSENSI ANAK MAGANG']);
    rows.add([]);

    // Profil
    rows.add(['DATA PROFIL']);
    rows.add(['Nama', user['name']]);
    rows.add(['Email', user['email']]);
    rows.add(['Divisi', user['divisi']]);
    rows.add(['Asal', user['asal']]);
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
      final dateStr = date != null ? DateFormat('yyyy-MM-dd').format(date) : (item['dateKey'] ?? '-');

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
        final clockInStr = item['clockIn'] != null ? DateFormat('HH:mm').format(item['clockIn']) : '-';
        final clockInLoc = item['clockInLocation']?.toString() ?? '-';
        final clockOutStr = item['clockOut'] != null ? DateFormat('HH:mm').format(item['clockOut']) : '-';
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
      final monthName = DateFormat('MMMM_yyyy', 'id_ID').format(adminC.selectedMonthAdmin.value);
      final fileName = 'Rekap_Absensi_${userName}_$monthName';

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
              // ignore: deprecated_member_use
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

class _PointColumn extends StatelessWidget {
  final String title;
  final int points;
  final Color color;

  const _PointColumn({
    required this.title,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$points',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
