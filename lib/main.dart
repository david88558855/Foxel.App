import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app.dart';
import 'core/platform/portable_path_provider.dart';

export 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 便携版：数据（账户 / 沙箱 / 偏好）全部落到程序目录的 data/ 内，
  // 删除程序目录即清空数据。
  PortableStorage.ensureConfigured();

  MediaKit.ensureInitialized();
  runApp(const FoxelDriveApp());
}
