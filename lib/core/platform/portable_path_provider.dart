import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// 便携版存储配置入口（幂等）。
///
/// 只在 Windows 生效：把应用支持目录切到程序目录下的 `data/`。
/// 在 `main()` 与 `AppRoot.initState()` 各调用一次，确保无论插件注册
/// 时机如何，第一次访问偏好设置之前一定已生效。
class PortableStorage {
  const PortableStorage._();

  static bool _configured = false;
  static String? dataPath;

  static void ensureConfigured() {
    if (_configured || kIsWeb || !Platform.isWindows) {
      return;
    }
    final current = PathProviderPlatform.instance;
    if (current is PortablePathProvider) {
      dataPath = current.dataPath;
      _configured = true;
      return;
    }
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final provider = PortablePathProvider(executableDir, current);
    PathProviderPlatform.instance = provider;
    dataPath = provider.dataPath;
    _configured = true;
    if (kDebugMode) {
      debugPrint('[Foxel] 便携版数据目录：${provider.dataPath}');
    }
  }
}

/// Windows 便携版路径策略。
///
/// 把「应用支持目录」指向程序目录下的 `data/`，其余目录（下载 / 临时 /
/// 文档等）继续委托系统默认实现。
///
/// 这样 `shared_preferences`（含账户索引、各账户沙箱数据）全部落在
/// 程序目录内，删除程序目录即等于清空数据，重装后回到账户管理页空态。
class PortablePathProvider extends PathProviderPlatform {
  PortablePathProvider(this.basePath, this._inner);

  /// 程序所在目录（`Platform.resolvedExecutable` 的父目录）。
  final String basePath;

  /// 原平台实现，用于转发未覆盖的目录查询。
  final PathProviderPlatform _inner;

  String get dataPath => '$basePath${Platform.pathSeparator}data';

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory(dataPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getTemporaryPath() => _inner.getTemporaryPath();

  @override
  Future<String?> getApplicationDocumentsPath() =>
      _inner.getApplicationDocumentsPath();

  @override
  Future<String?> getApplicationCachePath() =>
      _inner.getApplicationCachePath();

  @override
  Future<String?> getLibraryPath() => _inner.getLibraryPath();

  @override
  Future<String?> getExternalStoragePath() => _inner.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() =>
      _inner.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) =>
      _inner.getExternalStoragePaths(type: type);

  @override
  Future<String?> getDownloadsPath() => _inner.getDownloadsPath();
}
