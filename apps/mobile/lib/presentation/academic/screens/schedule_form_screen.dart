import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../common/widgets/app_button.dart';
import '../providers/schedule_provider.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String? scheduleId;
  final Map<String, dynamic>? extra;

  const ScheduleFormScreen({super.key, this.scheduleId, this.extra});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Day? _selectedDay;
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  final _roomController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEdit = false;
  String? _classId;
  String? _className;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];

  ScheduleItem? _existingItem;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.scheduleId != null;
    _classId = widget.extra?['classId'] as String?;
    _className = widget.extra?['className'] as String?;

    if (_isEdit) {
      _existingItem = widget.extra?['schedule'] as ScheduleItem?;
      if (_existingItem != null) {
        _selectedDay = _existingItem!.day;
        _selectedSubjectId = _existingItem!.subjectName;
        final parts = _existingItem!.startTime.split(':');
        _startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 7,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
        final endParts = _existingItem!.endTime.split(':');
        _endTime = TimeOfDay(
          hour: int.tryParse(endParts[0]) ?? 8,
          minute: endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0,
        );
        _roomController.text = _existingItem!.classRoom;
      }
    }

    Future.microtask(_loadFormData);
  }

  Future<void> _loadFormData() async {
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/academic/subjects'),
        dio.get('/users', queryParameters: {'role': 'GURU'}),
      ]);

      if (results[0].data is Map) {
        final data = results[0].data as Map<String, dynamic>;
        _subjects = (data['data'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
      }
      if (results[1].data is Map) {
        final data = results[1].data as Map<String, dynamic>;
        _teachers = (data['data'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _buildDto() {
    return {
      'day': _selectedDay!.name,
      'subjectId': _selectedSubjectId,
      'teacherId': _selectedTeacherId,
      'startTime': _formatTime(_startTime),
      'endTime': _formatTime(_endTime),
      'room': _roomController.text.trim(),
      if (_classId != null) 'classId': _classId,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      if (_isEdit) {
        await dio.patch('${ApiEndpoints.schedules}/${widget.scheduleId}',
            data: _buildDto());
      } else {
        await dio.post(ApiEndpoints.schedules, data: _buildDto());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Jadwal berhasil diperbarui' : 'Jadwal berhasil ditambahkan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message ?? 'Terjadi kesalahan';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Jadwal' : 'Tambah Jadwal';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_className != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.class_outlined,
                          size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Kelas: $_className',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_className != null) const SizedBox(height: 16),
              DropdownButtonFormField<Day>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Hari',
                  border: OutlineInputBorder(),
                ),
                items: Day.values.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedDay = value);
                },
                validator: (value) {
                  if (value == null) return 'Pilih hari';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Mata Pelajaran',
                  border: OutlineInputBorder(),
                ),
                items: _subjects.map((s) {
                  final id = s['id']?.toString() ?? '';
                  final name = s['name'] as String? ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedSubjectId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Pilih mata pelajaran';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Guru Pengajar',
                  border: OutlineInputBorder(),
                ),
                items: _teachers.map((t) {
                  final id = t['id']?.toString() ?? '';
                  final name = t['name'] as String? ?? '';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedTeacherId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Pilih guru';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickTime(isStart: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Mulai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _formatTime(_startTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickTime(isStart: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Selesai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _formatTime(_endTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Ruang',
                  hintText: 'Masukkan ruangan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.room_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ruang tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
