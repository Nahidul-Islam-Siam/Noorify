import 'dart:io';

import 'package:image/image.dart' as img;

class _ConversionTarget {
  const _ConversionTarget({
    required this.inputPath,
    required this.outputPath,
    required this.quality,
  });

  final String inputPath;
  final String outputPath;
  final int quality;
}

Future<void> main() async {
  final root = Directory.current.path.replaceAll('\\', '/');
  final targets = <_ConversionTarget>[
    _ConversionTarget(
      inputPath: '$root/assets/images/Login.png',
      outputPath: '$root/assets/images/Login.jpg',
      quality: 84,
    ),
    _ConversionTarget(
      inputPath: '$root/assets/images/app-opening-page.png',
      outputPath: '$root/assets/images/app-opening-page.jpg',
      quality: 84,
    ),
  ];

  for (final target in targets) {
    final inFile = File(target.inputPath);
    if (!inFile.existsSync()) {
      stderr.writeln('Input not found: ${target.inputPath}');
      continue;
    }

    final source = await img.decodeImageFile(target.inputPath);
    if (source == null) {
      stderr.writeln('Could not decode image: ${target.inputPath}');
      continue;
    }

    final encoded = img.encodeJpg(
      source.hasAlpha ? _flattenOnWhite(source) : source,
      quality: target.quality,
    );
    final outFile = File(target.outputPath);
    await outFile.writeAsBytes(encoded, flush: true);

    final inputBytes = inFile.lengthSync();
    final outputBytes = outFile.lengthSync();
    final savedBytes = inputBytes - outputBytes;
    final savedPct = inputBytes == 0
        ? 0
        : (savedBytes / inputBytes * 100).round();

    stdout.writeln(
      'Converted ${_basename(target.inputPath)} -> ${_basename(target.outputPath)} '
      '(${_humanSize(inputBytes)} -> ${_humanSize(outputBytes)}, saved $savedPct%)',
    );
  }
}

img.Image _flattenOnWhite(img.Image source) {
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(output, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(output, source);
  return output;
}

String _basename(String path) => path.split('/').last;

String _humanSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
}
