import 'package:flutter/material.dart';

class ImageTextContainer extends StatelessWidget {
  const ImageTextContainer({
    required this.imageUrl,
    required this.text,
  });

  final String imageUrl;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 150,
        padding: const EdgeInsets.all(8),
        color: const Color(0xF0FDFDFF).withOpacity(0.9),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
