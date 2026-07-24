import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../providers/notification_provider.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  AnnouncementTarget _target = AnnouncementTarget.all;
  String? _selectedClass;
  bool _isPinned = false;
  bool _showPreview = false;

  final _availableClasses = [
    'X-A',
    'X-B',
    'XI-A',
    'XI-B',
    'XII-A',
    'XII-B',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showPreview ? 'Pratinjau' : 'Buat Pengumuman'),
        actions: [
          if (!_showPreview)
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _showPreview = true);
                }
              },
              child: const Text('Pratinjau'),
            ),
          if (_showPreview)
            TextButton(
              onPressed: () => setState(() => _showPreview = false),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: _showPreview ? _buildPreview(state) : _buildForm(state),
    );
  }

  Widget _buildForm(NotificationState state) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Pengumuman',
                hintText: 'Masukkan judul pengumuman',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Judul tidak boleh kosong';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Isi Pengumuman',
                hintText: 'Tulis isi pengumuman di sini...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Isi tidak boleh kosong';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Target',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AnnouncementTarget>(
              value: _target,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: AnnouncementTarget.all, child: Text('Semua')),
                DropdownMenuItem(value: AnnouncementTarget.siswa, child: Text('Siswa')),
                DropdownMenuItem(value: AnnouncementTarget.guru, child: Text('Guru')),
                DropdownMenuItem(value: AnnouncementTarget.waliKelas, child: Text('Wali Kelas')),
                DropdownMenuItem(value: AnnouncementTarget.kelas, child: Text('Kelas Tertentu')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _target = value);
              },
            ),
            if (_target == AnnouncementTarget.kelas) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Pilih Kelas',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _availableClasses.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (value) => setState(() => _selectedClass = value),
                validator: (value) {
                  if (_target == AnnouncementTarget.kelas && value == null) {
                    return 'Pilih kelas target';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Sematkan (Pin)'),
              subtitle: const Text('Pengumuman akan tampil di bagian atas'),
              value: _isPinned,
              onChanged: (value) => setState(() => _isPinned = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur lampiran akan segera hadir')),
                );
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('Tambah Lampiran'),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Simpan',
              isLoading: state.isLoading,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _submit();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(NotificationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isPinned)
            Row(
              children: [
                Icon(Icons.push_pin, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('Disematkan', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            _titleController.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Sekarang',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            _contentController.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Publikasikan',
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final dto = <String, dynamic>{
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'target': _target.name,
      'isPinned': _isPinned,
    };
    if (_target == AnnouncementTarget.kelas && _selectedClass != null) {
      dto['targetClass'] = _selectedClass;
    }

    try {
      await ref.read(notificationProvider.notifier).createAnnouncement(dto);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berhasil dibuat')),
        );
      }
    } catch (_) {}
  }
}
