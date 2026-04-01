import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/absence_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final absenceC = Get.find<AbsenceController>();
    absenceC.loadHistory();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4A6CF7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Obx(() {
              final month = absenceC.selectedMonth.value;
              final label = DateFormat('MMMM yyyy', 'id_ID').format(month);
              final isCurrentMonth = month.month == DateTime.now().month &&
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

          const SizedBox(height: 16),

          // History list
          Expanded(
            child: Obx(() {
              if (absenceC.isHistoryLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = absenceC.filteredHistory;

              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat absensi',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'di bulan ini',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _HistoryCard(item: item);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = item['date'] as DateTime?;
    final clockIn = item['clockIn'] as DateTime?;
    final clockOut = item['clockOut'] as DateTime?;
    final duration = item['duration'] as String;
    final isComplete = item['isComplete'] as bool;
    final lateMinutes = item['lateMinutes'] as int? ?? 0;
    final status = item['status']?.toString() ?? 'on_time';

    final dayName = date != null ? DateFormat('EEEE', 'id_ID').format(date) : '-';
    final dateStr = date != null ? DateFormat('d MMM yyyy', 'id_ID').format(date) : '-';
    final clockInStr = clockIn != null ? DateFormat('HH:mm').format(clockIn) : '--:--';
    final clockOutStr = clockOut != null ? DateFormat('HH:mm').format(clockOut) : '--:--';

    final isLate = status == 'late' && lateMinutes > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLate
            ? Border.all(color: Colors.red.shade200, width: 1)
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
          // Date header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
              Row(
                children: [
                  // Late badge
                  if (isLate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.red.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Telat ${lateMinutes}m',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? (isLate ? Colors.orange.shade50 : Colors.green.shade50)
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isComplete
                          ? (isLate ? 'Telat' : 'Tepat Waktu')
                          : 'Belum Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isComplete
                            ? (isLate ? Colors.orange.shade700 : Colors.green.shade700)
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Clock In / Clock Out / Duration
          Row(
            children: [
              _TimeChip(
                label: 'Masuk',
                time: clockInStr,
                icon: Icons.login_rounded,
                color: isLate ? Colors.red.shade600 : const Color(0xFF4A6CF7),
              ),
              const SizedBox(width: 12),
              _TimeChip(
                label: 'Pulang',
                time: clockOutStr,
                icon: Icons.logout_rounded,
                color: const Color(0xFF6C5CE7),
              ),
              const SizedBox(width: 12),
              _TimeChip(
                label: 'Durasi',
                time: duration,
                icon: Icons.timer_outlined,
                color: const Color(0xFFF57C00),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
