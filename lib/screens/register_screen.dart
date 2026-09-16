import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _serverErrors.clear();
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final api = context.read<AuthApi>();
      final auth = context.read<AuthNotifier>();

      await api.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      await auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      context.go('/');
    } on ValidationException catch (e) {
      setState(() {
        _serverErrors.addAll(e.errors);
      });
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── ФИО ───
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'ФИО',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    maxLength: 100,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[А-Яа-яЁё\s\-]'),
                      ),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final serverError = _serverErrors['fullName'];
                      if (serverError != null) return serverError;
                      if (v == null || v.trim().isEmpty) return 'Введите ФИО';
                      if (!RegExp(r'^[А-Яа-яЁё\s\-]+$').hasMatch(v.trim())) {
                        return 'ФИО: только русские буквы, пробел и дефис';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Логин ───
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    maxLength: 30,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]'),
                      ),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final serverError = _serverErrors['username'];
                      if (serverError != null) return serverError;
                      if (v == null || v.trim().isEmpty) return 'Введите логин';
                      if (!RegExp(r'[a-zA-Z]').hasMatch(v)) {
                        return 'Логин: обязательна хотя бы одна латинская буква';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                        return 'Логин: только латиница, цифры и _';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Email ───
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 100,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final serverError = _serverErrors['email'];
                      if (serverError != null) return serverError;
                      if (v == null || v.trim().isEmpty) return 'Введите email';
                      final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');
                      if (!re.hasMatch(v.trim())) return 'Некорректный email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Пароль ───
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    obscureText: true,
                    maxLength: 64,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9!@#\$%^&*(),.?":{}|<>_\-]'),
                      ),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final serverError = _serverErrors['password'];
                      if (serverError != null) return serverError;
                      if (v == null || v.isEmpty) return 'Введите пароль';
                      if (v.length < 8) {
                        return 'Пароль не короче 8 символов';
                      }
                      if (!RegExp(r'[a-zA-Z]').hasMatch(v)) {
                        return 'Пароль: обязательна хотя бы одна латинская буква';
                      }
                      if (!RegExp(r'\d').hasMatch(v)) {
                        return 'Пароль: обязательна хотя бы одна цифра';
                      }
                      if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) {
                        return 'Пароль: обязателен хотя бы один специальный символ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isSaving ? null : () => context.go('/login'),
                    child: const Text('У меня уже есть аккаунт'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
