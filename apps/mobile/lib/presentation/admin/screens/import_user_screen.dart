import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../providers/user_provider.dart';

class ImportUserScreen extends ConsumerStatefulWidget {
  const ImportUserScreen({super.key});

  @override
  ConsumerState<ImportUserScreen> createState() => _ImportUserScreenState();
}

class _ImportUserScreenState extends ConsumerState<ImportUserScreen> {
  List<Map<String, dynamic>>? _parsedData;
  bool _isImporting = false;
  int? _importedCount;
  int? _failedCount;

  void _simulatePickFile() {
    final sampleCsv = '''nis,name,email,role
2023001,Andi Pratama,andi@email.com,SISWA
2023002,Siti Nurhaliza,siti@email.com,SISWA
1987001,Budi Santoso,budi@email.com,GURU
2023003,Dewi Lestari,dewi@email.com,SISWA
1987002,Ahmad Hidayat,ahmad@email.com,WALI_KELAS''';

    final lines = LineSplitter.split(sampleCsv).toList();
    if (lines.isEmpty) return;

    final headers = lines[0].split(',');
    final data = <Map<String, dynamic>>[];

    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length != headers.length) continue;
      final row = <String, dynamic>{};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j].trim()] = values[j].trim();
      }
      data.add(row);
    }

    setState(() {
      _parsedData = data;
      _importedCount = null;
      _failedCount = null;
    });
  }

  Future<void> _confirmImport() async {
    if (_parsedData == null || _parsedData!.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importedCount = 0;
      _failedCount = 0;
    });

    int imported = 0;
    int failed = 0;

    for (final row in _parsedData!) {
      final dto = <String, dynamic>{
        'nis': row['nis'] ?? '',
        'name': row['name'] ?? '',
        'email': row['email'] ?? '',
        'role': row['role'] ?? 'SISWA',
      };

      final error = await ref.read(userProvider.notifier).createUser(dto);
      if (error != null) {
        failed++;
      } else {
        imported++;
      }

      if (mounted) {
        setState(() {
          _importedCount = imported;
          _failedCount = failed;
        });
      }
    }

    if (mounted) {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Import CSV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Format CSV',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'File CSV harus memiliki header berikut:\n'
                    'nis, name, email, role\n\n'
                    'Role yang didukung: SISWA, GURU, WALI_KELAS, ADMIN, '
                    'BK, TU, KEPALA_SEKOLAH\n\n'
                    'Contoh:\n'
                    'nis,name,email,role\n'
                    '2023001,Andi Pratama,andi@email.com,SISWA',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_parsedData == null) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 64,
                      color: AppColors.textHint.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih file CSV untuk diimport',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Pilih File',
                      icon: Icons.folder_open,
                      onPressed: _simulatePickFile,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '(Demo: menggunakan data contoh)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_parsedData != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_parsedData!.length} data siap diimport',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _parsedData = null),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('NIS')),
                      DataColumn(label: Text('Nama')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                    ],
                    rows: List.generate(_parsedData!.length, (index) {
                      final row = _parsedData![index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(row['nis'] as String? ?? '')),
                        DataCell(Text(row['name'] as String? ?? '')),
                        DataCell(Text(row['email'] as String? ?? '')),
                        DataCell(Text(row['role'] as String? ?? '')),
                      ]);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isImporting || _importedCount != null) ...[
                if (_isImporting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Mengimport... ($_importedCount/${_parsedData!.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_importedCount != null && !_isImporting) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import selesai!',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_importedCount berhasil, $_failedCount gagal',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Kembali ke Daftar',
                    onPressed: () {
                      ref.read(userProvider.notifier).refresh();
                      context.pop();
                    },
                  ),
                ],
              ],
              if (!_isImporting && _importedCount == null) ...[
                AppButton(
                  label: 'Konfirmasi Import',
                  icon: Icons.upload,
                  onPressed: _confirmImport,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
