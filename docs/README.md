# Foxel 客户端 · 项目介绍

> 一个**多账户完全隔离**的私有云盘客户端，覆盖 Android / iOS / Windows / macOS / Linux。
> 当前版本 **v1.0.2**。

---

## 一、项目是什么

Foxel 客户端连接自建的 Foxel 服务端（如 `https://demo.foxel.cc`），用于浏览、上传、下载、播放服务器上的文件。

与常见云盘客户端不同，它把「**账户**」当作一等公民：**每个账户都是一套独立沙箱**——独立登录态、独立下载目录、独立传输队列、独立浏览位置、独立媒体缓存。你可以同时挂着私人服务器、团队服务器、NAS，互不干扰，随时一键切换。

<p align="center">
  <img src="foxel-design-overview.svg" alt="Foxel 设计规范总览" width="680">
</p>

> 上图为设计规范总览（配色 / 圆角 / 字号 / 页面地图 / 导航规范）。
> 完整可交互设计稿见 **[foxel-account-design.html](./foxel-account-design.html)**（9 个页签可切换）。

---

## 二、核心特性

| 特性 | 说明 |
|---|---|
| **多账户沙箱** | 凭证、下载目录、传输任务、浏览位置、媒体缓存五类数据按 `acc_<id>` 分区，切换账户即换指针并重建界面树 |
| **统一空态** | 全新安装或删光账户时，所有平台一致停留在「账户管理页空态」，不自动创建默认账户、不强制弹登录页 |
| **多选批量删除** | 账户管理页右上「编辑」进入多选，可勾选任意账户（含当前账户）批量删除；删空即回到空态 |
| **切换即隔离** | 切换账户中断旧账户任务（可逐账户关闭）、重建页面、恢复该账户上次浏览的位置与排序 |
| **账户级下载目录** | 默认目录优先使用**显示名称**（未填写时用账户 ID），支持系统目录浏览（桌面返回真实路径、Android 走 SAF）、可写校验与权限引导 |
| **Windows 便携版** | 数据写在 `<程序目录>/userdata/prefs.json`，**删除程序目录 = 清空数据**，不污染系统 AppData |
| **可靠的删除语义** | 删除账户立即退出其登录态；只移植一次的旧版本会话迁移 + 残留键幂等清理，杜绝「删了又复活」 |
| **桌面端适配** | 宽屏内容最大宽度 720 居中，与移动端版式一致 |

---

## 三、界面与设计图

设计稿共 **9 页**，与实现一一对应：

| 设计稿页面 | 覆盖内容 | 对应实现 |
|---|---|---|
| ① 概览与规范 | 设计令牌（配色 / 圆角 / 间距 / 字号）、导航流向 | `lib/core/theme/design_tokens.dart` |
| ② 账户管理页 | 常规态（点选即切换）、多选删除、批量确认 | `features/accounts/pages/account_center_page.dart` |
| ③ 空态与添加账户 | 唯一空态、手动添加、扫码添加 | 同上（`asRoot` 空态）+ `features/auth/pages/login_page.dart` |
| ④ 编辑账户 | 显示名称 / 服务器地址 / 四项隔离开关 / 危险操作 | `features/accounts/pages/account_form_page.dart` |
| ⑤ 设置页与下载目录 | 当前账户卡、账户管理入口、存储用量、下载目录弹层（含「浏览...」） | `features/settings/pages/settings_page.dart` |
| ⑥ 主界面与底部导航 | 文件页账户条、底部导航尺寸 / 间距 / 阴影规范 | `features/drive/pages/drive_shell_page.dart` |
| ⑦ 隔离与存储 | 全局层与账户沙箱划分、各平台数据位置 | `core/storage/account_store.dart` 等 |
| ⑧ 异常与确认 | 账户失效、切换中、删除确认 | `lib/app/app_root.dart` |
| ⑨ 范围与规划 | 已落地能力与后续规划 | — |

**设计规范要点**

- 主色 `#4C6FFF`，背景 `#F4F7FA`，卡片白底 + `#E7ECF2` 描边
- 文字三级：`#16202C` → `#5C6B7A` → `#93A0AF`
- 圆角：卡片 20 · 瓦片/按钮 16 · 字段 14 · 导航 22 · 选中段 15
- 页面标题 21 w800 · 分组标题 12 w800 · 列表标题 14.5 w700 · 胶囊 11 w800
- 底部导航：胶囊高 74、段间距 14、图标 20px、阴影 `blur 14 / offset (0,6) / 10%`

---

## 四、数据隔离模型

**全局层（唯一）**

- `foxel_accounts_index`：账户索引（id / 别名 / 服务器 / 头像）
- `foxel_active_account_id`：当前账户指针
- `foxel_migration_v2_done`：旧版本迁移只执行一次的标记

**账户沙箱（每账户一份）**

| 维度 | 存储 key / 位置 | 用户可见效果 |
|---|---|---|
| 登录凭证 | `foxel_acc_<id>_token` | 切换不乱登录态 |
| 下载目录 | `foxel_acc_<id>_download_dir` | 不同账户文件不混放 |
| 传输队列 | 按账户持有控制器 | 任务列表只显示当前账户 |
| 浏览位置 | `foxel_acc_<id>_browse_state` | 切回恢复上次目录与排序 |
| 媒体缓存 | `foxel_acc_<id>_vp_<hash>` | 删账户可彻底清干净 |

四项隔离开关（`独立下载目录 / 独立传输队列 / 记住浏览位置 / 独立媒体缓存`）按账户生效，关闭后该账户与其他关闭该开关的账户共用对应资源。

**各平台数据位置**

| 平台 | 位置 |
|---|---|
| Android / iOS | 应用私有目录（卸载即清除） |
| Windows | `<程序目录>/userdata/prefs.json`（便携，删程序即清空） |
| macOS / Linux | 系统应用支持目录 |

---

## 五、技术栈

- **框架**：Flutter（Material 3），Dart SDK ≥ 3.11
- **网络**：`http`，自研 `FoxelApi`（JWT，`access_token`）
- **存储**：`shared_preferences`（Windows 上替换为自研 `PortablePrefsStore`，JSON 原子写 + 写队列）
- **媒体**：`media_kit` / `media_kit_video`
- **相机 / 扫码**：`camera` + `zxing2` + `image`
- **文件**：`file_picker`、`open_filex`、`path_provider`
- **CI**：GitHub Actions（`analyze.yml` 静态检查 + 单测；`build.yml` 五平台构建）

---

## 六、目录结构

```
lib/
├─ app/
│  ├─ app.dart              # 全局主题（按钮 / 输入框 / AppBar / 对话框统一）
│  └─ app_root.dart         # 根组件：账户会话、切换、增删、状态推送
├─ core/
│  ├─ api/                  # FoxelApi、二维码登录
│  ├─ models/               # Account、AccountsSnapshot、IsolationPolicy…
│  ├─ storage/              # account_store / download_dir_store /
│  │                        # browse_state_store / portable_prefs_store
│  ├─ theme/                # design_tokens.dart（设计令牌唯一来源）
│  └─ widgets/              # ContentFrame（桌面端宽度收敛）
└─ features/
   ├─ accounts/             # 账户管理页、账户表单、头像
   ├─ auth/                 # 添加账户 / 扫码
   ├─ drive/                # 文件浏览、传输任务、底部导航壳
   ├─ media/                # 视频播放与进度
   └─ settings/             # 设置页
```

---

## 七、构建与发布

**本地构建**

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --split-per-abi       # Android
flutter build windows --release         # Windows
```

**CI 产物**

| 工作流 | 产出 |
|---|---|
| `analyze.yml` | `flutter analyze` + `flutter test`（含账户管理页组件测试） |
| `build.yml` | Android APK（3 个 ABI）、Windows、Linux、macOS、iOS（未签名） |

**v1.0.2 发布产物**

- `Foxel-windows-portable.zip`：Windows 便携版，解压即用
- `app-arm64-v8a-release.apk` / `app-armeabi-v7a-release.apk` / `app-x86_64-release.apk`

---

## 八、快速开始

1. 启动应用（无账户时停在账户管理页空态）
2. 点「添加账户」→ 填入服务器地址（如 `https://demo.foxel.cc`）、账号、密码 → 「验证并添加」
3. 添加成功即自动登录并切换到该账户；之后可在「设置 → 账户管理」中切换、编辑、删除

> 测试账号：`demo.foxel.cc`，用户名 / 密码均为 `admin`

---

## 九、已知限制与后续规划

- 扫码添加目前复用登录页（标题「添加账户」），尚未做独立页面
- 「清除本地数据 / 移除账户」不会删除已下载到磁盘的文件（避免误删用户资料）
- 账户级密码 / 生物识别锁：预留未实现
- 网络图片缓存尚未按账户分区

---

## 十、版本发布记录

| 版本 | 时间 | 说明 |
|---|---|---|
| **v1.0.2** | 2026-10-16 | 账户体系设计定稿；多选批量删除；导航点击异常阴影修复；下载目录默认名优先显示名称；发版前两轮代码审查共修复 20+ 项缺陷（并发写、状态竞态、隔离开关生效、生命周期守卫等） |
| v1.0.0 | 2026-09-16 | 首个公开版本：多账户创建 / 切换、文件浏览与传输 |

---

<p align="center"><sub>Foxel 客户端 · 设计稿与文档随版本一同发布</sub></p>
