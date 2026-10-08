import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

int _nextVideoView = 0;

Widget createPgVideoPlayer(String url) {
  final viewType = 'apnastay-pg-video-${_nextVideoView++}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final video = web.document.createElement('video') as web.HTMLVideoElement
      ..src = url
      ..controls = true
      ..preload = 'metadata'
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain';
    return video;
  });
  return HtmlElementView(viewType: viewType);
}
