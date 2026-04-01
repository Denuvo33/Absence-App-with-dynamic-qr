import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/absence_controller.dart';
import '../controllers/leave_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final absenceC = Get.find<AbsenceController>();
    final leaveC = Get.find<LeaveController>();
    absenceC.loadHistory();
    leaveC.loadLeaveRequests();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF00897B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Obx(() {
              final month = absenceC.selectedMonth.value;
              final label = DateFormat('MMMM yyyy', 'id_ID').format(month);
              final isCurrentMonth =
                  month.month == DateTime.now().month &&
                  month.year == DateTime.now().year;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: absenceC.previousMonth,
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: isCurrentMonth ? null : absenceC.nextMonth,
                    icon: Icon(
                      Icons.chevron_right,
                      color: isCurrentMonth ? Colors.white38 : Colors.white,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 20),

          // Stats
          Expanded(
            child: Obx(() {
              if (absenceC.isHistoryLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = absenceC.filteredHistory;
              final totalHadir = history.length;
              final lateDays = history
                  .where((e) => e['status'] == 'late')
                  .length;
              final onTimeDays = history
                  .where((e) => e['status'] == 'on_time')
                  .length;
              final totalLateMinutes = history.fold<int>(
                0,
                (sum, e) => sum + ((e['lateMinutes'] as int?) ?? 0),
              );

              // Count approved leaves for selected month
              final selMonth = absenceC.selectedMonth.value;
              int totalIzinDays = 0;
              for (final req in leaveC.leaveList) {
                if (req['status'] != 'approved') continue;
                final start = DateTime.tryParse(req['startDate'] ?? '');
                final end = DateTime.tryParse(req['endDate'] ?? '');
                if (start == null || end == null) continue;
                // Count days that fall within selected month
                for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
                  if (d.month == selMonth.month && d.year == selMonth.year) {
                    totalIzinDays++;
                  }
                }
              }

              // Average work duration
              int totalWorkMinutes = 0;
              int workDayCount = 0;
              for (final e in history) {
                final cin = e['clockIn'] as DateTime?;
                final cout = e['clockOut'] as DateTime?;
                if (cin != null && cout != null) {
                  totalWorkMinutes += cout.difference(cin).inMinutes;
                  workDayCount++;
                }
              }
              final avgWorkMinutes = workDayCount > 0
                  ? totalWorkMinutes ~/ workDayCount
                  : 0;
              final avgHours = avgWorkMinutes ~/ 60;
              final avgMins = avgWorkMinutes % 60;

              // Attendance rate = hadir / (hadir + izin days)
              final totalExpected = totalHadir + totalIzinDays;
              final attendanceRate = totalExpected > 0
                  ? (totalHadir / totalExpected * 100)
                  : 0.0;
              final punctualityRate = totalHadir > 0
                  ? (onTimeDays / totalHadir * 100)
                  : 0.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Top stats grid
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Hadir',
                            value: '$totalHadir',
                            subtitle: 'hari',
                            icon: Icons.calendar_month,
                            color: const Color(0xFF4A6CF7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Izin/Cuti',
                            value: '$totalIzinDays',
                            subtitle: 'hari',
                            icon: Icons.event_note_rounded,
                            color: const Color(0xFFEF6C00),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Tepat Waktu',
                            value: '$onTimeDays',
                            subtitle: 'hari',
                            icon: Icons.thumb_up_outlined,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Terlambat',
                            value: '$lateDays',
                            subtitle: 'hari',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Detailed stats
                    _DetailCard(
                      items: [
                        _DetailItem(
                          icon: Icons.timer_off_outlined,
                          label: 'Total Keterlambatan',
                          value: totalLateMinutes > 0
                              ? '${totalLateMinutes ~/ 60}j ${totalLateMinutes % 60}m'
                              : '0m',
                          color: Colors.red.shade600,
                        ),
                        _DetailItem(
                          icon: Icons.timer,
                          label: 'Rata-rata Jam Kerja',
                          value: workDayCount > 0
                              ? '${avgHours}j ${avgMins}m'
                              : '-',
                          color: const Color(0xFFF57C00),
                        ),
                        _DetailItem(
                          icon: Icons.percent,
                          label: 'Tingkat Kehadiran',
                          value: totalExpected > 0
                              ? '${attendanceRate.toStringAsFixed(0)}%'
                              : '-',
                          color: const Color(0xFF00897B),
                        ),
                        _DetailItem(
                          icon: Icons.schedule,
                          label: 'Tingkat Ketepatan',
                          value: totalHadir > 0
                              ? '${punctualityRate.toStringAsFixed(0)}%'
                              : '-',
                          color: const Color(0xFF4A6CF7),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DetailCard extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Ringkasan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
