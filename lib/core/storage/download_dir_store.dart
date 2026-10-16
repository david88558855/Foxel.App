import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 下载目录配置。
///
/// Android 端默认目录固定为 /storage/emulated/0/Download/Foxel，
/// 用户可以在「设置 → 下载目录」中修改。
class DownloadDirStore {
  static const _prefsKey = 'foxel_download_dir';
  static const _channel = MethodChannel('foxel/storage');

  /// Android 端固定默认下载目录。
  static const String androidDefaultDir = '/storage/emulated/0/Download/Foxel';

  /// 读取当前配置的下载目录，未配置时返回平台默认值。
  static Future<String> currentDir() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return defaultDir();
  }

  /// 平台默认下载目录。Android 固定为 [androidDefaultDir]，
  /// 其他平台优先使用系统下载目录。
  static Future<String> defaultDir() async {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isAndroid) {
      return androidDefaultDir;
    }
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return downloads.path;
      }
      final docs = await getApplicationDocumentsDirectory();
      return docs.path;
    } catch (_) {
      return '';
    }
  }

  /// 沙箱内下载目录的配置 key。
  static String dirKeyFor(String accountId) =>
      'foxel_acc_${accountId}_download_dir';

  /// 账户默认下载目录：<平台默认>/Foxel/<账户ID>。
  static Future<String> defaultDirFor(String accountId) async {
    final base = await defaultDir();
    if (base.isEmpty) {
      return '';
    }
    final separator = Platform.pathSeparator;
    final trimmed = base.endsWith(separator)
        ? base.substring(0, base.length - separator.length)
        : base;
    return '$trimmed${separator}Foxel$separator$accountId';
  }

  /// 账户下载目录：优先用户自定义，否则使用该账户沙箱默认目录。
  static Future<String> currentDirFor(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(dirKeyFor(accountId));
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return defaultDirFor(accountId);
  }

  /// 保存账户自定义下载目录。
  static Future<void> setDirFor(String accountId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dirKeyFor(accountId), path.trim());
  }

  /// 恢复账户默认下载目录。
  static Future<void> resetDirFor(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dirKeyFor(accountId));
  }

  /// 解析账户下载目录并确保存在。
  static Future<Directory> resolveFor(String accountId) async {
    final dir = Directory(await currentDirFor(accountId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 当前是否配置了自定义下载目录。
  static Future<bool> isCustomDir() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null || saved.trim().isEmpty) {
      return false;
    }
    return saved.trim() != await defaultDir();
  }

  /// 保存自定义下载目录。
  static Future<void> setDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path.trim());
  }

  /// 恢复默认下载目录。
  static Future<void> resetDir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// 解析实际下载目录，并确保目录存在。
  static Future<Directory> resolve() async {
    final dir = Directory(await currentDir());
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 统计账户下载目录已占用的字节数（不存在时返回 0）。
  static Future<int> dirSizeBytes(String accountId) async {
    if (kIsWeb) {
      return 0;
    }
    final path = await currentDirFor(accountId);
    if (path.isEmpty) {
      return 0;
    }
    final dir = Directory(path);
    if (!await dir.exists()) {
      return 0;
    }
    var total = 0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {
            // 单个文件读取失败时跳过。
          }
        }
      }
    } catch (_) {
      return total;
    }
    return total;
  }

  /// 通过写入探测文件检查目录是否可写。
  static Future<bool> isWritable(String path) async {
    try {
      final dir = Directory(path.trim());
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final probe = File('${dir.path}/.foxel_write_test');
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Android 专用：是否已获得「所有文件访问」权限。
  static Future<bool> hasAllFilesAccess() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    try {
      return await _channel.invokeMethod<bool>('hasAllFilesAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Android 专用：跳转到系统的「所有文件访问」授权页面。
  static Future<void> requestAllFilesAccess() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('requestAllFilesAccess');
    } on PlatformException {
      // 忽略，用户可在系统设置中手动开启。
    }
  }
}
