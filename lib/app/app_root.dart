import 'dart:async';

import 'package:flutter/material.dart';

import 'package:foxel/core/api/foxel_api.dart';
import 'package:foxel/core/models/account.dart';
import 'package:foxel/core/models/accounts_snapshot.dart';
import 'package:foxel/core/models/session.dart';
import 'package:foxel/core/theme/design_tokens.dart';
import 'package:foxel/core/storage/portable_prefs_store.dart';
import 'package:foxel/core/storage/account_store.dart';
import 'package:foxel/core/storage/download_dir_store.dart';
import 'package:foxel/features/accounts/pages/account_center_page.dart';
import 'package:foxel/features/accounts/pages/account_form_page.dart';
import 'package:foxel/features/auth/pages/login_page.dart';
import 'package:foxel/features/drive/controllers/transfer_task_controller.dart';
import 'package:foxel/features/drive/pages/drive_shell_page.dart';

/// 应用根：管理账户索引、当前账户与切换。
///
/// 全局只持有「账户列表 + 当前指针」，每个账户的数据（凭证 / 下载目录 /
/// 传输任务 / 浏览状态 / 缓存）都落在各自的沙箱里。
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _store = AccountStore();
  final _taskControllers = <String, TransferTaskController>{};
  final _shellKey = GlobalKey<DriveShellPageState>();

  /// 账户状态通知源：让 push 出来的账户管理页也能实时刷新
  /// （push 的路由不会随 AppRoot 重建）。
  final _snapshot = ValueNotifier<AccountsSnapshot>(AccountsSnapshot.empty);

  List<Account> _accounts = <Account>[];
  Account? _active;
  FoxelApi? _api;
  bool _loading = true;
  bool _switching = false;
  String _lastBaseUrl = '';

  @override
  void initState() {
    super.initState();
    // 双保险：确保首次读取账户数据前便携版路径已生效（插件此刻必定已注册）。
    PortableStorage.ensureConfigured();
    _bootstrap();
  }

  @override
  void dispose() {
    _api?.close();
    for (final controller in _taskControllers.values) {
      controller.dispose();
    }
    _snapshot.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final accounts = await _store.loadAccounts();
      if (accounts.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() => _loading = false);
        return;
      }

      var active = await _store.activeAccount() ?? accounts.first;
      _lastBaseUrl = active.baseUrl;
      final verified = await _verify(active);
      if (verified != null) {
        await _store.upsert(verified);
        active = verified;
      } else {
        await _store.markStale(active.id, stale: true);
        active = active.copyWith(isStale: true);
      }

      await _reload();
      if (!mounted) {
        return;
      }
      setState(() {
        _active = active;
        _api = FoxelApi(baseUrl: active.baseUrl, token: active.token);
        _loading = false;
      });
      _publishAccounts();
    } catch (error) {
      // 存储不可用（例如便携目录不可写）时也要退出加载态，避免白屏卡死。
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage('初始化账户数据失败：$error');
    }
  }

  /// 校验账户凭证，成功返回刷新后的账户，失败返回 null。
  Future<Account?> _verify(Account account) async {
    final api = FoxelApi(baseUrl: account.baseUrl, token: account.token);
    try {
      final profile = await api.me();
      return account.copyWith(
        username: profile.username.isEmpty
            ? account.username
            : profile.username,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
        isStale: false,
        lastUsedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    } finally {
      api.close();
    }
  }

  Future<void> _reload() async {
    _accounts = await _store.loadAccounts();
    _publishAccounts();
  }

  /// 推送最新账户状态（账户管理页订阅此通知）。
  void _publishAccounts() {
    _snapshot.value = AccountsSnapshot(
      accounts: List<Account>.unmodifiable(_accounts),
      activeId: _active?.id,
      runningTaskCounts: _runningTaskCounts(),
    );
  }

  /// 切换到目标账户：校验 → 中断旧账户任务 → 换指针 → 重建界面。
  Future<void> _switchTo(String accountId) async {
    if (_switching) {
      return;
    }
    final current = _active;
    if (current != null && current.id == accountId) {
      return;
    }
    Account? target;
    for (final account in _accounts) {
      if (account.id == accountId) {
        target = account;
      }
    }
    if (target == null) {
      return;
    }

    setState(() => _switching = true);
    final verified = await _verify(target);
    if (!mounted) {
      return;
    }

    if (verified == null) {
      await _store.markStale(target.id, stale: true);
      await _reload();
      if (!mounted) {
        return;
      }
      setState(() => _switching = false);
      _showMessage('「${target.displayName}」登录已失效，请重新验证');
      return;
    }

    if (current != null) {
      _taskControllers[current.id]?.interruptAll('已因切换账户中断');
    }

    await _store.upsert(verified);
    await _store.setActiveId(verified.id);
    await _store.touch(verified.id);
    await _reload();
    _lastBaseUrl = verified.baseUrl;
    _api?.close();

    if (!mounted) {
      return;
    }
    setState(() {
      _active = verified;
      _api = FoxelApi(baseUrl: verified.baseUrl, token: verified.token);
      _switching = false;
    });
    _publishAccounts();
    _showMessage('已切换到「${verified.displayName}」，数据与其他账户隔离');
  }

  /// 打开「账户管理」独立页（设置页内的入口）。
  Future<void> _openAccountCenter() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountCenterPage(
          snapshot: _snapshot,
          onSwitchAccount: _switchFromAccountCenter,
          onAddAccount: _openAddAccount,
          onAddManually: _openManualAdd,
          onAddByQr: _openQrAdd,
          onEditAccount: _openEditAccount,
          onRemoveAccounts: _confirmRemoveAccounts,
        ),
      ),
    );
  }

  /// 账户管理页内点选账户：切换成功后回到主界面的「文件」页。
  Future<bool> _switchFromAccountCenter(Account account) async {
    await _switchTo(account.id);
    final switched = _active?.id == account.id;
    if (switched) {
      _shellKey.currentState?.selectTab(0);
    }
    return switched;
  }

  Map<String, int> _runningTaskCounts() {
    final counts = <String, int>{};
    for (final entry in _taskControllers.entries) {
      var running = 0;
      for (final task in entry.value.tasks.value) {
        if (task.status == TransferTaskStatus.running) {
          running++;
        }
      }
      counts[entry.key] = running;
    }
    return counts;
  }

  Future<void> _openAddAccount() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.keyboard_rounded),
                title: const Text('手动输入'),
                subtitle: const Text('填写服务器地址与账号密码'),
                onTap: () => Navigator.of(sheetContext).pop('manual'),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('扫码添加'),
                subtitle: const Text('扫描网页端账户二维码'),
                onTap: () => Navigator.of(sheetContext).pop('qr'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'manual') {
      await _openManualAdd();
    } else {
      await _openQrAdd();
    }
  }

  Future<void> _openManualAdd() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountFormPage(
          onSave: (account, {bool switchAfterAdd = true}) async {
            await _addAccount(account, switchAfterAdd: switchAfterAdd);
          },
        ),
      ),
    );
  }

  Future<void> _openQrAdd() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(
          initialBaseUrl: _lastBaseUrl,
          onLoggedIn: (session) {
            unawaited(_handleNewSession(session));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// 保存新账户（可来自手动表单或扫码）。
  Future<void> _addAccount(
    Account account, {
    bool switchAfterAdd = true,
  }) async {
    final existing = _findDuplicate(account);
    final saved = existing == null
        ? account
        : existing.copyWith(
            token: account.token,
            email: account.email,
            avatarUrl: account.avatarUrl,
            username: account.username,
            isStale: false,
          );

    await _store.upsert(saved);
    await _reload();
    // 新建账户的默认下载目录：优先显示名称，未填写时用账户 ID。
    await _ensureDefaultDownloadDir(saved, isNew: existing == null);
    if (!mounted) {
      return;
    }
    setState(() {});

    if (switchAfterAdd) {
      await _switchTo(saved.id);
    } else {
      _showMessage('已添加「${saved.displayName}」');
    }
  }

  /// 为新账户落定默认下载目录（已有设置不覆盖，避免下载文件「搬家」）。
  Future<void> _ensureDefaultDownloadDir(
    Account account, {
    required bool isNew,
  }) async {
    if (!isNew) {
      return;
    }
    if (await DownloadDirStore.hasCustomDirFor(account.id)) {
      return;
    }
    final folderName = DownloadDirStore.sanitizeFolderName(account.alias);
    final duplicated =
        folderName.isNotEmpty &&
        _accounts.any(
          (item) =>
              item.id != account.id &&
              DownloadDirStore.sanitizeFolderName(item.alias) == folderName,
        );
    final shortId = account.id.length > 6
        ? account.id.substring(account.id.length - 6)
        : account.id;
    final dir = await DownloadDirStore.defaultDirForAccount(
      account,
      disambiguator: duplicated ? shortId : null,
    );
    if (dir.isNotEmpty) {
      await DownloadDirStore.setDirFor(account.id, dir);
    }
  }

  Account? _findDuplicate(Account account) {
    for (final item in _accounts) {
      if (item.id != account.id &&
          item.baseUrl == account.baseUrl &&
          item.username == account.username) {
        return item;
      }
    }
    return null;
  }

  /// 扫码 / 首个账户登录：把会话包装成一个新账户。
  Future<void> _handleNewSession(FoxelSession session) async {
    final normalized = FoxelApi.normalizeBaseUrl(session.baseUrl);
    final account = Account(
      id: Account.generateId(),
      alias: '',
      baseUrl: normalized,
      username: session.username,
      token: session.token,
      email: session.email,
      avatarUrl: session.avatarUrl,
      colorValue: Account.colorForIndex(_accounts.length),
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
    await _addAccount(account, switchAfterAdd: true);
  }

  Future<void> _openEditAccount(Account account) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountFormPage(
          account: account,
          onSave: (updated, {bool switchAfterAdd = false}) async {
            await _store.upsert(updated);
            await _reload();
            if (!mounted) {
              return;
            }
            setState(() {
              if (_active?.id == updated.id) {
                _active = updated;
                // 服务器地址或凭证变化后必须重建客户端，否则仍在访问旧地址。
                _api?.close();
                _api = FoxelApi(
                  baseUrl: updated.baseUrl,
                  token: updated.token,
                );
                _lastBaseUrl = updated.baseUrl;
              }
            });
            _publishAccounts();
            _showMessage('已保存「${updated.displayName}」');
          },
          onLogout: () async {
            await _store.updateToken(account.id, '');
            await _store.markStale(account.id, stale: true);
            await _reload();
            if (!mounted) {
              return;
            }
            setState(() {
              if (_active?.id == account.id) {
                _active = _active?.copyWith(token: '', isStale: true);
                // 凭证已清空：必须重建客户端，否则界面仍在用旧 token 请求。
                _api?.close();
                _api = FoxelApi(
                  baseUrl: _active?.baseUrl ?? account.baseUrl,
                  token: '',
                );
              }
            });
            _publishAccounts();
            _showMessage('已退出「${account.displayName}」，可重新验证');
          },
        ),
      ),
    );
  }

  /// 批量移除账户（单个删除也走这里）；返回 true 表示已删除。
  ///
  /// 删除当前账户时立即退出其登录态：切到剩余账户，没有则回到空态，
  /// 校验放到后台进行，避免界面停留在已删除的账户上。
  Future<bool> _confirmRemoveAccounts(List<Account> accounts) async {
    if (accounts.isEmpty) {
      return false;
    }
    final isBatch = accounts.length > 1;
    final names = accounts.map((item) => '「${item.displayName}」').join('、');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isBatch
                ? '删除 ${accounts.length} 个账户？'
                : '移除账户${names}？',
          ),
          content: Text(
            '将删除 $names 的登录状态、下载目录配置、传输记录与本地缓存。\n'
            '服务器上的文件不受影响，此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isBatch ? '删除 ${accounts.length} 项' : '移除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return false;
    }

    final ids = accounts.map((item) => item.id).toList();
    final removingActive = ids.contains(_active?.id);

    // 1) 清除存储中的账户与其沙箱数据（串行执行，避免索引互相覆盖）
    await _store.removeAll(ids);
    // 2) 释放这些账户的传输任务
    for (final id in ids) {
      _taskControllers.remove(id)?.dispose();
    }
    await _reload();

    if (!mounted) {
      return true;
    }

    final summary = isBatch ? '已删除 ${accounts.length} 个账户' : '已移除$names';

    if (!removingActive) {
      setState(() {});
      _publishAccounts();
      _showMessage(summary);
      return true;
    }

    // 3) 当前账户被删除：立刻离开其登录态
    _api?.close();
    final next = await _store.activeAccount();
    if (!mounted) {
      return true;
    }
    setState(() {
      _active = next;
      _api = next == null
          ? null
          : FoxelApi(baseUrl: next.baseUrl, token: next.token);
    });
    _publishAccounts();

    if (next == null) {
      _showMessage(summary);
      return true;
    }

    _showMessage('$summary，已切换到「${next.displayName}」');
    unawaited(_validateActive());
    return true;
  }

  /// 后台校验当前账户，失败则标记为失效（不阻塞界面切换）。
  Future<void> _validateActive() async {
    final current = _active;
    if (current == null) {
      return;
    }
    final verified = await _verify(current);
    if (!mounted) {
      return;
    }
    if (verified != null) {
      await _store.upsert(verified);
      await _reload();
      if (!mounted) {
        return;
      }
      setState(() {
        if (_active?.id == verified.id) {
          _active = verified;
          _api?.close();
          _api = FoxelApi(baseUrl: verified.baseUrl, token: verified.token);
        }
      });
      _publishAccounts();
      return;
    }
    await _store.markStale(current.id, stale: true);
    await _reload();
    if (!mounted) {
      return;
    }
    setState(() {
      if (_active?.id == current.id) {
        _active = _active?.copyWith(isStale: true);
      }
    });
    _publishAccounts();
  }

  Future<void> _confirmClearLocalData(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清除本地数据'),
          content: Text(
            '将删除「${account.displayName}」在本机的下载目录配置、浏览位置与播放进度，'
            '登录状态保留。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('清除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    _taskControllers[account.id]?.clearFinished();
    await _store.clearLocalData(account.id);
    _showMessage('已清除「${account.displayName}」的本地数据');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final active = _active;
    final api = _api;
    if (active == null || api == null) {
      // 无账户：直接呈现账户管理页的唯一空态，不显示登录页与底部导航。
      return AccountCenterPage(
        snapshot: _snapshot,
        onSwitchAccount: (_) async => false,
        onAddAccount: _openAddAccount,
        onAddManually: _openManualAdd,
        onAddByQr: _openQrAdd,
        onEditAccount: (_) {},
        onRemoveAccounts: (_) async => false,
        asRoot: true,
      );
    }

    return Stack(
      children: [
        DriveShellPage(
          key: _shellKey,
          api: api,
          account: active,
          accountCount: _accounts.length,
          taskController: _controllerFor(active.id),
          onOpenAccountCenter: _openAccountCenter,
          onAddAccount: _openAddAccount,
          onClearLocalData: _confirmClearLocalData,
        ),
        if (_switching)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x88F4F7FA),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  TransferTaskController _controllerFor(String accountId) {
    final existing = _taskControllers[accountId];
    if (existing != null) {
      return existing;
    }
    final controller = TransferTaskController();
    _taskControllers[accountId] = controller;
    return controller;
  }
}
