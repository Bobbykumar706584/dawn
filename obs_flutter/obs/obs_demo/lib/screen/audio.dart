import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:obs_demo/screen/player.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorder extends StatefulWidget {
  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  late AudioPlayer audioPlayer;
  String? _filePath;
  bool _isRecording = false;
  bool _hasRecording = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    if (await Record().hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/audio_recording.wav';

      // Check if there is already a recording
      if (_hasRecording) {
        bool reRecord = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Record Again?'),
            content: Text('Do you want to re-record the audio?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(true), // Yes, re-record
                child: Text('Yes'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), // No, keep current
                child: Text('No'),
              ),
            ],
          ),
        );

        if (reRecord != null && reRecord == false) {
          // User chose not to re-record
          setState(() {
            _isRecording = false; // Set recording state to false
          });
          return; // Exit method without starting a new recording
        }
      }

      // Start recording
      await Record().start(
        path: _filePath,
        encoder: AudioEncoder.AAC,
        bitRate: 128000,
        samplingRate: 44100,
      );

      setState(() {
        _isRecording = true; // Update recording state
        _hasRecording = false; // Reset hasRecording flag
      });

      print('Recording started: $_filePath');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required')),
      );
    }
  }

  Future<void> _stopRecording() async {
    await Record().stop();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    print('Recording stopped: $_filePath');
  }

  Future<void> _playRecording() async {
    if (_filePath != null && File(_filePath!).existsSync()) {
      await audioPlayer.play(DeviceFileSource(_filePath!));
      print('Playing recording: $_filePath');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No recording found or file does not exist')),
      );
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      _stopRecording();
    }
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isRecording ? 'Recording...' : 'Press the button to record'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  child: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
                ),
                SizedBox(width: 20), // Adjust spacing as needed
                if (_filePath != null && !_isRecording && _hasRecording)
                  ElevatedButton(
                    onPressed: _playRecording,
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 5),
                        Text('Play'),
                      ],
                    ),
                  ),
              ],
            ),
            // if (_filePath != null && !_isRecording && _hasRecording) ...[
            //   // SizedBox(height: 20),
            //   // Text('Recording saved at:'),
            //   // Text(_filePath!),
            //   // SizedBox(height: 20),
            //   PlayerWidget(
            //     player: audioPlayer,
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
