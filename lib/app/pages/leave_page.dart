import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/leave_controller.dart';

class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    final leaveC = Get.find<LeaveController>();
    leaveC.loadLeaveRequests();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Pengajuan Izin/Cuti',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Form header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Text(
                'Buat Pengajuan Baru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                    // Type selector
                    Text(
                      'Jenis Pengajuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          children: [
                            _TypeChip(
                              label: 'Izin',
                              isSelected: leaveC.selectedType.value == 'izin',
                              onTap: () => leaveC.selectedType.value = 'izin',
                              color: const Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(
                              label: 'Cuti',
                              isSelected: leaveC.selectedType.value == 'cuti',
                              onTap: () => leaveC.selectedType.value = 'cuti',
                              color: const Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(
                              label: 'Sakit',
                              isSelected: leaveC.selectedType.value == 'sakit',
                              onTap: () => leaveC.selectedType.value = 'sakit',
                              color: const Color(0xFF0F172A),
                            ),
                          ],
                        )),

                    const SizedBox(height: 20),

                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => _DateField(
                                label: 'Tanggal Mulai',
                                value: leaveC.startDate.value,
                                onTap: () => _pickDate(context, leaveC, true),
                              )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() => _DateField(
                                label: 'Tanggal Selesai',
                                value: leaveC.endDate.value,
                                onTap: () => _pickDate(context, leaveC, false),
                              )),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Reason
                    Text(
                      'Alasan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: leaveC.reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tulis alasan pengajuan...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC), // Slate 50
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: leaveC.isLoading.value
                                ? null
                                : leaveC.submitLeave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: leaveC.isLoading.value
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Kirim Pengajuan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Request list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Riwayat Pengajuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (leaveC.isListLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (leaveC.leaveList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pengajuan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: leaveC.leaveList
                      .map((item) => _LeaveCard(
                            item: item,
                            onCancel: item['status'] == 'pending'
                                ? () => _confirmCancel(leaveC, item['id'])
                                : null,
                          ))
                      .toList(),
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext context, LeaveController leaveC, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (isStart) {
        leaveC.startDate.value = picked;
      } else {
        leaveC.endDate.value = picked;
      }
    }
  }

  void _confirmCancel(LeaveController leaveC, String id) {
    Get.defaultDialog(
      title: 'Batalkan?',
      middleText: 'Yakin ingin membatalkan pengajuan ini?',
      textCancel: 'Tidak',
      textConfirm: 'Ya, Batalkan',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      onConfirm: () {
        Get.back();
        leaveC.cancelRequest(id);
      },
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? DateFormat('d MMM yyyy', 'id_ID').format(value!)
                      : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        value != null ? Colors.grey.shade800 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onCancel;

  const _LeaveCard({required this.item, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final status = item['status'] as String;
    final startDate = item['startDate'] as String;
    final endDate = item['endDate'] as String;
    final reason = item['reason'] as String;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green.shade600;
        statusLabel = 'Disetujui';
      case 'rejected':
        statusColor = Colors.red.shade600;
        statusLabel = 'Ditolak';
      default:
        statusColor = Colors.orange.shade600;
        statusLabel = 'Menunggu';
    }

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (type) {
      case 'cuti':
        typeColor = const Color(0xFF0F172A);
        typeIcon = Icons.beach_access;
        typeLabel = 'Cuti';
      case 'sakit':
        typeColor = Colors.red.shade600;
        typeIcon = Icons.local_hospital;
        typeLabel = 'Sakit';
      default:
        typeColor = const Color(0xFF475569);
        typeIcon = Icons.event_note;
        typeLabel = 'Izin';
    }

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
              // Type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date range
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '$startDate  →  $endDate',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reason
          Text(
            reason,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Cancel button (only for pending)
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
                label: Text(
                  'Batalkan',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
