import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isArabic = state.language == 'ar';
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              isArabic ? 'الملف الشخصي' : 'Profile',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            children: [
              const SizedBox(height: 16),
              _SettingsSection(
                title: isArabic ? 'المظهر' : 'Appearance',
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: isArabic ? 'المظهر' : 'Theme',
                    trailing: Text(
                      state.themeMode == 'system' 
                        ? (isArabic ? 'تلقائي' : 'System Default')
                        : state.themeMode == 'dark'
                          ? (isArabic ? 'داكن' : 'Dark')
                          : (isArabic ? 'فاتح' : 'Light'),
                    ),
                    onTap: () => _showThemeDialog(context, state),
                  ),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: isArabic ? 'اللغة' : 'Language',
                    trailing: Text(isArabic ? 'العربية' : 'English'),
                    onTap: () => _showLanguageDialog(context, state),
                  ),
                ],
              ),
              _SettingsSection(
                title: isArabic ? 'التفضيلات' : 'Preferences',
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_none_outlined,
                    title: isArabic ? 'الإشعارات' : 'Notifications',
                    onTap: () {},
                  ),
                ],
              ),
              _SettingsSection(
                title: isArabic ? 'الدعم' : 'Support',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: isArabic ? 'عن GoalHub' : 'About GoalHub',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'GoalHub v1.0.0',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, SettingsState state) {
    final isArabic = state.language == 'ar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'اختر المظهر' : 'Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(isArabic ? 'فاتح' : 'Light'),
              value: 'light',
              groupValue: state.themeMode,
              onChanged: (val) {
                context.read<SettingsCubit>().updateThemeMode(val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text(isArabic ? 'داكن' : 'Dark'),
              value: 'dark',
              groupValue: state.themeMode,
              onChanged: (val) {
                context.read<SettingsCubit>().updateThemeMode(val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text(isArabic ? 'تلقائي' : 'System Default'),
              value: 'system',
              groupValue: state.themeMode,
              onChanged: (val) {
                context.read<SettingsCubit>().updateThemeMode(val!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsState state) {
    final isArabic = state.language == 'ar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'اختر اللغة' : 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: state.language,
              onChanged: (val) {
                context.read<SettingsCubit>().updateLanguage(val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: state.language,
              onChanged: (val) {
                context.read<SettingsCubit>().updateLanguage(val!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
