import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mixup_media_player/src/player/youtube_player_backend.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

@internal
final class YouTubeViewer extends StatelessWidget {
  const YouTubeViewer({required this.backend, super.key});

  final YouTubePlayerBackend backend;

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: backend.controller);
  }
}
