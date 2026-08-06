import 'package:flutter/material.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

void main() => runApp(const ExampleApp());

/// Demonstration application for all supported media types.
final class ExampleApp extends StatelessWidget {
  /// Creates the media player example app.
  const ExampleApp({this.home, super.key});

  /// Optional home override for tests and embedding.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixup Media Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: home ?? const PlayerExampleScreen(),
    );
  }
}

enum _ExampleMediaType { video, audio, youtube }

/// Screen for selecting a media type and entering its URL.
final class PlayerExampleScreen extends StatefulWidget {
  /// Creates the interactive example screen.
  const PlayerExampleScreen({super.key});

  @override
  State<PlayerExampleScreen> createState() => _PlayerExampleScreenState();
}

final class _PlayerExampleScreenState extends State<PlayerExampleScreen> {
  static final Map<_ExampleMediaType, String> _sampleUrls = {
    _ExampleMediaType.video:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    _ExampleMediaType.audio:
        'https://flutter.github.io/assets-for-api-docs/assets/audio/rooster.mp3',
    _ExampleMediaType.youtube: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
  };

  _ExampleMediaType _type = _ExampleMediaType.video;
  late final TextEditingController _urlController;
  late final MixupMediaController _mixupMediaController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _sampleUrls[_type]);
    _mixupMediaController = MixupMediaController(source: _sourceFromInput());
  }

  MediaSource _sourceFromInput() {
    final url = Uri.parse(_urlController.text.trim());
    return switch (_type) {
      _ExampleMediaType.video => VideoMediaSource(data: NetworkVideoData(url)),
      _ExampleMediaType.audio => AudioMediaSource(data: NetworkAudioData(url)),
      _ExampleMediaType.youtube => YouTubeMediaSource(url: url),
    };
  }

  Future<void> _changeType(_ExampleMediaType? type) async {
    if (type == null) return;
    setState(() {
      _type = type;
      _urlController.text = _sampleUrls[type]!;
    });
    await _load();
  }

  Future<void> _load() async {
    final uri = Uri.tryParse(_urlController.text.trim());
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('有効な URL を入力してください。')),
      );
      return;
    }
    try {
      await _mixupMediaController.setSource(_sourceFromInput());
    } on MediaPlayerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  void dispose() {
    _mixupMediaController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mixup Media Player Example')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<_ExampleMediaType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'メディア種別'),
            items: const [
              DropdownMenuItem(
                value: _ExampleMediaType.video,
                child: Text('動画'),
              ),
              DropdownMenuItem(
                value: _ExampleMediaType.audio,
                child: Text('音声'),
              ),
              DropdownMenuItem(
                value: _ExampleMediaType.youtube,
                child: Text('YouTube'),
              ),
            ],
            onChanged: (value) => _changeType(value).ignore(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'URL',
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _load().ignore(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _load().ignore(),
            child: const Text('読み込む'),
          ),
          const SizedBox(height: 24),
          MixupMediaViewer(
            controller: _mixupMediaController,
            labels: const MixupMediaViewerLabels(
              loading: 'メディアを読み込んでいます',
              retry: '再試行',
              play: '再生',
              pause: '一時停止',
              stop: '停止',
              rewind: '10秒戻る',
              forward: '10秒進む',
            ),
          ),
        ],
      ),
    );
  }
}
