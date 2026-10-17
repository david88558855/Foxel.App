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

### v1.0.3 变更摘要

**新增**
- **文件批量操作**：长按条目或点工具栏「选择」进入多选，批量下载 / 移动 / 复制 / 删除；
  底部操作栏与顶部计数卡（含文件数、体积、文件夹数）
- **批量重命名**：查找替换 / 前后缀 / 序号编号 / 大小写 / 改扩展名五种方式，
  **实时预览**新旧名，冲突在预览阶段拦截

**修复**
- macOS 沙箱缺少出站网络权限，导致无法连接服务器（核心功能）
- 便携版数据文件读取异常时会把空数据写回磁盘，造成账户 / 配置被静默清空
- 批量重命名时 A→B 而 B 在本批未改名会漏判冲突，执行阶段覆盖 B
- 批量操作进行中切换目录会误操作父目录同名条目
- 切换目录 / 返回键残留「幽灵选中」，导致操作栏按钮空转
- 批量下载同名文件互相覆盖；复制未禁止自我嵌套
- 网络抖动不再被误判为「登录已失效」；登录页地址非法时不再卡在「登录中」
- 下载失败残留残缺文件

> 设计稿：`docs/foxel-account-design.html`（11 页可交互）· 设计规范总览：`docs/foxel-design-overview.svg` · 说明文档：`README.md`

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
