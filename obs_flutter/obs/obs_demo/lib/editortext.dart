import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:obs_demo/screen/player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:obs_demo/Editor/image_text_container.dart';
import 'package:obs_demo/Editor/story_editor.dart';
import 'package:obs_demo/Editor/story_para_navigation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:record/record.dart';

class EditorTextLayout extends StatefulWidget {
  const EditorTextLayout({
    required this.rowIndex,
    required this.onUpdateTextAvailability,
  });

  final int rowIndex;
  final Function(bool hasText) onUpdateTextAvailability;

  @override
  _EditorTextLayoutState createState() => _EditorTextLayoutState();
}

class _EditorTextLayoutState extends State<EditorTextLayout> {
  List<Map<String, dynamic>> storyDatas = [];
  Map<String, dynamic> story = {};
  bool isCompleted = false;
  FocusNode _focusNode = FocusNode();
  late int storyIndex;
  int paraIndex = 0;
  final TextEditingController _controller = TextEditingController();
  String _errorMessage = "";
  String _textFieldValue = "";

  late AudioPlayer audioPlayer;
  String? _filePath;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;

  Future<void> fetchStoryText() async {
    final jsonString = await rootBundle.loadString('assets/OBSTextData.json');
    setState(() {
      storyDatas = json.decode(jsonString).cast<Map<String, dynamic>>();
      storyIndex = widget.rowIndex;
    });
  }

  Future<void> fetchJson() async {
    Map<String, dynamic> data = await readJsonToFile();
    if (data.isEmpty) {
      final obsJson = await rootBundle.loadString('assets/OBSData.json');
      var obsData = json.decode(obsJson).cast<Map<String, dynamic>>();
      writeJsonToFile(obsData[storyIndex]);
      setState(() {
        story = obsData[storyIndex];
      });
    } else {
      setState(() {
        story = data;
      });
    }
  }

  Future<void> writeJsonToFile(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${storyIndex}.json');
    final jsonData = jsonEncode(data);
    await file.writeAsString(jsonData);
  }

  Future<Map<String, dynamic>> readJsonToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${storyIndex}.json');

    try {
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      _controller.text = data['story'][paraIndex]['text'];
      data['story'][paraIndex]['isEmpty'] = false;
      return data;
    } on FileSystemException {
      return <String, dynamic>{};
    } catch (e) {
      print("Error reading JSON file: $e");
      return <String, dynamic>{};
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStoryText();
    fetchJson();
    _focusNode.addListener(() {
      setState(() {});
    });
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
      setState(() {
        _isPlaying = true;
      });
      print('Playing recording: $_filePath');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No recording found or file does not exist')),
      );
    }
  }

  Future<void> _pauseRecording() async {
    await Record().pause();
    setState(() {
      _isRecording = false; // Update recording state to paused
    });
    print('Recording paused');
  }

  Future<void> _pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
    print('Audio paused');
  }

  Future<void> _resetAudio() async {
    await audioPlayer.stop();

    print('Audio reset');
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose of the FocusNode properly
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (storyDatas.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    String text =
        storyDatas[storyIndex]['story'][paraIndex]['url'].split('/').last;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(storyDatas[storyIndex]['title']),
        ),
        body: Column(
          children: [
            ImageTextContainer(
              imageUrl: 'assets/images/$text',
              text: storyDatas[storyIndex]['story'][paraIndex]['text'],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    StoryParaNavigation(
                      storyIndex: storyIndex,
                      paraIndex: paraIndex,
                      storyDatas: storyDatas,
                      story: story,
                      controller: _controller,
                      onPressedPrevious: () {
                        setState(() {
                          storyIndex = storyIndex > 0 ? storyIndex - 1 : 0;
                          paraIndex = 0;
                        });
                        fetchJson();
                      },
                      onPressedLeft: () {
                        setState(() {
                          paraIndex = paraIndex > 0 ? paraIndex - 1 : 0;
                        });
                        _controller.text = story['story'][paraIndex]['text'];
                      },
                      onPressedRight: () {
                        setState(() {
                          paraIndex = paraIndex <
                                  storyDatas[storyIndex]['story'].length - 1
                              ? paraIndex + 1
                              : paraIndex;
                        });
                        _controller.text = story['story'][paraIndex]['text'];
                      },
                      onPressedNext: () {
                        setState(() {
                          storyIndex = storyIndex < storyDatas.length - 1
                              ? storyIndex + 1
                              : storyIndex;
                          paraIndex = 0;
                        });
                        fetchJson();
                      },
                    ),
                    StoryEditor(
                      controller: _controller,
                      focusNode: _focusNode,
                      errorMessage: _errorMessage,
                      textFieldValue: _textFieldValue,
                      onSaveData: saveData,
                      onUpdateTextAvailability: widget.onUpdateTextAvailability,
                    ),
                    if (_filePath != null &&
                        !_isRecording &&
                        _hasRecording) ...[
                      PlayerWidget(
                        player: audioPlayer,
                        filePath: _filePath,
                      )
                    ],
                    Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                iconSize: 30,
                                onPressed: _isRecording
                                    ? _pauseRecording
                                    : _startRecording,
                                icon: Icon(
                                    _isRecording ? Icons.pause : Icons.mic),
                              ),
                              Text(
                                _isRecording ? 'Pause' : 'Record',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                  iconSize: 30,
                                  onPressed: _stopRecording,
                                  icon: Icon(Icons.stop)),
                              Text(
                                'Stop',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              IconButton(
                                iconSize: 30,
                                onPressed: _hasRecording
                                    ? (_isPlaying
                                        ? _pauseAudio
                                        : _playRecording)
                                    : null,
                                icon: Icon(_isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                              ),
                              Text(
                                _isPlaying ? 'Pause' : 'Play',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          // Column(
                          //   children: [
                          //     IconButton(
                          //         iconSize: 30,
                          //         icon: Icon(Icons.loop),
                          //         onPressed: _hasRecording ? _resetAudio : null
                          //         // icon: Icon(Icons.loop)
                          //         ),
                          //     Text(
                          //       'Reset',
                          //       textAlign: TextAlign.center,
                          //       style: TextStyle(fontSize: 12),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void saveData(String value) async {
    story['story'][paraIndex]['text'] = value;
    story['story'][paraIndex]['isEmpty'] = value.isEmpty;
    writeJsonToFile(story);
    widget.onUpdateTextAvailability(value.isNotEmpty);
    print('Data saved: $value');
    print(story['story'][paraIndex]);
  }
}
