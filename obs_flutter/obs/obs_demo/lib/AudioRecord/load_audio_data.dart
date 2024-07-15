import 'dart:convert';
import 'dart:math' as math;

Map<String, dynamic> loadParseJson(Map<String, dynamic> audioDataMap) {
  // Decode the JSON data
  final Map<String, dynamic> data = jsonDecode(audioDataMap["json"]);

  // Cast the 'data' field to a List of int
  final List<int> rawSamples = List.castFrom<dynamic, int>(data['data']);

  // Initialize an empty list for the filtered data
  List<int> filteredData = [];

  // Define the total number of samples and calculate the block size
  final int totalSamples = audioDataMap["totalSamples"];
  final double blockSize = rawSamples.length / totalSamples;

  // Iterate through each block to calculate the average value
  for (int i = 0; i < totalSamples; i++) {
    final int blockStart = (blockSize * i).toInt();
    int sum = 0;

    for (int j = 0; j < blockSize; j++) {
      sum += rawSamples[blockStart + j];
    }

    filteredData.add((sum / blockSize).round());
  }

  // Find the maximum absolute value in the filtered data
  final int maxNum = filteredData.reduce((a, b) => math.max(a.abs(), b.abs()));

  // Calculate the multiplier for normalizing the data
  final double multiplier = 1.0 / maxNum;

  // Normalize the filtered data
  final List<double> samples = filteredData.map((e) => e * multiplier).toList();

  // Return the normalized samples
  return {"samples": samples};
}
