import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart' hide AudioData;

import 'package:mixup_media_player/src/model/media_source.dart';
import 'package:mixup_media_player/src/model/media_state.dart';
import 'package:mixup_media_player/src/player/media_player_backend.dart';

@internal
final class AudioPlayerBackend implements MediaPlayerBackend {
  AudioPlayerBackend(this.data, this.onChanged);

  final AudioData data;
  final PlaybackChanged onChanged;
  final SoLoud _player = SoLoud.instance;
  AudioSource? _source;
  SoundHandle? _handle;
  Timer? _timer;
  MediaPlaybackStatus _status = MediaPlaybackStatus.stopped;
  bool _disposed = false;

  @override
  Future<void> initialize() async {
    if (!_player.isInitialized) await _player.init();
    final source = switch (data) {
      NetworkAudioData(:final url) => await _player.loadUrl(url.toString()),
      AssetAudioData(:final asset) => await _player.loadAsset(asset),
    };
    if (_disposed) {
      await _player.disposeSource(source);
      return;
    }
    _source = source;
    _timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _notify(),
    );
    _notify();
  }

  void _notify() {
    final source = _source;
    final handle = _handle;
    if (source == null) return;
    var position = Duration.zero;
    if (handle != null && _player.getIsValidVoiceHandle(handle)) {
      position = _player.getPosition(handle);
    } else if (_status == MediaPlaybackStatus.playing) {
      _status = MediaPlaybackStatus.completed;
      position = _player.getLength(source);
    }
    onChanged(
      PlaybackSnapshot(
        status: _status,
        position: position,
        duration: _player.getLength(source),
      ),
    );
  }

  @override
  Future<void> play() async {
    final source = _source!;
    final handle = _handle;
    if (handle != null && _player.getIsValidVoiceHandle(handle)) {
      _player.setPause(handle, false);
    } else {
      _handle = _player.play(source);
    }
    _status = MediaPlaybackStatus.playing;
    _notify();
  }

  @override
  Future<void> pause() async {
    final handle = _handle;
    if (handle != null && _player.getIsValidVoiceHandle(handle)) {
      _player.setPause(handle, true);
    }
    _status = MediaPlaybackStatus.paused;
    _notify();
  }

  @override
  Future<void> stop() async {
    final handle = _handle;
    if (handle != null) await _player.stop(handle);
    _handle = null;
    _status = MediaPlaybackStatus.stopped;
    _notify();
  }

  @override
  Future<void> seek(Duration position) async {
    var handle = _handle;
    if (handle == null || !_player.getIsValidVoiceHandle(handle)) {
      handle = _player.play(_source!, paused: true);
      _handle = handle;
      _status = MediaPlaybackStatus.paused;
    }
    _player.seek(handle, position);
    _notify();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    final handle = _handle;
    if (handle != null) await _player.stop(handle);
    final source = _source;
    if (source != null && _player.isInitialized) {
      await _player.disposeSource(source);
    }
  }
}
