import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../providers/school_provider.dart';

class SchoolProfileScreen extends ConsumerStatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  ConsumerState<SchoolProfileScreen> createState() =>
      _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends ConsumerState<SchoolProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _npsnController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isEditing = false;
  bool _showAddYear = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolProvider.notifier).fetchSchoolProfile();
      ref.read(schoolProvider.notifier).fetchAcademicYears();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _npsnController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _startEdit(Map<String, dynamic>? profile) {
    if (profile == null) return;
    _nameController.text = profile['name'] as String? ?? '';
    _addressController.text = profile['address'] as String? ?? '';
    _phoneController.text = profile['phone'] as String? ?? '';
    _emailController.text = profile['email'] as String? ?? '';
    _npsnController.text = profile['npsn'] as String? ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final dto = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'npsn': _npsnController.text.trim(),
    };

    final error = await ref.read(schoolProvider.notifier).updateSchoolProfile(dto);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil sekolah berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _addYear() async {
    final year = _yearController.text.trim();
    if (year.isEmpty) return;

    final error = await ref
        .read(schoolProvider.notifier)
        .createAcademicYear({'year': year});

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        _yearController.clear();
        setState(() => _showAddYear = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahun ajaran berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(String id, bool isActive) async {
    if (isActive) return;
    final error =
        await ref.read(schoolProvider.notifier).setActiveYear(id);
    if (mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteYear(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tahun Ajaran'),
        content: const Text('Yakin ingin menghapus tahun ajaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error =
          await ref.read(schoolProvider.notifier).deleteAcademicYear(id);
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Sekolah'),
        actions: [
          if (state.profile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _startEdit(state.profile),
              tooltip: 'Edit Profil',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSchoolProfile(state),
                  const SizedBox(height: 24),
                  _buildAcademicYears(state),
                ],
              ),
            ),
    );
  }

  Widget _buildSchoolProfile(SchoolState state) {
    final profile = state.profile;

    if (_isEditing) {
      return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profil Sekolah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nama Sekolah',
              controller: _nameController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Alamat',
              controller: _addressController,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'No. Telepon',
              controller: _phoneController,
              isPhone: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'NPSN',
              controller: _npsnController,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Batal',
                    isOutlined: true,
                    onPressed: () => setState(() => _isEditing = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Simpan',
                    isLoading: state.isUpdating,
                    onPressed: _saveProfile,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (profile == null) {
      return const Center(
        child: Text('Gagal memuat data sekolah'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] as String? ?? 'Nama Sekolah',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (profile['npsn'] != null)
                      Text(
                        'NPSN: ${profile['npsn']}',
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
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, 'Alamat',
              profile['address'] as String? ?? '-'),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, 'Telepon',
              profile['phone'] as String? ?? '-'),
          const SizedBox(height: 8),
          _infoRow(Icons.email_outlined, 'Email',
              profile['email'] as String? ?? '-'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicYears(SchoolState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tahun Ajaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _showAddYear = !_showAddYear),
              icon: Icon(
                _showAddYear ? Icons.close : Icons.add,
                size: 18,
              ),
              label: Text(_showAddYear ? 'Batal' : 'Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_showAddYear)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Tahun Ajaran',
                    hint: 'Contoh: 2025/2026',
                    controller: _yearController,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.isCreatingYear ? null : _addYear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isCreatingYear
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                  ),
                ),
              ],
            ),
          ),
        if (state.academicYears.isEmpty && !state.isLoading)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Belum ada tahun ajaran',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...state.academicYears.map((year) => _buildYearItem(year, state)),
      ],
    );
  }

  Widget _buildYearItem(Map<String, dynamic> year, SchoolState state) {
    final id = year['id'] as String? ?? '';
    final yearLabel = year['year'] as String? ?? '-';
    final isActive = year['isActive'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppColors.success : AppColors.border,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: isActive ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          yearLabel,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isActive ? 'Aktif' : 'Tidak Aktif',
          style: TextStyle(
            color: isActive ? AppColors.success : AppColors.textHint,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: state.isSettingActive
                      ? null
                      : () => _toggleActive(id, isActive),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: state.isSettingActive
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Aktifkan', style: TextStyle(fontSize: 12)),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
              onPressed: state.isDeletingYear ? null : () => _deleteYear(id),
            ),
          ],
        ),
      ),
    );
  }
}
