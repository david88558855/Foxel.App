import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 便携版用户数据目录名。
///
/// 不能用 `data`：Flutter Windows 的 `data/` 是运行时资源目录
/// （app.so / flutter_assets / icudtl.dat），用户数据必须与它分开。
const String kPortableDataDirName = 'userdata';

const String _prefsFileName = 'prefs.json';

/// Windows 便携版偏好存储：把 `shared_preferences` 的全部数据写到
/// `<程序目录>/userdata/prefs.json`，删除程序目录即清空数据。
///
/// 通过替换 `SharedPreferencesStorePlatform.instance` 生效，
/// 因此 `SharedPreferences` 的所有调用点都无需改动。
class PortablePrefsStore extends SharedPreferencesStorePlatform {
  PortablePrefsStore(this.file);

  final File file;

  Map<String, Object>? _cache;

  Future<Map<String, Object>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final map = <String, Object>{};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value != null) {
              map[key] = value as Object;
            }
          });
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Foxel] 便携数据读取失败，按空数据启动：$error');
      }
    }
    _cache = map;
    return map;
  }

  /// 原子写：先写临时文件再替换，避免中途崩溃损坏数据。
  Future<void> _persist() async {
    final map = _cache ?? <String, Object>{};
    try {
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(map), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmp.rename(file.path);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Foxel] 便携数据写入失败：$error');
      }
    }
  }

  @override
  Future<bool> clear() async {
    _cache = <String, Object>{};
    await _persist();
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() => _load();

  @override
  Future<bool> remove(String key) async {
    final map = await _load();
    map.remove(key);
    await _persist();
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final map = await _load();
    map[key] = value;
    await _persist();
    return true;
  }
}

/// 便携版存储配置入口（幂等）。
///
/// 只在 Windows 生效。必须在第一次读写 `SharedPreferences` 之前调用；
/// 由于插件注册可能把实例换回系统实现，这里每次都按「当前实例类型」判断，
/// 不使用一次性布尔标志。
class PortableStorage {
  const PortableStorage._();

  /// 当前使用的数据文件路径（用于诊断展示）。
  static String? dataFilePath;

  static void ensureConfigured() {
    if (kIsWeb || !Platform.isWindows) {
      return;
    }
    final current = SharedPreferencesStorePlatform.instance;
    if (current is PortablePrefsStore) {
      dataFilePath = current.file.path;
      return;
    }
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final file = File(
      '$executableDir${Platform.pathSeparator}$kPortableDataDirName'
      '${Platform.pathSeparator}$_prefsFileName',
    );
    SharedPreferencesStorePlatform.instance = PortablePrefsStore(file);
    dataFilePath = file.path;
    if (kDebugMode) {
      debugPrint('[Foxel] 便携版数据文件：${file.path}');
    }
  }
}
