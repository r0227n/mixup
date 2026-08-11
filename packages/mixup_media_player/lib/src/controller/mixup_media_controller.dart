import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:mixup_media_player/src/model/media_player_exception.dart';
import 'package:mixup_media_player/src/model/media_source.dart';
import 'package:mixup_media_player/src/model/media_state.dart';
import 'package:mixup_media_player/src/player/audio_player_backend.dart';
import 'package:mixup_media_player/src/player/media_player_backend.dart';
import 'package:mixup_media_player/src/player/video_player_backend.dart';
import 'package:mixup_media_player/src/player/youtube_player_backend.dart';

/// Owns the source, canonical playback state, and all playback operations.
final class MixupMediaController extends ChangeNotifier {
  /// Creates a controller and starts preparing [source].
  MixupMediaController({required MediaSource source}) : _source = source {
    _initialization = _load(source, rethrowError: false);
  }

  MediaSource _source;

  /// Current source and the single source of truth for media type selection.
  MediaSource get source => _source;

  MediaState _state = const MediaState.loading();

  /// Latest canonical playback state.
  MediaState get state => _state;

  late Future<void> _initialization;

  /// Completes after the current source has been prepared.
  ///
  /// Initial construction reports load failures through [state]. A source set
  /// with [setSource] also throws [MediaLoadException] to its caller.
  Future<void> get initialized => _initialization;

  MediaPlayerBackend? _backend;

  /// Current package-internal backend used by the unified viewer.
  @internal
  MediaPlayerBackend? get backend => _backend;
  int _generation = 0;
  bool _disposed = false;

  /// Replaces the current source and disposes its backend.
  Future<void> setSource(MediaSource source) async {
    if (_disposed) return;
    _source = source;
    _initialization = _load(source, rethrowError: true);
    await _initialization;
  }

  Future<void> _load(
    MediaSource source, {
    required bool rethrowError,
  }) async {
    final generation = ++_generation;
    final previous = _backend;
    _backend = null;
    _setState(const MediaState.loading());
    try {
      await previous?.dispose();
      if (!_isCurrent(generation)) return;
      final backend = _createBackend(source, generation);
      _backend = backend;
      await backend.initialize();
      if (!_isCurrent(generation)) {
        await backend.dispose();
        return;
      }
      // Some platform players (notably YouTube's iframe) cannot emit their
      // ready event until their viewer is mounted. Publish the initialized
      // backend while retaining the canonical loading state so the viewer can
      // mount the surface and wait for that event.
      _setState(_state);
    } on MediaPlayerException catch (exception) {
      if (!await _disposeFailedBackend(generation)) return;
      _setFailure(MediaFailureKind.loadFailed, exception);
      if (rethrowError) rethrow;
    } on Exception catch (error) {
      if (!await _disposeFailedBackend(generation)) return;
      final exception = MediaLoadException(cause: error);
      _setFailure(MediaFailureKind.loadFailed, exception);
      if (rethrowError) throw exception;
    }
  }

  Future<bool> _disposeFailedBackend(int generation) async {
    if (!_isCurrent(generation)) return false;
    final backend = _backend;
    _backend = null;
    try {
      await backend?.dispose();
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'mixup_media_player',
          context: ErrorDescription('while disposing a failed media backend'),
        ),
      );
    }
    return _isCurrent(generation);
  }

  MediaPlayerBackend _createBackend(MediaSource source, int generation) {
    void onChanged(PlaybackSnapshot snapshot) {
      if (!_isCurrent(generation)) return;
      if (snapshot.error != null) {
        _setFailure(
          MediaFailureKind.playbackFailed,
          MediaPlaybackException(cause: snapshot.error),
        );
        return;
      }
      _setState(
        MediaState(
          status: snapshot.status,
          position: snapshot.position,
          duration: snapshot.duration,
        ),
      );
    }

    return switch (source) {
      VideoMediaSource(:final data) => VideoPlayerBackend(data, onChanged),
      AudioMediaSource(:final data) => AudioPlayerBackend(data, onChanged),
      YouTubeMediaSource(:final videoId) => YouTubePlayerBackend(
        videoId,
        onChanged,
      ),
    };
  }

  /// Starts or resumes playback.
  Future<void> play() => _operate((backend) => backend.play());

  /// Pauses playback at the current position.
  Future<void> pause() => _operate((backend) => backend.pause());

  /// Stops playback and returns its position to zero.
  Future<void> stop() => _operate((backend) => backend.stop());

  /// Moves forward by a non-negative [offset], clamped to the duration.
  Future<void> skipForward(Duration offset) {
    _validateOffset(offset);
    return seek(_state.position + offset);
  }

  /// Moves backward by a non-negative [offset], clamped to zero.
  Future<void> skipBackward(Duration offset) {
    _validateOffset(offset);
    return seek(_state.position - offset);
  }

  void _validateOffset(Duration offset) {
    if (offset.isNegative) {
      throw MediaPlaybackException(
        message: 'Skip offsets must not be negative.',
        cause: offset,
      );
    }
  }

  /// Seeks to [position], clamped to the playable range.
  Future<void> seek(Duration position) {
    final duration = _state.duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : duration > Duration.zero && position > duration
        ? duration
        : position;
    return _operate((backend) => backend.seek(clamped));
  }

  /// Disposes and prepares the current source again.
  Future<void> retry() {
    return _initialization = _load(_source, rethrowError: true);
  }

  Future<void> _operate(
    Future<void> Function(MediaPlayerBackend backend) operation,
  ) async {
    final backend = _backend;
    if (_disposed || backend == null || !_state.isReady) return;
    try {
      await operation(backend);
    } on MediaPlayerException catch (exception) {
      _setFailure(MediaFailureKind.playbackFailed, exception);
      rethrow;
    } on Exception catch (error) {
      final exception = MediaPlaybackException(cause: error);
      _setFailure(MediaFailureKind.playbackFailed, exception);
      throw exception;
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _setFailure(MediaFailureKind kind, MediaPlayerException exception) {
    _setState(
      MediaState(
        status: MediaPlaybackStatus.error,
        position: _state.position,
        duration: _state.duration,
        failure: MediaFailure(
          kind: kind,
          exception: exception,
          recoveryAction: kind == MediaFailureKind.invalidSource
              ? MediaRecoveryAction.chooseAnotherSource
              : MediaRecoveryAction.retry,
        ),
      ),
    );
    FlutterError.reportError(
      FlutterErrorDetails(exception: exception, library: 'mixup_media_player'),
    );
  }

  void _setState(MediaState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    final backend = _backend;
    _backend = null;
    if (backend != null) unawaited(backend.dispose());
    super.dispose();
  }
}
