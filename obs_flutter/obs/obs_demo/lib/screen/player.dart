import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final String? filePath;

  const PlayerWidget({
    required this.player,
    required this.filePath,
    Key? key,
  }) : super(key: key);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  List<double>? _samples;

  bool get _isPlaying => _playerState == PlayerState.playing;

  bool get _isPaused => _playerState == PlayerState.paused;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    _playerState = player.state;
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_duration != null && _duration!.inMilliseconds > 0)
          PolygonWaveform(
            maxDuration: _duration ?? Duration.zero,
            elapsedDuration: _position ?? Duration.zero,
            samples:
                _samples ?? [], // Use _samples if available, else empty list
            height: 300,
            width: MediaQuery.of(context).size.width,
          )
        else
          Container(
            height: 100,
            color: Colors.grey.withOpacity(0.3),
            alignment: Alignment.center,
            child: Text(
              'Loading waveform...$_samples, $_duration', // Placeholder or loading indicator
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
                  ? _durationText
                  : '',
          style: const TextStyle(fontSize: 16.0),
        ),
        // SizedBox(height: 16),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: <Widget>[
        //     IconButton(
        //       icon: Icon(Icons.play_arrow),
        //       onPressed: _isPlaying ? null : _play,
        //     ),
        //     IconButton(
        //       icon: Icon(Icons.pause),
        //       onPressed: _isPlaying ? _pause : null,
        //     ),
        //     IconButton(
        //       icon: Icon(Icons.stop),
        //       onPressed: _stop,
        //     ),
        //   ],
        // ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  // Future<void> _play() async {
  //   await player.resume();
  //   setState(() => _playerState = PlayerState.playing);
  // }

  // Future<void> _pause() async {
  //   await player.pause();
  //   setState(() => _playerState = PlayerState.paused);
  // }

  // Future<void> _stop() async {
  //   await player.stop();
  //   setState(() {
  //     _playerState = PlayerState.stopped;
  //     _position = Duration.zero;
  //   });
  // }
}
