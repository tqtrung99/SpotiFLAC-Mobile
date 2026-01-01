import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';

class QueueTab extends ConsumerWidget {
  const QueueTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(downloadQueueProvider);
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
              'Downloads',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // Pause/Resume controls when downloading
        if (queueState.isProcessing || queueState.queuedCount > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Status icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: queueState.isPaused 
                              ? colorScheme.errorContainer 
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          queueState.isPaused ? Icons.pause : Icons.downloading,
                          color: queueState.isPaused 
                              ? colorScheme.onErrorContainer 
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              queueState.isPaused ? 'Queue Paused' : 'Downloading...',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${queueState.completedCount}/${queueState.items.length} completed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pause/Resume button
                      FilledButton.tonal(
                        onPressed: () => ref.read(downloadQueueProvider.notifier).togglePause(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(queueState.isPaused ? Icons.play_arrow : Icons.pause, size: 20),
                            const SizedBox(width: 4),
                            Text(queueState.isPaused ? 'Resume' : 'Pause'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Header with actions
        if (queueState.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${queueState.items.length} items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  Row(children: [
                    TextButton.icon(
                      onPressed: () => ref.read(downloadQueueProvider.notifier).clearCompleted(),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Clear done'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showClearAllDialog(context, ref),
                      icon: Icon(Icons.clear_all, size: 18, color: colorScheme.error),
                      label: Text('Clear all', style: TextStyle(color: colorScheme.error)),
                    ),
                  ]),
                ],
              ),
            ),
          ),

        // Queue list
        if (queueState.items.isNotEmpty)
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildQueueItem(context, ref, queueState.items[index], colorScheme),
            childCount: queueState.items.length,
          )),

        // Empty state or fill remaining for scroll
        if (queueState.items.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(context, colorScheme))
        else
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.queue_music, size: 64, color: colorScheme.onSurfaceVariant),
      const SizedBox(height: 16),
      Text('No downloads in queue', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Text('Add tracks from the Home tab', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
    ]),
  );

  Widget _buildQueueItem(BuildContext context, WidgetRef ref, DownloadItem item, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Cover art
            item.track.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.track.coverUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      memCacheWidth: 112,
                      memCacheHeight: 112,
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
                  ),
            const SizedBox(width: 12),
            
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.track.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.status == DownloadStatus.downloading) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress > 0 ? item.progress : null,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: colorScheme.primary,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(item.progress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.status == DownloadStatus.failed) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.error ?? 'Download failed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Action buttons based on status
            _buildActionButtons(context, ref, item, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, DownloadItem item, ColorScheme colorScheme) {
    switch (item.status) {
      case DownloadStatus.queued:
        // Queued: Show play (start) and cancel buttons
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel button
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).cancelItem(item.id),
              icon: Icon(Icons.close, color: colorScheme.error),
              tooltip: 'Cancel',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
        
      case DownloadStatus.downloading:
        // Downloading: Show progress indicator and cancel button
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel button (skip this download)
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).cancelItem(item.id),
              icon: Icon(Icons.stop, color: colorScheme.error),
              tooltip: 'Stop',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
        
      case DownloadStatus.completed:
        // Completed: Show check icon
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: colorScheme.onPrimaryContainer, size: 20),
        );
        
      case DownloadStatus.failed:
        // Failed: Show retry and remove buttons
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).retryItem(item.id),
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              tooltip: 'Retry',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).removeItem(item.id),
              icon: Icon(Icons.close, color: colorScheme.error),
              tooltip: 'Remove',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
        
      case DownloadStatus.skipped:
        // Skipped: Show retry and remove buttons
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).retryItem(item.id),
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              tooltip: 'Retry',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).removeItem(item.id),
              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              tooltip: 'Remove',
            ),
          ],
        );
    }
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Clear All'),
      content: const Text('Are you sure you want to clear all downloads?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { ref.read(downloadQueueProvider.notifier).clearAll(); Navigator.pop(context); },
          child: Text('Clear', style: TextStyle(color: colorScheme.error))),
      ],
    ));
  }
}
