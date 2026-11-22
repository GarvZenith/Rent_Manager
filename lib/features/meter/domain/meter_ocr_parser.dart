/// Parsing engine for extracting electricity sub-meter readings from raw OCR text
/// produced by camera scans of digital LCD and analog odometer displays.
class MeterOcrResult {
  final double? reading;
  final String rawText;
  final double confidence; // 0.0 to 1.0
  final String? matchedSnippet;
  final bool isHighConfidence;

  const MeterOcrResult({
    this.reading,
    required this.rawText,
    this.confidence = 0.0,
    this.matchedSnippet,
    this.isHighConfidence = false,
  });

  bool get hasReading => reading != null;
}

class MeterOcrParser {
  /// Primary regex for numbers explicitly followed or preceded by kWh / KWH / Unit indicators
  /// Examples: '1080.5 kWh', '01250 KWH', 'kWh: 1080', '950 units'
  static final RegExp _kwhPattern = RegExp(
    r'(?:kwh|units?|kw|reading)[\s:=]*([0-9]{1,6}(?:\.[0-9]{1,2})?)|([0-9]{1,6}(?:\.[0-9]{1,2})?)[\s]*(?:kwh|units?|kw)',
    caseSensitive: false,
  );

  /// Secondary regex for standard 4 to 6 digit electric meter LCD displays with optional leading zeroes
  /// Examples: '01080.5', '001250', '12450.0'
  static final RegExp _meterDigitsPattern = RegExp(
    r'\b0*([1-9][0-9]{1,5}(?:\.[0-9]{1,2})?)\b|\b(0(?:\.[0-9]{1,2})?)\b',
  );

  /// False positive patterns to exclude:
  /// Voltage ('230V', '240 V'), Frequency ('50Hz'), Dates ('2026/04/01', '01-04-2026'), Time ('12:30')
  static final RegExp _exclusionPattern = RegExp(
    r'(?:\d+[\s]*(?:v|volts|hz|a|amps|rpm)\b)|(?:\d{1,4}[-/\.]\d{1,2}[-/\.]\d{2,4})|(?:\d{1,2}:\d{2})',
    caseSensitive: false,
  );

  /// Normalizes common 7-segment LCD OCR confusion artifacts:
  /// - Capital 'O' or lowercase 'o' into '0'
  /// - Capital 'I', 'l', or '|' into '1'
  /// - Capital 'S' into '5' (when adjacent to digits)
  /// - Capital 'B' into '8' (when adjacent to digits)
  static String sanitizeOcrText(String rawText) {
    if (rawText.isEmpty) return rawText;

    var cleaned = rawText;

    // Replace obvious letter substitutions between digits
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)[Oo](\d)'),
      (m) => '${m[1]}0${m[2]}',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)[Il|](\d)'),
      (m) => '${m[1]}1${m[2]}',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)[Ss](\d)'),
      (m) => '${m[1]}5${m[2]}',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)[Bb](\d)'),
      (m) => '${m[1]}8${m[2]}',
    );

    return cleaned;
  }

  /// Extracts the most plausible sub-meter reading from OCR text
  static MeterOcrResult parse(String rawText, {double? previousReading}) {
    if (rawText.trim().isEmpty) {
      return MeterOcrResult(rawText: rawText, confidence: 0.0);
    }

    final sanitized = sanitizeOcrText(rawText);

    // 1. Try kWh-specific pattern first (highest confidence)
    final kwhMatches = _kwhPattern.allMatches(sanitized);
    for (final match in kwhMatches) {
      final candidateStr = match.group(1) ?? match.group(2);
      if (candidateStr != null) {
        final parsed = double.tryParse(candidateStr);
        if (parsed != null && parsed >= 0) {
          // If we have previous reading, check if this is >= previous reading
          final isLogical = previousReading == null || parsed >= previousReading;
          final confidence = isLogical ? 0.95 : 0.75;
          return MeterOcrResult(
            reading: parsed,
            rawText: rawText,
            confidence: confidence,
            matchedSnippet: match.group(0),
            isHighConfidence: isLogical,
          );
        }
      }
    }

    // 2. Filter out non-reading metrics (Voltage, Frequency, Dates)
    final lines = sanitized.split('\n');
    final validCandidates = <double>[];

    for (final line in lines) {
      final cleanLine = line.replaceAll(_exclusionPattern, ' ');
      final digitMatches = _meterDigitsPattern.allMatches(cleanLine);

      for (final match in digitMatches) {
        final candidateStr = match.group(1) ?? match.group(2);
        if (candidateStr != null) {
          final parsed = double.tryParse(candidateStr);
          if (parsed != null && parsed > 0 && parsed < 1000000) {
            validCandidates.add(parsed);
          }
        }
      }
    }

    if (validCandidates.isEmpty) {
      return MeterOcrResult(rawText: rawText, confidence: 0.0);
    }

    // 3. Selection heuristic:
    // If previousReading is known, prefer candidates strictly greater than previousReading first
    if (previousReading != null && previousReading > 0) {
      final strictlyGreater = validCandidates.where((c) => c > previousReading).toList();
      if (strictlyGreater.isNotEmpty) {
        strictlyGreater.sort();
        final best = strictlyGreater.first;
        final confidence = (best - previousReading) < 1000 ? 0.85 : 0.65;
        return MeterOcrResult(
          reading: best,
          rawText: rawText,
          confidence: confidence,
          matchedSnippet: best.toString(),
          isHighConfidence: confidence >= 0.8,
        );
      }
      final equal = validCandidates.where((c) => c == previousReading).toList();
      if (equal.isNotEmpty) {
        return MeterOcrResult(
          reading: equal.first,
          rawText: rawText,
          confidence: 0.70,
          matchedSnippet: equal.first.toString(),
          isHighConfidence: false,
        );
      }
    }

    // Otherwise, pick the candidate that best matches typical Indian PG sub-meter ranges (100 to 99999)
    validCandidates.sort((a, b) => b.compareTo(a)); // largest plausible
    final best = validCandidates.first;

    return MeterOcrResult(
      reading: best,
      rawText: rawText,
      confidence: 0.60,
      matchedSnippet: best.toString(),
      isHighConfidence: false,
    );
  }
}
