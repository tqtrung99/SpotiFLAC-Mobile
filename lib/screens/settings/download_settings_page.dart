import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

class DownloadSettingsPage extends ConsumerWidget {
  const DownloadSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing App Bar with back button
          SliverAppBar(
            expandedHeight: 120 + topPadding,
            collapsedHeight: kToolbarHeight,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120 + topPadding;
                final minHeight = kToolbarHeight + topPadding;
                final expandRatio = ((constraints.maxHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
                final animation = AlwaysStoppedAnimation(expandRatio);
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.zero,
                  title: SafeArea(
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.only(
                        left: Tween<double>(begin: 56, end: 24).evaluate(animation),
                        bottom: Tween<double>(begin: 12, end: 16).evaluate(animation),
                      ),
                      child: Text('Download',
                        style: TextStyle(
                          fontSize: Tween<double>(begin: 20, end: 28).evaluate(animation),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Service section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Service')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ServiceSelector(
                currentService: settings.defaultService,
                onChanged: (service) => ref.read(settingsProvider.notifier).setDefaultService(service),
              ),
            ),
          ),

          // Quality section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Audio Quality')),
          SliverList(delegate: SliverChildListDelegate([
            _QualityOption(title: 'FLAC Lossless', subtitle: '16-bit / 44.1kHz', value: 'LOSSLESS',
              isSelected: settings.audioQuality == 'LOSSLESS',
              onTap: () => ref.read(settingsProvider.notifier).setAudioQuality('LOSSLESS')),
            _QualityOption(title: 'Hi-Res FLAC', subtitle: '24-bit / up to 96kHz', value: 'HI_RES',
              isSelected: settings.audioQuality == 'HI_RES',
              onTap: () => ref.read(settingsProvider.notifier).setAudioQuality('HI_RES')),
            _QualityOption(title: 'Hi-Res FLAC Max', subtitle: '24-bit / up to 192kHz', value: 'HI_RES_LOSSLESS',
              isSelected: settings.audioQuality == 'HI_RES_LOSSLESS',
              onTap: () => ref.read(settingsProvider.notifier).setAudioQuality('HI_RES_LOSSLESS')),
          ])),

          // File settings section
          SliverToBoxAdapter(child: _SectionHeader(title: 'File Settings')),
          SliverList(delegate: SliverChildListDelegate([
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.text_fields, color: colorScheme.onSurfaceVariant),
              title: const Text('Filename Format'),
              subtitle: Text(settings.filenameFormat),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showFormatEditor(context, ref, settings.filenameFormat),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.folder_outlined, color: colorScheme.onSurfaceVariant),
              title: const Text('Download Directory'),
              subtitle: Text(settings.downloadDirectory.isEmpty ? 'Music/SpotiFLAC' : settings.downloadDirectory, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickDirectory(ref),
            ),
          ])),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showFormatEditor(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filename Format', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: controller, decoration: const InputDecoration(hintText: '{artist} - {title}'), autofocus: true),
          const SizedBox(height: 16),
          Text('Available: {title}, {artist}, {album}, {track}, {year}, {disc}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton(onPressed: () { ref.read(settingsProvider.notifier).setFilenameFormat(controller.text); Navigator.pop(context); }, child: const Text('Save')),
          ]),
        ]),
      ),
    );
  }

  Future<void> _pickDirectory(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) ref.read(settingsProvider.notifier).setDownloadDirectory(result);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}

class _ServiceSelector extends StatelessWidget {
  final String currentService;
  final ValueChanged<String> onChanged;
  const _ServiceSelector({required this.currentService, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          _ServiceChip(icon: Icons.music_note, label: 'Tidal', isSelected: currentService == 'tidal', onTap: () => onChanged('tidal')),
          const SizedBox(width: 8),
          _ServiceChip(icon: Icons.album, label: 'Qobuz', isSelected: currentService == 'qobuz', onTap: () => onChanged('qobuz')),
          const SizedBox(width: 8),
          _ServiceChip(icon: Icons.shopping_bag, label: 'Amazon', isSelected: currentService == 'amazon', onTap: () => onChanged('amazon')),
        ]),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ServiceChip({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Icon(icon, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  const _QualityOption({required this.title, required this.subtitle, required this.value, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : Icon(Icons.circle_outlined, color: colorScheme.outline),
      onTap: onTap,
    );
  }
}
