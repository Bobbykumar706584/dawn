import 'package:flutter/material.dart';

class StoryParaNavigation extends StatelessWidget {
  const StoryParaNavigation({
    required this.storyIndex,
    required this.paraIndex,
    required this.storyDatas,
    required this.story,
    required this.controller,
    required this.onPressedPrevious,
    required this.onPressedLeft,
    required this.onPressedRight,
    required this.onPressedNext,
  });

  final int storyIndex;
  final int paraIndex;
  final List<Map<String, dynamic>> storyDatas;
  final Map<String, dynamic> story;
  final TextEditingController controller;
  final VoidCallback onPressedPrevious;
  final VoidCallback onPressedLeft;
  final VoidCallback onPressedRight;
  final VoidCallback onPressedNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        storyIndex != 0
            ? IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 35,
                onPressed: onPressedPrevious,
              )
            : IconButton(
                icon: Icon(Icons.skip_previous),
                iconSize: 35,
                color: Color.fromARGB(66, 168, 163, 163).withOpacity(0.5),
                onPressed: () {},
              ),
        paraIndex != 0
            ? IconButton(
                icon: Icon(Icons.arrow_left_sharp),
                iconSize: 35,
                onPressed: onPressedLeft,
              )
            : IconButton(
                icon: Icon(Icons.arrow_left_sharp),
                iconSize: 35,
                color: Color.fromARGB(66, 168, 163, 163).withOpacity(0.5),
                onPressed: () {},
              ),
        Text(storyDatas[storyIndex]['storyId'].toString()),
        const Text(":"),
        Text(storyDatas[storyIndex]['story'][paraIndex]['id'].toString()),
        paraIndex != storyDatas[storyIndex]['story'].length - 1
            ? IconButton(
                icon: Icon(Icons.arrow_right_sharp),
                iconSize: 35,
                onPressed: onPressedRight,
              )
            : IconButton(
                icon: Icon(Icons.arrow_right_sharp),
                iconSize: 35,
                color: Colors.black26.withOpacity(0.5),
                onPressed: () {},
              ),
        storyIndex != storyDatas.length - 1
            ? IconButton(
                icon: Icon(Icons.skip_next),
                iconSize: 35,
                onPressed: onPressedNext,
              )
            : IconButton(
                icon: Icon(Icons.skip_next),
                iconSize: 35,
                color: Color.fromARGB(66, 168, 163, 163).withOpacity(0.5),
                onPressed: () {},
              ),
      ],
    );
  }
}
