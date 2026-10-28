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

## 桌面端字体换成 Arial 了

之前桌面端用的是 Flutter 自带的 Roboto —— 它没有中文字形，Windows 上的汉字只能回落到宋体，小字号发虚、笔画粗细跟旁边的数字和英文完全不是一个调子。

这一版把桌面端字体栈固定下来：

| 语言 | 字体 | 说明 |
| --- | --- | --- |
| 英文 / 数字 | **Arial** | 桌面系统通用，字形紧凑、小字号清晰 |
| 中文 | **微软雅黑**（Windows）· **苹方**（macOS）· **Noto Sans CJK / 文泉驿**（Linux） | 与 Arial 同属无衬线人文体，字面率和重心最接近，混排不会一高一低 |

- **只影响桌面端**：Windows / macOS / Linux 生效；Android / iOS 仍用系统字体（苹方 / Roboto），保持原生观感。
- **字体栈带兜底**：Arial 缺失时会自动退到系统无衬线体，不会出现方块或空白。
- 编辑器、输入框、对话框、按钮这类容易漏掉的文本也一并覆盖到了。

## 兼容性

- 只改字体渲染，**没有动任何功能逻辑与数据结构**，可以直接覆盖安装（`1.0.10+10`）。
- 如果系统里装了自定义字体替换（例如用工具把 Arial 映射成了别的字体），显示结果会跟随系统设置。

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
