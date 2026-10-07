import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class SymfoniumAudioService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  late AudioHandler _audioHandler;

  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;

  Future<void> initialize() async {
    _audioPlayer = AudioPlayer();
    _audioHandler = await AudioService.init(
      builder: () => _MyAudioHandler(_audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.symfonium.music.channel.audio',
        androidNotificationChannelName: 'Symfonium Playback',
        androidNotificationOngoing: true,
      ),
    );
  }

  /// 從 WebDAV URL 串流高音質音檔（含 Auth Header）
  Future<void> playFromWebDAV({
    required String url,
    required Map<String, String> headers,
  }) async {
    final source = ProgressiveAudioSource(
      Uri.parse(url),
      headers: headers,
    );
    await _audioPlayer.setAudioSource(source);
    await _audioPlayer.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    notifyListeners();
  }

  void disposePlayer() {
    _audioPlayer.dispose();
  }
}

class _MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  _MyAudioHandler(this._player) {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    mediaItem.add(const MediaItem(
      id: 'symfonium_webdav',
      title: 'Symfonium 高音質串流',
      album: 'WebDAV Library',
    ));
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: {MediaAction.seek},
      androidCompactActionIndices: [0, 1, 3],
      processingState: AudioProcessingState.ready,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() => _player.stop();
}
