import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/login_controller.dart';

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
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 420),
                child: Padding(
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

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _identifierCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
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

    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              if (v == null || v.isEmpty) {
                return "Bu alan gerekli";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text("Şifre", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: "••••••••",
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Şifre gerekli";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
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
                    : const Text("Giriş Yap"),
          ),
        ],
      ),
    );
  }
}
