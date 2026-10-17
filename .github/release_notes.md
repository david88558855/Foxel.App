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

**文件批量操作**

- 长按任意文件 / 文件夹直接进入多选并选中该项，或点工具栏右上「选择」
- 多选态顶部条为「取消 / 已选择 N 项 / 全选」，条目左侧圆形勾选标记；点条目即勾选
- 顶部计数卡显示「X 个文件（合计体积）+ Y 个文件夹」
- 底部悬浮操作栏：下载 / 移动 / 复制 / 删除 / 更多
- 移动与复制进入目录选择页，来源目录、其自身及下级均禁止作为目标

**批量重命名**

- 五种方式：查找替换、添加前后缀、序号编号、大小写转换、修改扩展名（仅文件）
- 实时预览「原名 → 新名」，应用按钮写明「应用（N 项可用）」
- 冲突在预览阶段拦截：目标名已存在 / 批内重名 / 批内链式或互换 / 清洗后为空
- 逐项执行、受限并发 3；单项失败不中断整批，失败项保留选中便于重试

## 问题修复

- 删除账户与切换账户此前只做单向互斥，会让已删除账户被写回索引（僵尸账户）
- 批量移动 / 复制可以把目标目录选成来源目录自身（`dst == src`）
- 批量重命名漏判批内链式（A→B 且 B→C）与互换（A↔B）冲突，并发下发会撞名覆盖
- 账户被删除后，传输任务仍可能继续向该账户目录写入文件
- Windows 便携版数据文件读取失败后会把空数据写回磁盘，导致账户与配置被清空
- Windows 便携版写盘原先「先删除再重命名」，中间存在数据文件不存在的空窗
- 下载失败会删除目标文件，可能销毁用户下载前就存在的同名文件
- 上传入口未捕获异常且用 `files.single` 取值，选择器异常时无任何提示
- 目录列表排序不稳定，导致批量重命名的序号在刷新后错位
- 批量下载展开文件夹时读取失败的目录被静默忽略，任务数与实际不符
- 批量操作在异步分片之间未校验页面挂载，切账户后仍对旧账户发起写操作
- 下载目录兜底路径与设置页「恢复默认」口径不一致（清除本地数据后会错位）
- macOS 沙箱缺少出站网络权限，导致无法连接服务器
- 切换目录或返回键残留「幽灵选中」，操作栏按钮可点但静默空转
- 网络抖动被误判为「登录已失效」；现在只有 401 / 403 才标记失效

## 破坏性变更

1. 批量重命名不再支持同一批内的链式与互换重命名（会命中冲突检测被拦截，请分两批执行）
2. Windows 便携版：数据文件读取失败时本次会话不再写盘（此前会写回空数据并清空配置）
3. `FoxelApiException` 增加 `statusCode`；凭证失效判定只认 401 / 403
4. 文件页长按语义变更：长按进入多选模式并选中该项，单条目操作请用条目右侧「⋯」

## 已知问题

1. Android：API 24–32 访问公共 `Download` 目录未做运行时权限申请
2. Android：全局允许明文 HTTP（自建服务 / 自签证书场景）；`MANAGE_EXTERNAL_STORAGE` 存在合规风险
3. Android：未配置签名密钥时 release 构建回退 debug 签名（可安装、不可上架）
4. iOS / macOS：仓库未提交 `Podfile`（CI 由 Flutter 自动生成），本地开发需先 `flutter create --platforms=ios,macos .`
5. Linux：产物未内嵌版本元数据；Web 目录存在但**不是受支持平台**
6. 批量下载大文件夹时传输队列暂无全局并发上限
7. 单次批量操作上限 200 项；批量重命名同一批只支持一种方式
8. 扫码添加目前复用登录页；账户级密码 / 生物识别锁未实现

> 完整说明：`docs/Foxel-v1.0.5-release-note.md` · 设计稿：`docs/foxel-account-design.html` · 项目说明：`README.md`

**测试服务端**：`https://demo.foxel.cc`（用户名 / 密码均为 `admin`）
