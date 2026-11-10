import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../repositories/profile_repository.dart';
import '../widgets/primary_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(currentPassword: _currentController.text, newPassword: _newController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tu contraseña se cambió.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = error is ApiException ? error.message : 'Ocurrió un error inesperado. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
                validator: (value) => (value == null || value.isEmpty) ? 'Escribe tu contraseña actual' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Repite la nueva contraseña'),
                validator: (value) => value != _newController.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Cambiar contraseña', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
