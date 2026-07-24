import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../providers/user_provider.dart';
import '../widgets/role_badge.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId;
  final Map<String, dynamic>? userData;

  const UserFormScreen({super.key, this.userId, this.userData});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  final _nipController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = 'SISWA';
  String _selectedGender = 'L';
  DateTime? _birthDate;
  bool _isSubmitting = false;
  bool _isEdit = false;

  final _roles = [
    'SISWA',
    'GURU',
    'WALI_KELAS',
    'ADMIN',
    'BK',
    'TU',
    'KEPALA_SEKOLAH',
  ];

  final _genders = [
    {'value': 'L', 'label': 'Laki-laki'},
    {'value': 'P', 'label': 'Perempuan'},
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.userId != null;
    if (_isEdit && widget.userData != null) {
      _prefillForm(widget.userData!);
    }
  }

  void _prefillForm(Map<String, dynamic> user) {
    _nisController.text = user['nis'] as String? ?? '';
    _nipController.text = user['nip'] as String? ?? '';
    _nameController.text = user['name'] as String? ?? '';
    _emailController.text = user['email'] as String? ?? '';
    _phoneController.text = user['phone'] as String? ?? '';
    _addressController.text = user['address'] as String? ?? '';
    _selectedRole = user['role'] as String? ?? 'SISWA';
    _selectedGender = user['gender'] as String? ?? 'L';
    if (user['birthDate'] != null) {
      _birthDate = DateTime.tryParse(user['birthDate'] as String);
    }
  }

  @override
  void dispose() {
    _nisController.dispose();
    _nipController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(1950),
      lastDate: now,

    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Map<String, dynamic> _buildDto() {
    return {
      'nis': _nisController.text.trim(),
      if (_nipController.text.trim().isNotEmpty)
        'nip': _nipController.text.trim(),
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'gender': _selectedGender,
      if (_birthDate != null)
        'birthDate': _birthDate!.toIso8601String().split('T')[0],
      'role': _selectedRole,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String? error;
    if (_isEdit) {
      error = await ref
          .read(userProvider.notifier)
          .updateUser(widget.userId!, _buildDto());
    } else {
      error = await ref.read(userProvider.notifier).createUser(_buildDto());
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Pengguna berhasil diperbarui'
                : 'Pengguna berhasil ditambahkan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Pengguna' : 'Tambah Pengguna';

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
              if (_isEdit)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      RoleBadge(role: _selectedRole),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${widget.userId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isEdit) const SizedBox(height: 16),
              AppTextField(
                label: 'NIS',
                hint: 'Nomor Induk Siswa',
                controller: _nisController,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIS tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'NIP',
                hint: 'Nomor Induk Pegawai (khusus Guru)',
                controller: _nipController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                hint: 'contoh@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'No. Telepon',
                hint: '08xxxxxxxxxx',
                controller: _phoneController,
                isPhone: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Alamat',
                hint: 'Masukkan alamat',
                controller: _addressController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(),
                ),
                items: _genders.map((g) {
                  return DropdownMenuItem(
                    value: g['value'],
                    child: Text(g['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Pilih tanggal',
                    style: TextStyle(
                      color: _birthDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        RoleBadge(role: role, isSmall: true),
                        const SizedBox(width: 8),
                        Text(RoleBadge.labelForRole(role)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah Pengguna',
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
