import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../academic/providers/teacher_subject_provider.dart';
import '../providers/assignment_provider.dart';

class AssignmentFormScreen extends ConsumerStatefulWidget {
  final String? assignmentId;
  final Map<String, dynamic>? extra;

  const AssignmentFormScreen({super.key, this.assignmentId, this.extra});

  @override
  ConsumerState<AssignmentFormScreen> createState() => _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends ConsumerState<AssignmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  String? _selectedSubjectId;
  String? _selectedClassId;
  DateTime? _deadline;
  String? _attachmentPath;
  bool _isSubmitting = false;

  bool get _isEditing => widget.assignmentId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherSubjectProvider.notifier).loadAll();
    });

    if (widget.extra != null) {
      _titleController.text = widget.extra!['title'] as String? ?? '';
      _descriptionController.text = widget.extra!['description'] as String? ?? '';

      _maxScoreController.text = (widget.extra!['maxScore'] as int?)?.toString() ?? '';
      final deadlineStr = widget.extra!['deadline'] as String?;
      if (deadlineStr != null) {
        _deadline = DateTime.tryParse(deadlineStr);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherSubjects = ref.watch(teacherSubjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tugas' : 'Buat Tugas'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Judul Tugas',
                hint: 'Masukkan judul tugas',
                controller: _titleController,
                validator: (v) => v?.isEmpty == true ? 'Judul harus diisi' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Deskripsi',
                hint: 'Masukkan deskripsi tugas',
                maxLines: 5,
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),
              Text(
                'Mata Pelajaran',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  hintText: 'Pilih mata pelajaran',
                ),
                items: teacherSubjects.assignments.map((a) {
                  final name = a['subjectName'] as String? ?? a['name'] as String? ?? '';
                  final id = a['subjectId']?.toString() ?? a['id']?.toString() ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedSubjectId = id;
                  });
                },
                validator: (v) => v == null ? 'Mapel harus dipilih' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Kelas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  hintText: 'Pilih kelas',
                ),
                items: teacherSubjects.classes.map((c) {
                  final name = c['name'] as String? ?? '';
                  final id = c['id']?.toString() ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedClassId = id;
                  });
                },
                validator: (v) => v == null ? 'Kelas harus dipilih' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Batas Waktu',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _deadline != null
                            ? DateFormat('d MMM yyyy, HH:mm', 'id').format(_deadline!)
                            : 'Pilih tanggal dan waktu',
                        style: TextStyle(
                          color: _deadline != null ? AppColors.textPrimary : AppColors.textHint,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nilai Maksimal',
                hint: '100',
                keyboardType: TextInputType.number,
                controller: _maxScoreController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nilai maksimal harus diisi';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Lampiran',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickAttachment,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        _attachmentPath != null
                            ? _attachmentPath!.split('/').last
                            : 'Tambah Lampiran (opsional)',
                        style: TextStyle(
                          color: _attachmentPath != null ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      if (_attachmentPath != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _attachmentPath = null),
                          child: const Icon(Icons.close, size: 18, color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEditing ? 'Simpan Perubahan' : 'Buat Tugas',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal batas waktu',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 59),
      helpText: 'Pilih waktu batas waktu',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (time == null || !mounted) return;

    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickAttachment() async {
    setState(() {
      _attachmentPath = '/tmp/sample.pdf';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batas waktu harus diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dto = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'subjectId': _selectedSubjectId,
      'classId': _selectedClassId,
      'deadline': _deadline!.toIso8601String(),
      'maxScore': int.tryParse(_maxScoreController.text.trim()) ?? 100,
    };

    String? error;
    if (_isEditing) {
      error = await ref.read(assignmentProvider.notifier).updateAssignment(widget.assignmentId!, dto);
    } else {
      error = await ref.read(assignmentProvider.notifier).createAssignment(dto);
    }

    setState(() => _isSubmitting = false);

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Tugas berhasil diperbarui' : 'Tugas berhasil dibuat')),
      );
      Navigator.pop(context);
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $error'), backgroundColor: AppColors.error),
      );
    }
  }
}
