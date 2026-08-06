/// Base type for all failures produced by this package.
sealed class MediaPlayerException implements Exception {
  const MediaPlayerException({required this.message, this.cause});

  /// A stable, user-presentable summary of the failure.
  final String message;

  /// The plugin or platform failure that caused this exception, when present.
  final Object? cause;

  @override
  String toString() => 'MediaPlayerException: $message';
}

/// Indicates invalid data supplied in a media source.
final class MediaSourceValidationException extends MediaPlayerException {
  /// Creates a validation exception for [field].
  const MediaSourceValidationException({
    required this.field,
    required super.message,
    this.rejectedValue,
  });

  /// Name of the invalid field.
  final String field;

  /// Rejected value, safe for callers to inspect but not automatically logged.
  final Object? rejectedValue;
}

/// Indicates that a valid source could not be prepared.
final class MediaLoadException extends MediaPlayerException {
  /// Creates a media preparation exception.
  const MediaLoadException({
    super.message = 'The media could not be loaded.',
    super.cause,
  });
}

/// Indicates that an operation failed after the source was prepared.
final class MediaPlaybackException extends MediaPlayerException {
  /// Creates a playback operation exception.
  const MediaPlaybackException({
    super.message = 'Playback failed.',
    super.cause,
  });
}
