import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/grade_provider.dart';

class ComponentFormScreen extends ConsumerStatefulWidget {
  final String? componentId;
  final Map<String, dynamic>? extra;

  const ComponentFormScreen({super.key, this.componentId, this.extra});

  @override
  ConsumerState<ComponentFormScreen> createState() => _ComponentFormScreenState();
}

class _ComponentFormScreenState extends ConsumerState<ComponentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _maxScoreCtrl;
  String _type = 'Tugas';
  bool _isSubmitting = false;

  static const _types = ['Tugas', 'UTS', 'UAS', 'Praktik'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _maxScoreCtrl = TextEditingController(text: '100');

    if (widget.componentId != null && widget.extra != null) {
      final c = widget.extra!;
      _nameCtrl.text = c['name'] as String? ?? '';
      _type = c['type'] as String? ?? 'Tugas';
      _weightCtrl.text = (c['weight'] as num?)?.toString() ?? '';
      _maxScoreCtrl.text = (c['maxScore'] as int?)?.toString() ?? '100';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _maxScoreCtrl.dispose();
    super.dispose();
  }

  String? get _subjectId => widget.extra?['subjectId'] as String?;
  String? get _classId => widget.extra?['classId'] as String?;
  String? get _subjectName => widget.extra?['subjectName'] as String?;
  String? get _className => widget.extra?['className'] as String?;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final dto = {
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
      'maxScore': int.tryParse(_maxScoreCtrl.text.trim()) ?? 100,
      'subjectId': _subjectId,
      'classId': _classId,
    };

    final notifier = ref.read(gradeProvider.notifier);
    String? error;
    if (widget.componentId != null) {
      error = await notifier.updateComponent(widget.componentId!, dto);
    } else {
      error = await notifier.createComponent(dto);
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.componentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Komponen' : 'Tambah Komponen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_subjectName != null || _className != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_subjectName != null) ...[
                        Icon(Icons.book, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(_subjectName!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      if (_subjectName != null && _className != null)
                        const SizedBox(width: 12),
                      if (_className != null) ...[
                        Icon(Icons.meeting_room, size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(_className!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Komponen',
                  hintText: 'Cth: Tugas 1, UTS, UAS',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
                decoration: const InputDecoration(labelText: 'Tipe'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bobot (%)',
                  hintText: 'Cth: 25',
                  suffixText: '%',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Bobot wajib diisi';
                  final n = double.tryParse(v.trim());
                  if (n == null || n < 0 || n > 100) return 'Bobot 0-100';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxScoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Skor Maksimal',
                  hintText: 'Cth: 100',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Skor maksimal wajib diisi';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Masukkan angka valid';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Komponen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
