import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/theme/app_colors.dart";
import "../providers/login_controller.dart";
import "../providers/auth_controller.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

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
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Giriş başarılı!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        error: (error, st) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Giriş hatası: $error"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        loading: () {},
      );
    });

    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                "Veteriner Kliniği Yönetim Sistemi",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _identifierCtrl,
                decoration: InputDecoration(
                  labelText: "E-posta veya Telefon",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "E-posta veya telefon gerekli";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Şifre gerekli";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Forgot password screen
                  },
                  child: const Text("Şifremi Unuttum?"),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                          : const Text(
                            "GİRİŞ YAP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hesabınız yok mu? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/auth/register");
                    },
                    child: const Text("Kaydol"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
