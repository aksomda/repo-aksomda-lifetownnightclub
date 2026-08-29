import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  final AuthController controller;
  final VoidCallback onLogin;

  const RegisterPage({
    super.key,
    required this.controller,
    required this.onLogin,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prenameController = TextEditingController();
  final _ageController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _nameController,
      _prenameController,
      _ageController,
      _telephoneController,
      _emailController,
      _passwordController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await widget.controller.register(
      name: _nameController.text.trim(),
      prename: _prenameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      telephone: _telephoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé.')),
      );
      widget.onLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Échec de l’inscription',
          ),
        ),
      );
    }
  }

  InputDecoration decoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: decoration('Nom'),
                    validator: requiredField,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _prenameController,
                    decoration: decoration('Prénom'),
                    validator: requiredField,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: decoration('Âge'),
                    validator: (value) {
                      final age = int.tryParse(value?.trim() ?? '');
                      return age == null || age <= 0 ? 'Âge invalide' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    decoration: decoration('Téléphone'),
                    validator: requiredField,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: decoration('Email'),
                    validator: (value) =>
                        value == null || !value.contains('@')
                            ? 'Email invalide'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: decoration('Mot de passe'),
                    validator: (value) => value == null || value.length < 6
                        ? '6 caractères minimum'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) {
                      if (widget.controller.isLoading) {
                        return const CircularProgressIndicator();
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submit,
                          child: const Text('Créer le compte'),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: widget.onLogin,
                    child: const Text('J’ai déjà un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'Requis' : null;
}
