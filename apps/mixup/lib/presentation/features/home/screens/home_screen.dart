import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixup/presentation/features/home/controllers/home_content_provider.dart';

/// The temporary home screen displaying repository content for debugging.
class HomeScreen extends ConsumerWidget {
  /// Creates the temporary home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(homeContentProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Mixup repository debug'),
      ),
      body: content.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText('読み込みに失敗しました\n$error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(homeContentProvider),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '楽曲 (${data.songs.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final song in data.songs)
              ListTile(
                title: Text(song.title),
                subtitle: Text(song.sourcePath),
                onTap: () => context.go(
                  '/songs/${song.sourcePath.split('/').first}/timing',
                ),
              ),
            const Divider(),
            Text(
              'MIX (${data.mixes.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final mix in data.mixes)
              ListTile(
                title: Text(mix.title),
                subtitle: Text('${mix.bars}小節 · ${mix.call}'),
              ),
          ],
        ),
      ),
    );
  }
}
