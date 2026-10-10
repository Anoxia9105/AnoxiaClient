import 'package:video_player/video_player.dart';

VideoPlayerController captureVideoController(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));
