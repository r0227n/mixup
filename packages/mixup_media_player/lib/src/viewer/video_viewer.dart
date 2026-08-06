import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mixup_media_player/src/player/video_player_backend.dart';
import 'package:video_player/video_player.dart';

@internal
final class VideoViewer extends StatelessWidget {
  const VideoViewer({required this.backend, super.key});

  final VideoPlayerBackend backend;

  @override
  Widget build(BuildContext context) => VideoPlayer(backend.controller);
}
