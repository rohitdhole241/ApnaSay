import 'package:flutter/widgets.dart';

import 'pg_video_player_stub.dart'
    if (dart.library.html) 'pg_video_player_web.dart'
    as platform;

class PgVideoPlayer extends StatelessWidget {
  final String url;

  const PgVideoPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) => platform.createPgVideoPlayer(url);
}
