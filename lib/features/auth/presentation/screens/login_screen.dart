import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG kullanacağız
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/shared/layouts/main_layout.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/login_state_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fenotip Motorunu Çalıştırıyoruz
    return const Scaffold(
      body: ResponsiveLayout(
        mobile: _LoginMobileView(),
        desktop: _LoginDesktopView(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FENOTİP 1: MOBİL GÖRÜNÜM (Sade ve Odaklı)
// -----------------------------------------------------------------------------
class _LoginMobileView extends StatelessWidget {
  const _LoginMobileView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LogoAndTitle(), // Ortak Logo Parçası
              const SizedBox(height: 40),
              const _LoginForm(), // Ortak Form Parçası
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        "Biçer Teknoloji © 2025",
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FENOTİP 2: DESKTOP GÖRÜNÜM (Split Screen - Henry Tarzı)
// -----------------------------------------------------------------------------
class _LoginDesktopView extends StatelessWidget {
  const _LoginDesktopView();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // SOL TARAFA: Marka Görseli (Buraya Henry'nin klası gelecek)
        Expanded(
          flex: 1, // Ekranın yarısı (veya oranı)
          child: Container(
            color: AppColors.primary,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // İleride buraya gerçek bir resim koyacağız
                // Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
                Container(color: AppColors.primary.withOpacity(0.9)), // Overlay
                const Center(
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
              ],
            ),
          ),
        ),
        // SAĞ TARAF: Giriş Formu
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                ), // Form çok yayılmasın
                child: const Padding(
                  padding: EdgeInsets.all(48.0),
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

// -----------------------------------------------------------------------------
// ORTAK PARÇALAR (GENOTİP)
// Hem Mobilde hem Desktopta kullanılan yapıtaşları
// -----------------------------------------------------------------------------

class _LogoAndTitle extends StatelessWidget {
  final bool isDesktop;
  const _LogoAndTitle({this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Geçici İkon (Logo yerine)
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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Hesabınıza giriş yaparak devam edin.",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _LoginForm extends ConsumerWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPasswordVisible = ref.watch(passwordVisibilityProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Input
        const Text(
          "Kullanıcı Adı",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(
            hintText: "kullanici_adi",
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),

        // Password Input
        const Text("Şifre", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: isPasswordVisible,
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                ref.read(passwordVisibilityProvider.notifier).state =
                    !isPasswordVisible;
              },
            ),
          ),
        ),

        // Şifremi Unuttum
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text("Şifremi Unuttum?"),
          ),
        ),
        const SizedBox(height: 24),

        // Giriş Butonu
        ElevatedButton(
          onPressed:
              isLoading
                  ? null
                  : () {
                    // Loading Simülasyonu
                    // Input değerlerini almak için Controller kullanmak daha doğru ama
                    // şimdilik hızlıca test etmek için hardcode veya basit controller kullanabilirsin.
                    // Profesyonel yöntem: TextEditingController tanımlamak.

                    // NOT: Bu örnekte inputları bağlamadığımız için
                    // gerçek projede TextEditingController eklemelisin.
                    // Şimdilik test için manuel string gönderiyoruz:

                    ref
                        .read(authControllerProvider)
                        .login(
                          username:
                              "vet_ahmet", // Buraya textController.text gelecek
                          password:
                              "sifre123", // Buraya passwordController.text gelecek
                          onSuccess: () {
                            // Dashboard'a Işınlan 🚀
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const MainLayout(),
                              ),
                            );
                          },
                          onError: (msg) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        );
                  },
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
    );
  }
}
