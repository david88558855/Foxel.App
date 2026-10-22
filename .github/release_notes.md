请根据操作系统和 CPU 架构选择安装包（**点击表格中的格式即可下载**）。

| 架构 | Windows | macOS | Linux | Android | iOS |
| --- | --- | --- | --- | --- | --- |
| x86-64 (64 位) | [ZIP](https://github.com/__REPO__/releases/download/__TAG__/Foxel-windows-x86_64.zip) | — | [TAR.GZ](https://github.com/__REPO__/releases/download/__TAG__/Foxel-linux-x86_64.tar.gz) | [APK](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-x86_64.apk) | — |
| AArch64 / ARM64 | — | [ZIP](https://github.com/__REPO__/releases/download/__TAG__/Foxel-macos-arm64.zip) | — | [APK](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-arm64-v8a.apk) | [IPA](https://github.com/__REPO__/releases/download/__TAG__/Foxel-ios-arm64-unsigned.ipa) |
| ARMv7 (32 位) | — | — | — | [APK](https://github.com/__REPO__/releases/download/__TAG__/Foxel-android-armeabi-v7a.apk) | — |

### 安装说明

- **Windows**：下载 ZIP 压缩包，解压后运行 `Foxel.exe`
- **macOS**：下载 ZIP 压缩包，解压后拖入「应用程序」文件夹；首次打开可能需要在「系统设置 > 隐私与安全性」中允许
- **Linux**：下载 TAR.GZ 压缩包，解压后运行 `Foxel`
- **Android**：下载对应架构的 APK 文件安装；大多数现代设备选择 `arm64-v8a`
- **iOS**：下载 IPA 文件，需通过 AltStore 等工具侧载安装（未签名版本）

---

## 全新应用图标

图标母题直接取自服务端 `logo.svg` 的那只狐狸，矢量路径零改动，只重新构图与配色。

- **主色渐变底 + 白色狐狸**：`#5B7CFF → #6B4EE6`，与 App 主色同族，深浅壁纸都能压住
- **五平台一次换齐**：Android / iOS / macOS / Windows / Linux 全部替换，桌面、任务栏、Dock、启动器里都不再出现 Flutter 默认图标

### 各平台的差异处理

| 平台 | 做法 |
| --- | --- |
| Windows | 圆角 20% 直接画进 `.ico` 位图，圆角外是 `alpha=0` 的透明像素，壁纸能透出来；ico 内含 16 / 24 / 32 / 48 / 64 / 128 / 256 共 7 档位图 |
| Android | 新增自适应图标（渐变 shape 背景层 + 透明前景层），适配圆形 / 圆角方形等 OEM 遮罩；附带 `monochrome` 层，Android 13+ 主题图标可单色渲染 |
| iOS | 15 档尺寸，全部移除 alpha 通道（App Store 硬性要求），圆角交由系统裁切 |
| macOS | 7 档尺寸，方形不透明，系统自行裁超椭圆并叠加投影 |
| Linux | 沿用圆角 PNG |

### 换完图标看不到变化？

Windows 会缓存图标。若资源管理器仍显示旧图标，执行 `ie4uinit.exe -show`，或清除 `%LocalAppData%\IconCache.db` 后重启资源管理器。已固定到任务栏的快捷方式可能需要重新固定一次。

## 兼容性

- 本次仅更换图标资源与版本号，**未改动任何功能逻辑**：账户、配置、传输队列、浏览位置、媒体缓存全部沿用
- 未做破坏性变更，可以直接覆盖安装

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
