import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class ModelDownloader {
  // Model download URL. Change this for deployment if needed.
  static const String modelUrl =
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';
  static const String modelFileName = 'gemma-3n-E2B-it-int4.task';

  /// Returns the local file path where the model should be stored.
  static Future<String> getModelFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, modelFileName);
  }

  /// Checks if the model file exists locally and matches the expected size.
  static Future<bool> modelIsComplete() async {
    final path = await getModelFilePath();
    final file = File(path);
    if (await file.exists()) {
      // File exists in app's directory, no permission needed
      final expectedSize = await getRemoteFileSize();
      final localSize = await file.length();
      print(
          '[ModelDownloader] Local model size: $localSize, Expected size: $expectedSize');
      if (expectedSize == null) {
        print(
            '[ModelDownloader] Could not get expected size from server. Assuming model is complete.');
        return true;
      }
      final isComplete = localSize == expectedSize;
      print('[ModelDownloader] Model is complete: $isComplete');
      return isComplete;
    }
    // Try to copy from app external files or Download if available
    final copied = await _tryCopyFromSdcardOrDownload(path);
    if (!copied) {
      print(
          '[ModelDownloader] Model file does not exist and could not be copied.');
      return false;
    }
    // After copying, check size again
    final expectedSize = await getRemoteFileSize();
    final localSize = await file.length();
    print(
        '[ModelDownloader] Local model size: $localSize, Expected size: $expectedSize');
    if (expectedSize == null) {
      print(
          '[ModelDownloader] Could not get expected size from server. Assuming model is complete.');
      return true;
    }
    final isComplete = localSize == expectedSize;
    print('[ModelDownloader] Model is complete: $isComplete');
    return isComplete;
  }

  /// Tries to copy the model from /sdcard/Android/data or /sdcard/Download to app storage if present.
  static Future<bool> _tryCopyFromSdcardOrDownload(String destPath) async {
    final candidates = [
      '/storage/emulated/0/Android/data/com.example.myapp/files/gemma-3n-E2B-it-int4.task',
      '/sdcard/Android/data/com.example.myapp/files/gemma-3n-E2B-it-int4.task',
      '/sdcard/Download/gemma-3n-E2B-it-int4.task',
    ];
    for (final candidate in candidates) {
      final file = File(candidate);
      if (await file.exists()) {
        print(
            '[ModelDownloader] Found model at $candidate, attempting to copy to $destPath');
        // Only request permission if accessing Downloads
        if (candidate.contains('/Download/')) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            print(
                '[ModelDownloader] Storage permission not granted. Cannot copy model file from Downloads.');
            continue;
          }
        }
        try {
          await file.copy(destPath);
          print('[ModelDownloader] Copy succeeded from $candidate');
          return true;
        } catch (e) {
          print('[ModelDownloader] Copy failed from $candidate: $e');
        }
      } else {
        print('[ModelDownloader] Model not found at $candidate');
      }
    }
    return false;
  }

  /// Gets the expected file size from the server using a HEAD request.
  static Future<int?> getRemoteFileSize() async {
    try {
      final dio = Dio();
      final response = await dio.head(modelUrl);
      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        return int.tryParse(contentLength);
      }
    } catch (_) {}
    return null;
  }

  /// Downloads the model file, reporting progress (0.0 to 1.0) via [onProgress].
  /// If a partial file exists, resumes download if possible.
  static Future<void> downloadModel(
      {required void Function(double) onProgress}) async {
    await Permission.storage.request();
    final path = await getModelFilePath();
    final file = File(path);
    final dio = Dio();
    int? expectedSize = await getRemoteFileSize();
    int downloaded = 0;
    if (await file.exists()) {
      downloaded = await file.length();
      // If file is complete, skip download
      if (expectedSize != null && downloaded == expectedSize) {
        onProgress(1.0);
        return;
      }
    }
    try {
      await dio.download(
        modelUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        deleteOnError: true,
        options: Options(
          headers: downloaded > 0 ? {'range': 'bytes=$downloaded-'} : null,
        ),
      );
    } catch (e) {
      // Clean up partial file on error
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
    // Verify file size after download
    if (expectedSize != null && await file.length() != expectedSize) {
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception('Downloaded file is incomplete or corrupt.');
    }
  }
}
