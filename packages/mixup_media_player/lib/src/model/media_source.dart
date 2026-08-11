import 'package:mixup_media_player/src/model/media_player_exception.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// A media source supported by the package controller.
sealed class MediaSource {
  const MediaSource();
}

/// A strongly typed YouTube video identifier.
extension type const VideoId(String value) {}

/// A video source.
final class VideoMediaSource extends MediaSource {
  /// Creates a video source from validated [data].
  const VideoMediaSource({required this.data});

  /// Validated video input.
  final VideoData data;
}

/// An audio source.
final class AudioMediaSource extends MediaSource {
  /// Creates an audio source from validated [data].
  const AudioMediaSource({required this.data});

  /// Validated audio input.
  final AudioData data;
}

/// A validated YouTube watch, share, shorts, or embed URL.
final class YouTubeMediaSource extends MediaSource {
  /// Validates [url] and creates a YouTube source.
  factory YouTubeMediaSource({required Uri url}) {
    _validateNetworkUrl(url, field: 'url');
    final videoId = YoutubePlayerController.convertUrlToId(url.toString());
    if (videoId == null || videoId.isEmpty) {
      throw MediaSourceValidationException(
        field: 'url',
        message: 'The URL does not contain a supported YouTube video ID.',
        rejectedValue: url,
      );
    }
    return YouTubeMediaSource._(url: url, videoId: VideoId(videoId));
  }

  const YouTubeMediaSource._({required this.url, required this._videoId});

  /// Original validated URL.
  final Uri url;
  final VideoId _videoId;

  /// Extracted, strongly typed YouTube video ID.
  VideoId get videoId => _videoId;
}

/// Input understood by the video player.
sealed class VideoData {
  const VideoData();
}

/// A validated HTTP or HTTPS video URL.
final class NetworkVideoData extends VideoData {
  /// Validates and stores [url].
  factory NetworkVideoData(Uri url) {
    _validateNetworkUrl(url, field: 'url');
    return NetworkVideoData._(url);
  }

  const NetworkVideoData._(this.url);

  /// Validated video URL.
  final Uri url;
}

/// A non-empty Flutter asset path containing video data.
final class AssetVideoData extends VideoData {
  /// Validates and stores [asset] and its optional [package].
  factory AssetVideoData(String asset, {String? package}) {
    _validateAsset(asset);
    if (package != null && package.trim().isEmpty) {
      throw MediaSourceValidationException(
        field: 'package',
        message: 'The asset package name must not be empty.',
        rejectedValue: package,
      );
    }
    return AssetVideoData._(asset, package: package);
  }

  const AssetVideoData._(this.asset, {this.package});

  /// Asset path.
  final String asset;

  /// Optional package owning the asset.
  final String? package;
}

/// Input understood by the audio player.
sealed class AudioData {
  const AudioData();
}

/// A validated HTTP or HTTPS audio URL.
final class NetworkAudioData extends AudioData {
  /// Validates and stores [url].
  factory NetworkAudioData(Uri url) {
    _validateNetworkUrl(url, field: 'url');
    return NetworkAudioData._(url);
  }

  const NetworkAudioData._(this.url);

  /// Validated audio URL.
  final Uri url;
}

/// A non-empty Flutter asset path containing audio data.
final class AssetAudioData extends AudioData {
  /// Validates and stores [asset].
  factory AssetAudioData(String asset) {
    _validateAsset(asset);
    return AssetAudioData._(asset);
  }

  const AssetAudioData._(this.asset);

  /// Asset path.
  final String asset;
}

void _validateNetworkUrl(Uri url, {required String field}) {
  if (!url.hasAuthority ||
      url.host.isEmpty ||
      (url.scheme != 'https' && url.scheme != 'http')) {
    throw MediaSourceValidationException(
      field: field,
      message: 'The media URL must be an absolute HTTP or HTTPS URL.',
      rejectedValue: url,
    );
  }
}

void _validateAsset(String asset) {
  if (asset.trim().isEmpty) {
    throw MediaSourceValidationException(
      field: 'asset',
      message: 'The asset path must not be empty.',
      rejectedValue: asset,
    );
  }
}
