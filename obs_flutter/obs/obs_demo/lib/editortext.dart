import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:obs_demo/Editor/image_text_container.dart';
import 'package:obs_demo/Editor/story_editor.dart';
import 'package:obs_demo/Editor/story_para_navigation.dart';
import 'package:obs_demo/screen/player.dart';

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
  String appBarTitle = "";

  late AudioPlayer audioPlayer;
  String? _filePath;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String _recordButtonText = "Record";

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  late Duration maxDuration;
  late Duration elapsedDuration;
  late AudioCache audioCatch;
  late List<double> samples;
  late int totalSamples;

  late List<String> audioData;

  Future<void> fetchStoryText() async {
    try {
      final jsonString = await rootBundle.loadString('assets/OBSTextData.json');
      final jsonData = json.decode(jsonString) as List<dynamic>;

      setState(() {
        storyDatas = jsonData.cast<Map<String, dynamic>>();
        storyIndex = widget.rowIndex;
      });
      // Print the keys of each story dataSS
      // for (var storyData in storyDatas) {
      //   print('Story Data Keys: ${storyData.keys}');
      //   if (storyData.containsKey('story')) {
      //     print('Story Paragraph Keys: ${storyData['story'].first.keys}');
      //   }
      // }
    } catch (e) {
      print('Error loading JSON data: $e');
    }
  }

  Future<void> fetchJson() async {
    Map<String, dynamic> data = await readJsonToFile();
    if (data.isEmpty) {
      final obsJson = await rootBundle.loadString('assets/OBSData.json');
      var obsData = json.decode(obsJson).cast<Map<String, dynamic>>();
      await writeJsonToFile(obsData[storyIndex]);
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
      setState(() {
        _controller.text = data['story'][paraIndex]['text'];
      });
      for (var paragraph in data['story']) {
        if (paragraph['audio'] == null) {
          paragraph.remove('audio');
        }
        if (paragraph['isEmpty'] == false) {
          paragraph.remove('isEmpty');
        }
        if (paragraph['_hasRecording'] == false) {
          paragraph.remove('_hasRecording');
        }
      }
      print(data);
      return data;
    } on FileSystemException {
      return <String, dynamic>{};
    } catch (e) {
      print("Error reading JSON file: $e");
      return <String, dynamic>{};
    }
  }

  Future<void> parseData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${storyIndex}.json');
    final jsonData = await file.readAsString();
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    // print(audioJson);
    // print(jsonData);

    // final samplesData = await compute(loadparseJson, audioDataMap);
    // await audioPlayer.load(audioData[1]);
    // await audioPlayer.play(audioData[1]);
    // maxDuration in milliseconds
    // await Future.delayed(const Duration(milliseconds: 200));

    // int maxDurationInmilliseconds =
    //     await audioPlayer.fixedPlayer!.getDuration();

    // maxDuration = Duration(milliseconds: maxDurationInmilliseconds);
    // setState(() {
    //   samples = samplesData["samples"];
    // });
  }

  @override
  void initState() {
    super.initState();
    fetchStoryText();
    fetchJson();
    parseData();
    _focusNode.addListener(() {
      setState(() {});
    });
    audioPlayer = AudioPlayer();
    _requestPermissions();
    audioPlayer.onPositionChanged.listen((Duration duration) {
      setState(() {
        _currentPosition = duration;
      });
    });
    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    if (await Record().hasPermission()) {
      int storyId = storyDatas[storyIndex]['storyId'];
      int paraId = storyDatas[storyIndex]['story'][paraIndex]['id'];

      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/OBS_${storyId}_$paraId.wav';
      // Start recording
      await Record().start(
        path: _filePath,
        encoder: AudioEncoder.AAC,
        bitRate: 12,
        samplingRate: 48000,
      );

      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      // Update recording start time

      setState(() {
        _isRecording = true; // Update recording state
        _hasRecording = false; // Reset hasRecording flag
        _isPaused = false;
        _recordButtonText = "Pause";
      });

      print('Recording started: $_filePath');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required')),
      );
    }
  }

  Future<void> _pauseRecording() async {
    await Record().pause();
    setState(() {
      _isRecording = false;
      _isPaused = true;
      //  _hasRecording = true; // Assume there's a recording after pause
      _recordButtonText = "Resume";
    });

    // Store the recorded audio path in story data
    // story['story'][paraIndex]['audio'] = _filePath;
    // writeJsonToFile(story);

    print('Recording paused: $_filePath');
  }

  Future<void> _resumeRecording() async {
    await Record().resume();
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordButtonText = "Pause";
    });
    print('Recording resumed: $_filePath');
  }

  Future<void> _stopRecording() async {
    await Record().stop();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _isPaused = false;
      _recordButtonText = "Record";
    });

    // Store the recorded audio path in story data
    story['story'][paraIndex]['audio'] = _filePath;
    // Ensure _filePath is set correctly
    writeJsonToFile(story); // Update JSON file with the latest audio path

    print('Recording stopped: $_filePath');
  }

  Future<void> _reRecording() async {
    bool? confirmReRecord = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Re-record Audio?'),
        content: Text(
            'Do you want to delete the existing recording and record again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User confirmed re-recording
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User canceled re-recording
            },
            child: Text('No'),
          ),
        ],
      ),
    );
//deleting the recorded audio
    if (confirmReRecord == true) {
      // User confirmed re-recording
      if (_isRecording || _isPaused) {
        await Record().stop();
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });
      }
      if (_filePath != null) {
        final file = File(_filePath!);
        if (await file.exists()) {
          await file.delete();
          print('Previous recording deleted');
        }
      }

      setState(() {
        _hasRecording = false;
        _filePath = null;
        _recordButtonText = "Record";
      });

      story['story'][paraIndex]['audio'] = null;
      await writeJsonToFile(story);
      // Optionally start a new recording here or guide the user to start recording manually
      _startRecording();
    }
  }

  ///play recording

  Future<void> _playRecording() async {
    String? audioFile = story['story'][paraIndex]['audio'];
    if (audioFile != null && File(audioFile).existsSync()) {
      await audioPlayer.play(DeviceFileSource(audioFile));
      setState(() {
        _isPlaying = true;
      });
      print('Playing recording: $_filePath');
      audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
        print('Playback completed');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No recording found or file does not exist')),
      );
    }
  }

  Future<void> _pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
    print('Audio paused');
  }

  Future<void> _deleteRecording() async {
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
        print('Recording deleted');
      }
      setState(() {
        _hasRecording = false;
        _isRecording = false;
        _isPlaying = false;
        _isPaused = false;
        _filePath = null;
        _recordButtonText = "Record";
      });
    }

    // Remove the audio path from the story data
    story['story'][paraIndex].remove('audio');
    await writeJsonToFile(story); // Update JSON file

    print('Audio data removed from JSON');
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose of the FocusNode properly
    audioPlayer.dispose();
    _controller.dispose();
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
    bool hasAudio = story['story'] != null &&
        story['story'][paraIndex] != null &&
        story['story'][paraIndex]['audio'] != null &&
        story['story'][paraIndex]['audio'].isNotEmpty;

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
                    // if (hasAudio)
                    // PlayerWidget(
                    //   player: audioPlayer,
                    //   filePath: story['story'][paraIndex]['audio'],
                    // ),
                    // if (_isPlaying || _isPaused || hasAudio) ...[
                    if (hasAudio) ...[
                      Slider(
                        value: _currentPosition.inMilliseconds.toDouble(),
                        max: _totalDuration.inMilliseconds.toDouble(),
                        onChanged: (value) async {
                          final position =
                              Duration(milliseconds: value.toInt());
                          await audioPlayer.seek(position);
                        },
                      ),
                      Text(
                        '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],

                    Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!hasAudio)
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (_isRecording) {
                                      _pauseRecording();
                                    } else if (_isPaused) {
                                      _resumeRecording();
                                    }
                                    // else if (_hasRecording) {
                                    //   _reRecording();
                                    // }
                                    else {
                                      _startRecording();
                                    }
                                  },
                                  child: Text(_recordButtonText),
                                ),

                                // _isRecording
                                //     ? IconButton(
                                //         icon: Icon(Icons.pause),
                                //         onPressed: _pauseRecording,
                                //       )
                                //     : IconButton(
                                //         icon: Icon(Icons.mic),
                                //         onPressed: _hasRecording &&
                                //                 !_isPaused &&
                                //                 !_isRecording
                                //             ? _reRecording
                                //             : (_isPaused
                                //                 ? _resumeRecording
                                //                 : _startRecording),
                                //       ),
                                Text(
                                  _recordButtonText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          if (_isRecording || _isPaused)
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

                          //play and pause audio
                          Column(
                            children: [
                              IconButton(
                                iconSize: 30,
                                onPressed: hasAudio
                                    ? () {
                                        if (_isPlaying) {
                                          _pauseAudio();
                                        } else {
                                          _playRecording();
                                        }
                                      }
                                    : null,
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: _isPlaying ? Colors.green : null,
                                ),
                              ),
                              Text(
                                _isPlaying ? 'Pause' : 'Play',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          //delete
                          Column(
                            children: [
                              IconButton(
                                  iconSize: 30,
                                  onPressed: hasAudio
                                      ? () {
                                          _deleteRecording();
                                        }
                                      : null,
                                  icon: Icon(
                                    Icons.delete,
                                    color: hasAudio ? Colors.red : null,
                                  )),
                              Text(
                                'Delete',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void saveData(String value) async {
    story['story'][paraIndex]['text'] = value;
    writeJsonToFile(story);
    widget.onUpdateTextAvailability(value.isNotEmpty);
    print('Data saved: $value');
  }
}
