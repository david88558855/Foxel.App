请根据操作系统和 CPU 架构选择安装包。

| 架构 | Windows | macOS | Linux | Android | iOS |
| --- | --- | --- | --- | --- | --- |
| x86-64 (64 位) | ZIP | — | TAR.GZ | APK | — |
| AArch64 / ARM64 | — | ZIP | — | APK | IPA |
| ARMv7 (32 位) | — | — | — | APK | — |

### 安装说明

- **Windows**：下载 ZIP 压缩包，解压后运行 `foxel.exe`
- **macOS**：下载 ZIP 压缩包，解压后拖入「应用程序」文件夹；首次打开可能需要在「系统设置 > 隐私与安全性」中允许
- **Linux**：下载 TAR.GZ 压缩包，解压后运行 `foxel`
- **Android**：下载对应架构的 APK 文件安装；大多数现代设备选择 `arm64-v8a`
- **iOS**：下载 IPA 文件，需通过 AltStore 等工具侧载安装（未签名版本）

### 本次附件

| 平台 / 架构 | 文件名 |
| --- | --- |
| Windows x86-64 | `Foxel-windows-x86_64.zip` |
| macOS ARM64 | `Foxel-macos-arm64.zip` |
| Linux x86-64 | `Foxel-linux-x86_64.tar.gz` |
| Android ARM64 | `Foxel-android-arm64-v8a.apk` |
| Android ARMv7 | `Foxel-android-armeabi-v7a.apk` |
| Android x86-64（模拟器） | `Foxel-android-x86_64.apk` |
| iOS ARM64（未签名） | `Foxel-ios-arm64-unsigned.ipa` |

### 本版要点

- **多账户沙箱**：登录凭证 / 下载目录 / 传输队列 / 浏览位置 / 媒体缓存五类数据按账户隔离
- **统一空态**：没有账户时停留在「账户管理页空态」，不自动创建默认账户
- **多选批量删除**：账户管理页右上「编辑」→ 勾选 →「删除 N 项」，删空即回空态
- **账户级下载目录**：默认目录优先使用显示名称，支持系统目录浏览与权限引导
- **Windows 便携版**：数据写在 `<程序目录>/userdata/prefs.json`，删除程序目录即清空数据

> 设计稿：`docs/foxel-account-design.html`（9 页可交互）· 设计规范总览：`docs/foxel-design-overview.svg` · 说明文档：`README.md`

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
