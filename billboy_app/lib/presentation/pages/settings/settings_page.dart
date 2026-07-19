import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticatedState ? authState.user : null;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile card
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 28),

              _SettingsSection(
                title: 'Appearance',
                items: [
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    label: 'Theme',
                    subtitle: 'System',
                    onTap: () => _showThemeDialog(context),
                  ),
                  _SettingsItem(
                    icon: Icons.table_chart_outlined,
                    label: 'Table Columns',
                    subtitle: 'Customize visible columns',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Notifications',
                items: [
                  _SettingsSwitchItem(
                    icon: Icons.notifications_outlined,
                    label: 'Push Notifications',
                    value: true,
                    onChanged: (v) {},
                  ),
                  _SettingsSwitchItem(
                    icon: Icons.email_outlined,
                    label: 'Email Notifications',
                    value: true,
                    onChanged: (v) {},
                  ),
                  _SettingsSwitchItem(
                    icon: Icons.sms_outlined,
                    label: 'SMS Notifications',
                    value: false,
                    onChanged: (v) {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Depreciation Rules',
                items: [
                  _SettingsItem(
                    icon: Icons.trending_down_rounded,
                    label: 'Manage Depreciation',
                    subtitle: 'Customize rates by category',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Integrations',
                items: [
                  _SettingsItem(
                    icon: Icons.email_outlined,
                    label: 'Connect Gmail',
                    subtitle: 'Auto-detect email bills',
                    trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.sms_outlined,
                    label: 'SMS Detection',
                    subtitle: 'Detect purchase confirmations',
                    trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Security',
                items: [
                  _SettingsItem(
                    icon: Icons.fingerprint_rounded,
                    label: 'Biometric Lock',
                    subtitle: 'Use fingerprint or face ID',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.lock_outlined,
                    label: 'Change Password',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Data',
                items: [
                  _SettingsItem(
                    icon: Icons.download_outlined,
                    label: 'Export All Data',
                    subtitle: 'Download as CSV or PDF',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete All Data',
                    subtitle: 'Permanently delete all bills',
                    labelColor: AppColors.error,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Account',
                items: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    labelColor: AppColors.error,
                    onTap: () => _confirmSignOut(context),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Center(
                child: Text(
                  'BillBoy v1.0.0\nNever lose a bill. Never miss a warranty.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(icon: Icons.wb_sunny_outlined, label: 'Light Mode'),
            _ThemeOption(icon: Icons.nightlight_outlined, label: 'Dark Mode'),
            _ThemeOption(icon: Icons.settings_outlined, label: 'System Default'),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutEvent());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ThemeOption({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.pop(context),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.borderLight
                  : AppColors.borderDark,
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: labelColor ?? AppColors.primary, size: 18),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: labelColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

