import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/settings/presentation/providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _branchIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _userPasswordController = TextEditingController();
  String _selectedRole = 'STAFF';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _branchIdController.text = user?.branchId ?? '';
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _branchIdController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = (authState.user?.role.toUpperCase() ?? '') == 'ADMIN';

    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1000;
              if (!isDesktop) {
                return _buildMobileLayout(context, state, controller, isAdmin);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: _SettingsMenu(
                      selected: state.selectedMenu,
                      isAdmin: isAdmin,
                      onSelect: (item) => _handleMenuSelect(item, controller),
                    ),
                  ),
                  const VerticalDivider(width: 24, thickness: 1),
                  Expanded(
                    child: _SettingsContent(
                      state: state,
                      isAdmin: isAdmin,
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                      branchIdController: _branchIdController,
                      fullNameController: _fullNameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      userPasswordController: _userPasswordController,
                      selectedRole: _selectedRole,
                      onRoleChanged:
                          (value) => setState(() => _selectedRole = value),
                      onLogout: () => controller.logout(),
                      onChangePassword: _handlePasswordChange,
                      onCreateUser: _handleCreateUser,
                      onDeactivateUser: (id) => controller.deactivateUser(id),
                      onInflationChanged: controller.setInflationProtection,
                      onBackupChanged: controller.setBackupPeriod,
                      onThemeChanged: controller.setThemePreference,
                      onRefreshUsers: controller.loadUsers,
                      onRefreshSessions: controller.loadSessions,
                      onRevokeSession: controller.revokeSession,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SettingsState state,
    SettingsController controller,
    bool isAdmin,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                SettingsMenuItem.values.map((item) {
                  final disabled = _isAdminOnly(item) && !isAdmin;
                  final selected = state.selectedMenu == item;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_menuTitle(item)),
                      selected: selected,
                      onSelected:
                          disabled
                              ? null
                              : (_) => _handleMenuSelect(item, controller),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _SettingsContent(
            state: state,
            isAdmin: isAdmin,
            currentPasswordController: _currentPasswordController,
            newPasswordController: _newPasswordController,
            confirmPasswordController: _confirmPasswordController,
            branchIdController: _branchIdController,
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            emailController: _emailController,
            userPasswordController: _userPasswordController,
            selectedRole: _selectedRole,
            onRoleChanged: (value) => setState(() => _selectedRole = value),
            onLogout: () => controller.logout(),
            onChangePassword: _handlePasswordChange,
            onCreateUser: _handleCreateUser,
            onDeactivateUser: (id) => controller.deactivateUser(id),
            onInflationChanged: controller.setInflationProtection,
            onBackupChanged: controller.setBackupPeriod,
            onThemeChanged: controller.setThemePreference,
            onRefreshUsers: controller.loadUsers,
            onRefreshSessions: controller.loadSessions,
            onRevokeSession: controller.revokeSession,
          ),
        ),
      ],
    );
  }

  void _handleMenuSelect(SettingsMenuItem item, SettingsController controller) {
    controller.selectMenu(item);
    if (item == SettingsMenuItem.userCreate ||
        item == SettingsMenuItem.userFreeze) {
      controller.loadUsers();
    }
    if (item == SettingsMenuItem.userHistory) {
      controller.loadSessions();
    }
  }

  Future<void> _handlePasswordChange() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lutfen tum sifre alanlarini doldurun.')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni sifre ve tekrar sifresi ayni olmali.'),
        ),
      );
      return;
    }
    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni sifre en az 8 karakter olmali.')),
      );
      return;
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _handleCreateUser() async {
    final branchId = _branchIdController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _userPasswordController.text;

    if (branchId.isEmpty ||
        fullName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lutfen tum alanlari doldurun.')),
      );
      return;
    }

    await ref
        .read(settingsControllerProvider.notifier)
        .createUser(
          branchId: branchId,
          fullName: fullName,
          phone: phone,
          email: email,
          password: password,
          role: _selectedRole,
        );

    _fullNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _userPasswordController.clear();
  }
}

class _SettingsMenu extends StatelessWidget {
  final SettingsMenuItem selected;
  final bool isAdmin;
  final ValueChanged<SettingsMenuItem> onSelect;

  const _SettingsMenu({
    required this.selected,
    required this.isAdmin,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const ListTile(
            title: Text(
              'Ayarlar Menüsü',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            subtitle: Text('Klinik yönetimi ve güvenlik ayarları'),
          ),
          const Divider(),
          ...SettingsMenuItem.values.map((item) {
            final isLocked = _isAdminOnly(item) && !isAdmin;
            return ListTile(
              leading: Icon(_menuIcon(item)),
              title: Text(_menuTitle(item)),
              subtitle: Text(_menuSubtitle(item)),
              trailing:
                  isLocked ? const Icon(Icons.lock_outline, size: 18) : null,
              selected: selected == item,
              selectedTileColor: AppColors.primary.withOpacity(0.08),
              onTap: isLocked ? null : () => onSelect(item),
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final SettingsState state;
  final bool isAdmin;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController branchIdController;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController userPasswordController;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onLogout;
  final VoidCallback onChangePassword;
  final VoidCallback onCreateUser;
  final ValueChanged<String> onDeactivateUser;
  final ValueChanged<bool> onInflationChanged;
  final ValueChanged<BackupPeriodOption> onBackupChanged;
  final ValueChanged<ThemePreference> onThemeChanged;
  final VoidCallback onRefreshUsers;
  final VoidCallback onRefreshSessions;
  final ValueChanged<String> onRevokeSession;

  const _SettingsContent({
    required this.state,
    required this.isAdmin,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.branchIdController,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.userPasswordController,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onLogout,
    required this.onChangePassword,
    required this.onCreateUser,
    required this.onDeactivateUser,
    required this.onInflationChanged,
    required this.onBackupChanged,
    required this.onThemeChanged,
    required this.onRefreshUsers,
    required this.onRefreshSessions,
    required this.onRevokeSession,
  });

  @override
  Widget build(BuildContext context) {
    final loadingOverlay =
        state.isBusy
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox.shrink();

    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildPanel(context),
            ),
          ),
          loadingOverlay,
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    switch (state.selectedMenu) {
      case SettingsMenuItem.account:
        return _infoPanel(
          title: 'Hesap Özeti',
          icon: Icons.account_circle_outlined,
          text:
              'Buradan klinik hesabınızla ilgili temel güvenlik ayarlarına erişebilirsiniz. Şifre değiştirme ve aktif oturum yönetimi ile yetkisiz kullanım riskini azaltırınız.',
        );
      case SettingsMenuItem.password:
        return SingleChildScrollView(
          child: Column(
            key: const ValueKey('password'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _panelHeader('Şifre Değiştir', Icons.password_outlined),
              const SizedBox(height: 12),
              const Text(
                'Güvenlik için mevcut şifrenizi girerek yeni şifre belirleyin. Klinik verilerini korumak adına güçlü bir şifre tercih edin.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onChangePassword,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Şifreyi Güncelle'),
              ),
            ],
          ),
        );
      case SettingsMenuItem.inflationProtection:
        return Column(
          key: const ValueKey('inflation'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader('Enflasyon Koruma Ayarları', Icons.trending_up),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enflasyon Koruma Aktif Olsun'),
              subtitle: Text(
                state.inflationProtectionEnabled
                    ? 'Aktif: Ürün satış fiyatı artışında açık borçlar da yeni fiyat politikasına göre güncellenir.'
                    : 'Pasif: Açık borçlar satıldığı andaki tutar ile sabit kalır.',
              ),
              value: state.inflationProtectionEnabled,
              onChanged: onInflationChanged,
            ),
            const SizedBox(height: 10),
            const Text(
              'Veteriner kliniklerinde uzun vadeli vadeli satışlarda maliyet artışları sıktır. Bu ayar açık olduğunda, borçlu müşterinin kalan borcu ürünün güncel fiyatıyla uyumlu hale gelir. Kapalı olduğunda hasta sahibi açısından borç daha öngörülebilir kalır.',
            ),
          ],
        );
      case SettingsMenuItem.userCreate:
        if (!isAdmin) return _adminOnlyPanel();
        return SingleChildScrollView(
          child: Column(
            key: const ValueKey('create-user'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _panelHeader(
                'Kullanıcı Hesabı Oluştur (Admin)',
                Icons.person_add_alt_1,
              ),
              const SizedBox(height: 12),
              const Text(
                'Yeni klinik personeli ekleyin. Oluşturulan kullanıcılar ilk girişte şifre değiştirme zorunluluğu ile açılır.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: branchIdController,
                decoration: const InputDecoration(labelText: 'Şube ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: userPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Geçici Şifre'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                ],
                onChanged: (value) {
                  if (value != null) onRoleChanged(value);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreateUser,
                icon: const Icon(Icons.add),
                label: const Text('Kullanıcı Oluştur'),
              ),
            ],
          ),
        );
      case SettingsMenuItem.userFreeze:
        if (!isAdmin) return _adminOnlyPanel();
        return Column(
          key: const ValueKey('freeze-user'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader(
              'Klinik Kullanıcısı Dondurma',
              Icons.person_off_outlined,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefreshUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Listeyi yenile'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Dondurulan kullanıcı sisteme giriş yapamaz. Klinikten ayrılan personel için güvenli bir kapatma yöntemidir.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  state.users.isEmpty
                      ? const Center(
                        child: Text('Gösterilecek kullanıcı bulunamadı.'),
                      )
                      : ListView.separated(
                        itemCount: state.users.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(user.fullName),
                            subtitle: Text('${user.email} • ${user.role}'),
                            trailing:
                                user.isActive
                                    ? TextButton(
                                      onPressed:
                                          () => onDeactivateUser(user.id),
                                      child: const Text('Dondurma'),
                                    )
                                    : const Chip(
                                      label: Text('Pasif (Kapalı)'),
                                      backgroundColor: Color(0xFFFFE0E0),
                                    ),
                          );
                        },
                      ),
            ),
          ],
        );
      case SettingsMenuItem.backupPeriod:
        return Column(
          key: const ValueKey('backup'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader('Yedekleme Raporu Periyodu', Icons.backup_outlined),
            const SizedBox(height: 12),
            const Text(
              'Yedekleme periyodu seçildiğinde sistem yönetim panelinde raporlama sıklığı bu seçime göre hizalanır.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BackupPeriodOption>(
              value: state.backupPeriod,
              decoration: const InputDecoration(labelText: 'Periyot'),
              items:
                  BackupPeriodOption.values.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(_backupTitle(period)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) onBackupChanged(value);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Not: Bu seçim şimdi yerel olarak saklanır. Sunucu tarafı zamanlayıcı altyapısı hazır olduğunda otomatik yedekleme tetikleri bu ayara bağlanacaktır.',
            ),
          ],
        );
      case SettingsMenuItem.userHistory:
        return Column(
          key: const ValueKey('history'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader('Kullanıcı İşlemleri Geçmişi', Icons.history_outlined),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefreshSessions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Oturumları Yenile'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Audit log endpointi açıldığında kullanıcı bazlı tüm hareketler burada listelenecek. Şimdilik aktif cihaz oturumlarını görüp sonlandırabilirsiniz.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  state.sessions.isEmpty
                      ? const Center(child: Text('Aktif oturum bulunamadi.'))
                      : ListView.separated(
                        itemCount: state.sessions.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final session = state.sessions[index];
                          return ListTile(
                            leading: const Icon(Icons.devices_other_outlined),
                            title: Text(
                              session.deviceName.isEmpty
                                  ? 'Bilinmeyen cihaz'
                                  : session.deviceName,
                            ),
                            subtitle: Text(
                              '${session.ipAddress} • Son kullanım: ${session.lastUsedAt}',
                            ),
                            trailing: TextButton(
                              onPressed: () => onRevokeSession(session.id),
                              child: const Text('Sonlandırma'),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
      case SettingsMenuItem.themeMode:
        return Column(
          key: const ValueKey('theme'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader('Uygulama Tema Modu', Icons.palette_outlined),
            const SizedBox(height: 12),
            const Text(
              'Tema seçimi şimdi menüyü zenginleştiren bir ayarıdır. UI altyapısı tamamlandığında tüm uygulamaya anında uygulanacaktır.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<ThemePreference>(
              segments: const [
                ButtonSegment(
                  value: ThemePreference.system,
                  label: Text('Sistem'),
                  icon: Icon(Icons.devices),
                ),
                ButtonSegment(
                  value: ThemePreference.light,
                  label: Text('Açık'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemePreference.dark,
                  label: Text('Koyu'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {state.themePreference},
              onSelectionChanged: (values) => onThemeChanged(values.first),
            ),
          ],
        );
      case SettingsMenuItem.logout:
        return Column(
          key: const ValueKey('logout'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader('Çıkış Yap', Icons.logout),
            const SizedBox(height: 12),
            const Text(
              'Bu cihazdaki oturum kapatılır. Tekrar erişim için giriş bilgileri gerekir.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              icon: const Icon(Icons.logout),
              label: const Text('Güvenli Çıkış Yap'),
            ),
          ],
        );
    }
  }

  Widget _panelHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _infoPanel({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader(title, icon),
        const SizedBox(height: 14),
        Text(text),
      ],
    );
  }

  Widget _adminOnlyPanel() {
    return _infoPanel(
      title: 'Yetki Gerekiyor',
      icon: Icons.admin_panel_settings_outlined,
      text:
          'Bu ayar sadece ADMIN rolünde olan kullanıcılara açıktır. Klinik güvenliği için personel yönetimi ekranları kısıtlanmıştır.',
    );
  }
}

bool _isAdminOnly(SettingsMenuItem item) {
  return item == SettingsMenuItem.userCreate ||
      item == SettingsMenuItem.userFreeze;
}

String _menuTitle(SettingsMenuItem item) {
  switch (item) {
    case SettingsMenuItem.account:
      return 'Hesap';
    case SettingsMenuItem.password:
      return 'Şifre';
    case SettingsMenuItem.inflationProtection:
      return 'Enflasyon Koruma';
    case SettingsMenuItem.userCreate:
      return 'Kullanıcı Oluştur';
    case SettingsMenuItem.userFreeze:
      return 'Kullanıcı Dondur';
    case SettingsMenuItem.backupPeriod:
      return 'Yedekleme';
    case SettingsMenuItem.userHistory:
      return 'İşlem Geçmişi';
    case SettingsMenuItem.themeMode:
      return 'Tema';
    case SettingsMenuItem.logout:
      return 'Çıkış';
  }
}

String _menuSubtitle(SettingsMenuItem item) {
  switch (item) {
    case SettingsMenuItem.account:
      return 'Temel hesap bilgileri';
    case SettingsMenuItem.password:
      return 'Şifre değiştirme';
    case SettingsMenuItem.inflationProtection:
      return 'Borc güncelleme davranışı';
    case SettingsMenuItem.userCreate:
      return 'Admin personel kaydı';
    case SettingsMenuItem.userFreeze:
      return 'Kullanıcı pasife alma';
    case SettingsMenuItem.backupPeriod:
      return 'Raporlama periyodu';
    case SettingsMenuItem.userHistory:
      return 'Oturum ve hareket takibi';
    case SettingsMenuItem.themeMode:
      return 'Sistem/açık/koyu';
    case SettingsMenuItem.logout:
      return 'Güvenli çıkış';
  }
}

IconData _menuIcon(SettingsMenuItem item) {
  switch (item) {
    case SettingsMenuItem.account:
      return Icons.account_circle_outlined;
    case SettingsMenuItem.password:
      return Icons.password_outlined;
    case SettingsMenuItem.inflationProtection:
      return Icons.trending_up_outlined;
    case SettingsMenuItem.userCreate:
      return Icons.person_add_alt_1_outlined;
    case SettingsMenuItem.userFreeze:
      return Icons.person_off_outlined;
    case SettingsMenuItem.backupPeriod:
      return Icons.backup_outlined;
    case SettingsMenuItem.userHistory:
      return Icons.history_outlined;
    case SettingsMenuItem.themeMode:
      return Icons.palette_outlined;
    case SettingsMenuItem.logout:
      return Icons.logout_outlined;
  }
}

String _backupTitle(BackupPeriodOption option) {
  switch (option) {
    case BackupPeriodOption.daily:
      return 'Günlük';
    case BackupPeriodOption.every3Days:
      return '3 günlük';
    case BackupPeriodOption.weekly:
      return 'Haftalık';
    case BackupPeriodOption.monthly:
      return 'Aylık';
  }
}
