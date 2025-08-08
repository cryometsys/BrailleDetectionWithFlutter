class BrailleDetectionResult {
  final String processedText;
  final String explanation;
  final double confidence;
  final List<String> detectedRows;
  final int totalCharacters;
  final String? annotatedImageBase64;

  BrailleDetectionResult({
    required this.processedText,
    required this.explanation,
    required this.confidence,
    required this.detectedRows,
    required this.totalCharacters,
    this.annotatedImageBase64,
  });

  factory BrailleDetectionResult.fromJson(Map<String, dynamic> json) {
    return BrailleDetectionResult(
      processedText: json['processed_text'] ?? '',
      explanation: json['explanation'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      detectedRows: List<String>.from(json['detected_rows'] ?? []),
      totalCharacters: json['total_characters'] ?? 0,
      annotatedImageBase64: json['annotated_image_base64'],
    );
  }
}
