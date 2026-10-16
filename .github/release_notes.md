请根据操作系统和 CPU 架构选择安装包（**点击表格中的格式即可下载**）。

| 架构 | Windows | macOS | Linux | Android | iOS |
| --- | --- | --- | --- | --- | --- |
| x86-64 (64 位) | [ZIP](https://github.com/__REPO__/releases/download/__TAG__/Foxel-windows-x86_64.zip) | — | [TAR.GZ](https://github.com/__REPO__/releases/download/__TAG__/Foxel-linux-x86_64.tar.gz) | [APK](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-x86_64.apk) | — |
| AArch64 / ARM64 | — | [ZIP](https://github.com/__REPO__/releases/download/__TAG__/Foxel-macos-arm64.zip) | — | [APK](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-arm64-v8a.apk) | [IPA](https://github.com/__REPO__/releases/download/__TAG__/Foxel-ios-arm64-unsigned.ipa) |
| ARMv7 (32 位) | — | — | — | [APK](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-armeabi-v7a.apk) | — |

### 安装说明

- **Windows**：下载 ZIP 压缩包，解压后运行 `foxel.exe`
- **macOS**：下载 ZIP 压缩包，解压后拖入「应用程序」文件夹；首次打开可能需要在「系统设置 > 隐私与安全性」中允许
- **Linux**：下载 TAR.GZ 压缩包，解压后运行 `foxel`
- **Android**：下载对应架构的 APK 文件安装；大多数现代设备选择 `arm64-v8a`
- **iOS**：下载 IPA 文件，需通过 AltStore 等工具侧载安装（未签名版本）

### 本次附件（也可在下方 Assets 中直接下载）

| 平台 / 架构 | 文件 | 大小 |
| --- | --- | --- |
| Windows x86-64 | [Foxel-windows-x86_64.zip](https://github.com/__REPO__/releases/download/__TAG__/Foxel-windows-x86_64.zip) | 约 32 MB |
| macOS ARM64 | [Foxel-macos-arm64.zip](https://github.com/__REPO__/releases/download/__TAG__/Foxel-macos-arm64.zip) | 约 35 MB |
| Linux x86-64 | [Foxel-linux-x86_64.tar.gz](https://github.com/__REPO__/releases/download/__TAG__/Foxel-linux-x86_64.tar.gz) | 约 10 MB |
| Android ARM64 | [Foxel-android-arm64-v8a.apk](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-arm64-v8a.apk) | 约 33 MB |
| Android ARMv7 | [Foxel-android-armeabi-v7a.apk](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-armeabi-v7a.apk) | 约 30 MB |
| Android x86-64（模拟器） | [Foxel-android-x86_64.apk](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-x86_64.apk) | 约 38 MB |
| iOS ARM64（未签名） | [Foxel-ios-arm64-unsigned.ipa](https://github.com/__REPO__/releases/download/__TAG__/Foxel-ios-arm64-unsigned.ipa) | 约 15 MB |

### 本版要点

- **多账户沙箱**：登录凭证 / 下载目录 / 传输队列 / 浏览位置 / 媒体缓存五类数据按账户隔离
- **统一空态**：没有账户时停留在「账户管理页空态」，不自动创建默认账户
- **多选批量删除**：账户管理页右上「编辑」→ 勾选 →「删除 N 项」，删空即回空态
- **账户级下载目录**：默认目录优先使用显示名称，支持系统目录浏览与权限引导
- **Windows 便携版**：数据写在 `<程序目录>/userdata/prefs.json`，删除程序目录即清空数据

> 设计稿：`docs/foxel-account-design.html`（9 页可交互）· 设计规范总览：`docs/foxel-design-overview.svg` · 说明文档：`README.md`

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
