import 'package:flutter/material.dart';

class StoryEditor extends StatelessWidget {
  const StoryEditor({
    required this.controller,
    required this.focusNode,
    required this.errorMessage,
    required this.textFieldValue,
    required this.onSaveData,
    required this.onUpdateTextAvailability,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String errorMessage;
  final String textFieldValue;
  final Function(String) onSaveData;
  final Function(bool) onUpdateTextAvailability;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        height: 150,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (value) {
              onSaveData(value);
              onUpdateTextAvailability(value.isNotEmpty);
            },
            decoration: InputDecoration(
              labelText: (focusNode.hasFocus || textFieldValue.isNotEmpty)
                  ? null
                  : 'Start translating story',
              labelStyle: TextStyle(color: Colors.grey),
              errorText: errorMessage.isNotEmpty ? errorMessage : null,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            ),
            maxLines: 25,
          ),
        ),
      ),
    );
  }
}
