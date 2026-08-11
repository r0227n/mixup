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

@immutable
/// Localizable text used by the example playback controls.
final class _ExamplePlaybackLabels {
  /// Creates customizable, localizable control labels.
  const _ExamplePlaybackLabels({
    this.loading = 'Loading media…',
    this.retry = 'Retry',
    this.play = 'Play',
    this.pause = 'Pause',
    this.stop = 'Stop',
    this.rewind = 'Rewind 10 seconds',
    this.forward = 'Forward 10 seconds',
  });

  /// Loading semantics label.
  final String loading;

  /// Retry button label.
  final String retry;

  /// Play button label.
  final String play;

  /// Pause button label.
  final String pause;

  /// Stop button label.
  final String stop;

  /// Backward skip tooltip.
  final String rewind;

  /// Forward skip tooltip.
  final String forward;
}

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

  static const _labels = _ExamplePlaybackLabels(
    loading: 'メディアを読み込んでいます',
    retry: '再試行',
    play: '再生',
    pause: '一時停止',
    stop: '停止',
    rewind: '10秒戻る',
    forward: '10秒進む',
  );

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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MixupMediaViewer(
                controller: _mixupMediaController,
                loadingLabel: _labels.loading,
              ),
              _PlaybackFooter(
                controller: _mixupMediaController,
                labels: _labels,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Playback controls and error UI owned by the example app.
final class _PlaybackFooter extends StatelessWidget {
  const _PlaybackFooter({required this.controller, required this.labels});

  final MixupMediaController controller;
  final _ExamplePlaybackLabels labels;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        if (state.status == MediaPlaybackStatus.error) {
          return _ErrorView(
            controller: controller,
            state: state,
            labels: labels,
          );
        }

        return _Controls(
          controller: controller,
          state: state,
          labels: labels,
        );
      },
    );
  }
}

final class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.state,
    required this.labels,
  });

  final MixupMediaController controller;
  final MediaState state;
  final _ExamplePlaybackLabels labels;

  @override
  Widget build(BuildContext context) {
    final max = state.duration.inMilliseconds.toDouble();
    final value = state.position.inMilliseconds.clamp(0, max > 0 ? max : 1);

    return Column(
      children: [
        Slider(
          value: value.toDouble(),
          max: max > 0 ? max : 1,
          onChanged: state.isReady
              ? (milliseconds) => controller
                    .seek(Duration(milliseconds: milliseconds.round()))
                    .ignore()
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: labels.rewind,
              onPressed: () =>
                  controller.skipBackward(const Duration(seconds: 10)).ignore(),
              icon: const Icon(Icons.replay_10),
            ),
            IconButton(
              tooltip: state.isPlaying ? labels.pause : labels.play,
              onPressed: () =>
                  (state.isPlaying ? controller.pause() : controller.play())
                      .ignore(),
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: labels.stop,
              onPressed: () => controller.stop().ignore(),
              icon: const Icon(Icons.stop),
            ),
            IconButton(
              tooltip: labels.forward,
              onPressed: () =>
                  controller.skipForward(const Duration(seconds: 10)).ignore(),
              icon: const Icon(Icons.forward_10),
            ),
            Text('${_format(state.position)} / ${_format(state.duration)}'),
          ],
        ),
      ],
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.controller,
    required this.state,
    required this.labels,
  });

  final MixupMediaController controller;
  final MediaState state;
  final _ExamplePlaybackLabels labels;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure!;

    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(failure.message),
          if (failure.recoveryAction == MediaRecoveryAction.retry)
            TextButton(
              onPressed: () => controller.retry().ignore(),
              child: Text(labels.retry),
            ),
        ],
      ),
    );
  }
}
