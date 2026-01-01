import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/screens/settings/appearance_settings_page.dart';
import 'package:spotiflac_android/screens/settings/download_settings_page.dart';
import 'package:spotiflac_android/screens/settings/options_settings_page.dart';
import 'package:spotiflac_android/screens/settings/about_page.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Collapsing App Bar - Simplified for performance
        SliverAppBar(
          expandedHeight: 100,
          collapsedHeight: kToolbarHeight,
          floating: false,
          pinned: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            expandedTitleScale: 1.4,
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // Menu items
        SliverList(delegate: SliverChildListDelegate([
          _SettingsMenuItem(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme, colors, display',
            onTap: () => _navigateTo(context, const AppearanceSettingsPage()),
          ),
          _SettingsMenuItem(
            icon: Icons.download_outlined,
            title: 'Download',
            subtitle: 'Service, quality, filename format',
            onTap: () => _navigateTo(context, const DownloadSettingsPage()),
          ),
          _SettingsMenuItem(
            icon: Icons.tune_outlined,
            title: 'Options',
            subtitle: 'Fallback, lyrics, cover art, updates',
            onTap: () => _navigateTo(context, const OptionsSettingsPage()),
          ),
          _SettingsMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version ${AppInfo.version}, credits, GitHub',
            onTap: () => _navigateTo(context, const AboutPage()),
          ),
        ])),
        
        // Fill remaining space to enable scroll
        const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsMenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ])),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 24),
        ]),
      ),
    );
  }
}
