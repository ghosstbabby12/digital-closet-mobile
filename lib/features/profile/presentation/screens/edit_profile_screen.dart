import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/profile/domain/profile.dart';
import 'package:closet_ai/core/widgets/primary_button.dart';
import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/features/profile/presentation/controllers/profile_actions.dart';
import 'package:closet_ai/features/profile/domain/profile_validation.dart';

/// Edit name, email and phone. Changing the email asks for the current password.
class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.name ?? '');
  late final _emailController = TextEditingController(text: widget.profile.email);
  late final _phoneController = TextEditingController(text: widget.profile.phone ?? '');
  final _passwordController = TextEditingController();
  bool _saving = false;

  bool get _emailChanged => _emailController.text.trim() != widget.profile.email;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final email = _emailController.text.trim();
      await ref
          .read(profileActionsProvider)
          .update(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: email,
            currentPassword: _emailChanged ? _passwordController.text : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tus datos se guardaron.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar datos')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Correo'),
                onChanged: (_) => setState(() {}),
                validator: validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)', hintText: 'Ej. +57 300 123 4567'),
                validator: validatePhone,
              ),
              if (_emailChanged) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    helperText: 'Para cambiar el correo, confirma tu contraseña.',
                  ),
                  validator: requireCurrentPassword,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: 'Guardar cambios', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
