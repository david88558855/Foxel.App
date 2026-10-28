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

## 提示条搬到顶部了

以前文件页的操作提示（「已加入 2 个下载任务」之类）是贴底的黑色浮条，正好压在底部导航上：既挡路，又难跟这一页的浅色卡片配上。现在它挪到了顶部搜索框那一行。

- **位置**：占用搜索框那一格，显示时搜索框让位，2.4 秒后自动还原
- **不挤动列表**：提示条只是浮在上面（位移 + 淡入），高度与搜索框一致，进出都不改变布局，列表不会跳
- **配色**：主色浅底 `#EAF0FF` + 描边 `#D3DFFF` + 深蓝字 `#1B3A78`，与卡片同族，不再是刺眼的纯黑
- **出错自动转红**：`#FDECEC` 底 + `#7A1F1F` 字，一眼分清「成了」和「没成」
- **点一下就能收起**，不用等它自己消失
- 压缩任务的「查看」入口从底部按钮变成提示条右侧的 `查看 ›`

### 覆盖到的提示

批量下载 / 移动 / 复制 / 删除 / 批量重命名、新建文件夹、上传、压缩、下载目录不可写、预览不支持等文件页提示，全部走新样式。

## 兼容性

- 本次只改提示条的呈现方式，**未改动任何功能逻辑与数据结构**：账户、配置、传输队列、浏览位置、媒体缓存全部沿用
- 未做破坏性变更，可以直接覆盖安装（版本 `1.0.8+8`）

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
