import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_settings.freezed.dart';

/// Validated local paths loaded from the application's settings asset.
@freezed
abstract class ContentSettings with _$ContentSettings {
  /// Creates settings for all required content collections.
  const factory ContentSettings({
    required String songsPath,
    required String mixesPath,
  }) = _ContentSettings;

  /// Parses the canonical `settings.json` representation.
  factory ContentSettings.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('settings.json must contain an object.');
    }
    final contentPaths = decoded['contentPaths'];
    if (contentPaths is! Map<String, dynamic>) {
      throw const FormatException('settings.json is missing contentPaths.');
    }

    String requiredPath(String key) {
      final value = contentPaths[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('contentPaths.$key must be a non-empty string.');
      }
      return value;
    }

    return ContentSettings(
      songsPath: requiredPath('songs'),
      mixesPath: requiredPath('mixes'),
    );
  }
}
