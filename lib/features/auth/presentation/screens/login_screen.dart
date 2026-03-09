import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/login_controller.dart';
import '../providers/register_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ResponsiveLayout(
        mobile: _LoginMobileView(),
        desktop: _LoginDesktopView(),
      ),
    );
  }
}

class _LoginMobileView extends StatelessWidget {
  const _LoginMobileView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _LogoAndTitle(),
              SizedBox(height: 40),
              _LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginDesktopView extends StatelessWidget {
  const _LoginDesktopView();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.primary,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "İşletmenizi\nGeleceğe Taşıyın.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: const Padding(
                          padding: EdgeInsets.all(48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LogoAndTitle(isDesktop: true),
                              SizedBox(height: 48),
                              _LoginForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoAndTitle extends StatelessWidget {
  final bool isDesktop;
  const _LogoAndTitle({this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.pets, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          "Tekrar Hoş Geldiniz!",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Hesabınıza giriş yaparak devam edin.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _identifierCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _clinicNameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _registerPhoneCtrl;
  late final TextEditingController _registerEmailCtrl;
  late final TextEditingController _registerPasswordCtrl;
  late final TextEditingController _registerConfirmPasswordCtrl;

  bool _obscurePassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;
  _AuthPanelMode _mode = _AuthPanelMode.login;

  @override
  void initState() {
    super.initState();

    _identifierCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _clinicNameCtrl = TextEditingController();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _registerPhoneCtrl = TextEditingController();
    _registerEmailCtrl = TextEditingController();
    _registerPasswordCtrl = TextEditingController();
    _registerConfirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _clinicNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _registerPhoneCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPasswordCtrl.dispose();
    _registerConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(loginControllerProvider.notifier);

    await controller.login(
      identifier: _identifierCtrl.text.trim(),
      password: _passwordCtrl.text,
      deviceName: "Mobile App",
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registerPasswordCtrl.text != _registerConfirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifre ve şifre tekrarı aynı olmalı"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fullName =
        '${_normalizePart(_firstNameCtrl.text)}_${_normalizePart(_lastNameCtrl.text)}';
    final register = ref.read(registerControllerProvider.notifier);
    await register.register(
      clinicName: _clinicNameCtrl.text.trim(),
      fullName: fullName,
      phone: _registerPhoneCtrl.text.trim(),
      email: _registerEmailCtrl.text.trim(),
      password: _registerPasswordCtrl.text,
    );
  }

  Future<void> _handleFreeTrial() async {
    final controller = ref.read(loginControllerProvider.notifier);
    await controller.login(
      identifier: "mehmet@example.com",
      password: "NewStrongPassword123",
      deviceName: "Trial Login",
    );
  }

  String _normalizePart(String input) {
    var value = input.trim().toLowerCase();
    const trMap = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u'};
    trMap.forEach((k, v) => value = value.replaceAll(k, v));
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<AsyncValue<void>>(loginControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Giriş hatası: $e"),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });
    ref.listen<AsyncValue<void>>(registerControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Kayıt hatası: $e"),
              backgroundColor: Colors.red,
            ),
          );
        },
        data: (_) {
          if (prev?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Kayıt başarılı, oturum açılıyor..."),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    });

    final loginState = ref.watch(loginControllerProvider);
    final registerState = ref.watch(registerControllerProvider);
    final isLoading = loginState.isLoading || registerState.isLoading;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () =>
                                setState(() => _mode = _AuthPanelMode.register),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            _mode == _AuthPanelMode.register
                                ? AppColors.primary
                                : AppColors.border,
                      ),
                      backgroundColor:
                          _mode == _AuthPanelMode.register
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.transparent,
                    ),
                    child: const Text("Kaydol"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () =>
                                setState(() => _mode = _AuthPanelMode.login),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            _mode == _AuthPanelMode.login
                                ? AppColors.primary
                                : AppColors.border,
                      ),
                      backgroundColor:
                          _mode == _AuthPanelMode.login
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.transparent,
                    ),
                    child: const Text("Giriş Yap"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_mode == _AuthPanelMode.login) ...[
              const Text(
                "E-posta veya Telefon",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _identifierCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: "E-posta veya telefon",
                ),
                validator: (v) {
                  if (_mode != _AuthPanelMode.login) return null;
                  if (v == null || v.isEmpty) {
                    return "Bu alan gerekli";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Şifre",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "••••••••",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (v) {
                  if (_mode != _AuthPanelMode.login) return null;
                  if (v == null || v.isEmpty) {
                    return "Şifre gerekli";
                  }
                  return null;
                },
              ),
            ] else ...[
              const Text(
                "Klinik Adı (Zorunlu)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clinicNameCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.business_outlined),
                  hintText: "Örn: Hayat Veteriner",
                ),
                validator: (v) {
                  if (_mode != _AuthPanelMode.register) return null;
                  if (v == null || v.trim().isEmpty)
                    return "Klinik adı zorunlu";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: "Ad (zorunlu)",
                      ),
                      validator: (v) {
                        if (_mode != _AuthPanelMode.register) return null;
                        if (v == null || v.trim().isEmpty) return "Ad zorunlu";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: "Soyad (zorunlu)",
                      ),
                      validator: (v) {
                        if (_mode != _AuthPanelMode.register) return null;
                        if (v == null || v.trim().isEmpty)
                          return "Soyad zorunlu";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Telefon (Zorunlu)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _registerPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: "05321234555",
                ),
                validator: (v) {
                  if (_mode != _AuthPanelMode.register) return null;
                  if (v == null || v.trim().isEmpty) return "Telefon zorunlu";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "Şifre (Zorunlu)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _registerPasswordCtrl,
                obscureText: _obscureRegisterPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "En az 8 karakter, harf + rakam",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRegisterPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureRegisterPassword =
                                !_obscureRegisterPassword,
                      );
                    },
                  ),
                ),
                validator: (v) {
                  if (_mode != _AuthPanelMode.register) return null;
                  if (v == null || v.isEmpty) return "Şifre zorunlu";
                  if (v.length < 8) return "Şifre en az 8 karakter olmalı";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registerConfirmPasswordCtrl,
                obscureText: _obscureRegisterConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Şifre tekrar (zorunlu)",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRegisterConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureRegisterConfirmPassword =
                                !_obscureRegisterConfirmPassword,
                      );
                    },
                  ),
                ),
                validator: (v) {
                  if (_mode != _AuthPanelMode.register) return null;
                  if (v == null || v.isEmpty) return "Şifre tekrar zorunlu";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "E-posta (Opsiyonel)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _registerEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: "ornek@mail.com",
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : (_mode == _AuthPanelMode.login
                          ? _handleLogin
                          : _handleRegister),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _mode == _AuthPanelMode.login
                            ? "Giriş Yap"
                            : "Kaydı Tamamla",
                      ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _handleFreeTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.rocket_launch_outlined),
              label:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text("Ücretsiz Deneyin"),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AuthPanelMode { login, register }
