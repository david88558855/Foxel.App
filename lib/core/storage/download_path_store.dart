import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadPathStore {
  static const _downloadPathKey = 'foxel_download_path';

  /// Load the custom download path from persistent storage.
  /// Returns null if no custom path has been set.
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadPathKey);
  }

  /// Save a custom download path to persistent storage.
  Future<void> save(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadPathKey, path);
  }

  /// Remove the custom download path, reverting to the default.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadPathKey);
  }

  /// Resolve the download directory:
  /// 1. If a custom path is set and the directory still exists, use it.
  /// 2. Otherwise fall back to the system downloads directory.
  /// 3. If that is unavailable, fall back to the app documents directory.
  Future<Directory> resolveDownloadDirectory() async {
    final customPath = await load();
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return dir;
      }
    }
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      return downloadsDir;
    }
    return await getApplicationDocumentsDirectory();
  }
}