import 'package:flutter_test/flutter_test.dart';
import 'package:mixup_media_player/mixup_media_player.dart';

void main() {
  group('network media validation', () {
    test('accepts absolute HTTP and HTTPS URLs', () {
      expect(
        NetworkVideoData(Uri.parse('https://example.com/video.mp4')).url,
        Uri.parse('https://example.com/video.mp4'),
      );
      expect(
        NetworkAudioData(Uri.parse('http://example.com/audio.mp3')).url,
        Uri.parse('http://example.com/audio.mp3'),
      );
    });

    for (final value in [
      'video.mp4',
      'file:///tmp/video.mp4',
      'ftp://host/a',
    ]) {
      test('rejects $value with a typed exception', () {
        expect(
          () => NetworkVideoData(Uri.parse(value)),
          throwsA(
            isA<MediaSourceValidationException>()
                .having((error) => error.field, 'field', 'url')
                .having(
                  (error) => error.rejectedValue,
                  'rejectedValue',
                  Uri.parse(value),
                ),
          ),
        );
      });
    }
  });

  group('asset validation', () {
    test('rejects empty paths and package names', () {
      expect(
        () => AssetAudioData('  '),
        throwsA(isA<MediaSourceValidationException>()),
      );
      expect(
        () => AssetVideoData('videos/a.mp4', package: ''),
        throwsA(
          isA<MediaSourceValidationException>().having(
            (error) => error.field,
            'field',
            'package',
          ),
        ),
      );
    });
  });

  group('YouTube validation', () {
    test('accepts watch and share URLs', () {
      final watchSource = YouTubeMediaSource(
        url: Uri.parse('https://www.youtube.com/watch?v=aqz-KE-bpKQ'),
      );
      expect(watchSource.url.host, 'www.youtube.com');
      expect(watchSource.videoId, const VideoId('aqz-KE-bpKQ'));
      expect(
        YouTubeMediaSource(
          url: Uri.parse('https://youtu.be/aqz-KE-bpKQ'),
        ).url.host,
        'youtu.be',
      );
    });

    test('rejects a YouTube URL without a video ID', () {
      expect(
        () => YouTubeMediaSource(url: Uri.parse('https://www.youtube.com/')),
        throwsA(
          isA<MediaSourceValidationException>()
              .having((error) => error.field, 'field', 'url')
              .having(
                (error) => error.message,
                'message',
                contains('YouTube video ID'),
              ),
        ),
      );
    });
  });
}
