import 'package:flutter/material.dart';

class AudioControlRow extends StatelessWidget {
  final Function() onMicPressed;
  final Function() onPausePressed;
  final Function() onStopPressed;
  final Function() onLoopPressed;

  const AudioControlRow({
    required this.onMicPressed,
    required this.onPausePressed,
    required this.onStopPressed,
    required this.onLoopPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              IconButton(
                iconSize: 30,
                onPressed: onMicPressed,
                icon: Icon(Icons.mic),
              ),
            ],
          ),
          Column(
            children: [
              IconButton(
                iconSize: 30,
                onPressed: onPausePressed,
                icon: Icon(Icons.pause),
              ),
            ],
          ),
          Column(
            children: [
              IconButton(
                iconSize: 30,
                onPressed: onStopPressed,
                icon: Icon(Icons.stop),
              ),
            ],
          ),
          Column(
            children: [
              IconButton(
                iconSize: 30,
                onPressed: onLoopPressed,
                icon: Icon(Icons.loop),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
