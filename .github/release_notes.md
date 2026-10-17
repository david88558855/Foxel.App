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

## 新增功能

**Windows 系统托盘常驻**

- 启动后以托盘模式运行：进程起来、通知区域出现 Foxel 图标，主窗口**一次都不出现**（不是"先闪一下再隐藏"），任务栏也没有程序按钮
- 托盘图标**右键**菜单严格两项：「显示主窗口」「退出」，无分隔线、无子菜单
- **左键双击**托盘图标等效「显示主窗口」——与菜单项共用同一回调，位置、尺寸、最大化状态、任务栏按钮全部一致；左键单击不做任何事
- 点窗口关闭按钮 / `Alt+F4` / 任务栏「关闭窗口」只**收进托盘**：窗口不销毁，位置与尺寸全保留，正在进行的传输不中断
- 只有托盘菜单「退出」才真正结束进程；退出时先摘图标再销毁窗口，通知区域不留残余图标
- 资源管理器（explorer.exe）重启后自动重挂托盘图标
- 单实例：重复双击 `Foxel.exe` 不会开出第二个实例，而是把已有主窗口唤到前台
- 首次启动弹一次通知区域提示（仅一次，标记写入 `userdata/.tray-hint-shown`）

## 问题修复

- Windows 便携版重复启动会同时跑起多个实例并互相覆盖 `userdata/prefs.json`；现在第二个实例只负责唤起已有窗口并立即退出
- 托盘图标挂载失败时回退为直接显示主窗口，避免出现"进程在跑但看不见、点不到"的死局

## 破坏性变更

1. **Windows 启动行为变更**：不再自动显示主窗口，改为托盘常驻；首次使用需从托盘图标进入
2. **Windows 关闭行为变更**：点关闭不再退出程序，只收进托盘；需要退出时请用托盘菜单「退出」

## 已知问题

1. Windows：托盘图标可能被系统收纳进「隐藏的图标」溢出区，可在任务栏设置中固定
2. Windows：首次启动的提示气泡受系统通知设置影响，关闭通知时可能看不到
3. 其余限制沿用 v1.0.5（Android 公共目录权限、iOS / macOS 未提交 `Podfile`、批量下载并发上限等）

> 完整说明：`docs/Foxel-v1.0.6-release-note.md` · 托盘设计稿：`docs/foxel-tray-design.html` · 项目说明：`README.md`

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
