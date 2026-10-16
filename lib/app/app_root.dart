import 'package:flutter/material.dart';

import 'package:foxel/core/api/foxel_api.dart';
import 'package:foxel/core/models/account.dart';
import 'package:foxel/core/models/session.dart';
import 'package:foxel/core/storage/account_store.dart';
import 'package:foxel/features/accounts/pages/account_form_page.dart';
import 'package:foxel/features/accounts/widgets/account_switcher.dart';
import 'package:foxel/features/auth/pages/settings_page.dart';
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

  List<Account> _accounts = <Account>[];
  Account? _active;
  FoxelApi? _api;
  bool _loading = true;
  bool _switching = false;
  String _lastBaseUrl = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _api?.close();
    for (final controller in _taskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
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

    _accounts = await _store.loadAccounts();
    if (!mounted) {
      return;
    }
    setState(() {
      _active = active;
      _api = FoxelApi(baseUrl: active.baseUrl, token: active.token);
      _loading = false;
    });
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
  }

  /// 切换到目标账户：校验 → 中断旧账户任务 → 换指针 → 重建界面。
  Future<void> _switchTo(String accountId) async {
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
    _showMessage('已切换到「${verified.displayName}」，数据与其他账户隔离');
  }

  Future<void> _openSwitcher() async {
    final selected = await AccountSwitcher.show(
      context: context,
      accounts: _accounts,
      activeId: _active?.id,
      runningTaskCounts: _runningTaskCounts(),
      onAddAccount: _openAddAccount,
      onManageAccounts: () {
        _showMessage('可在「账户」页管理全部账户');
      },
    );
    if (selected == null) {
      return;
    }
    await _switchTo(selected);
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
        builder: (_) => SettingsPage(
          initialBaseUrl: _lastBaseUrl,
          onLoggedIn: (session) {
            _handleNewSession(session);
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
              }
            });
            _showMessage('已退出「${account.displayName}」，可重新验证');
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemove(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('移除账户「${account.displayName}」？'),
          content: const Text(
            '将删除该账户在本机的登录凭证、下载目录配置、传输记录与缓存。'
            '服务器上的文件不受影响。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await _store.remove(account.id);
    _taskControllers.remove(account.id)?.dispose();
    await _reload();

    if (!mounted) {
      return;
    }
    if (_active?.id == account.id) {
      _api?.close();
      final next = await _store.activeAccount();
      if (next == null) {
        setState(() {
          _active = null;
          _api = null;
        });
        return;
      }
      final verified = await _verify(next);
      final resolved = verified ?? next.copyWith(isStale: true);
      if (verified != null) {
        await _store.upsert(verified);
      }
      await _store.setActiveId(resolved.id);
      await _reload();
      if (!mounted) {
        return;
      }
      setState(() {
        _active = resolved;
        _api = FoxelApi(baseUrl: resolved.baseUrl, token: resolved.token);
      });
    } else {
      setState(() {});
    }
    _showMessage('已移除「${account.displayName}」');
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
      return SettingsPage(
        initialBaseUrl: _lastBaseUrl,
        onLoggedIn: (session) => _handleNewSession(session),
      );
    }

    return Stack(
      children: [
        DriveShellPage(
          key: ValueKey<String>(active.id),
          api: api,
          account: active,
          accounts: _accounts,
          taskController: _controllerFor(active.id),
          runningTaskCounts: _runningTaskCounts(),
          switching: _switching,
          onSwitchAccount: (account) => _switchTo(account.id),
          onOpenSwitcher: _openSwitcher,
          onAddAccount: _openAddAccount,
          onEditAccount: _openEditAccount,
          onRemoveAccount: _confirmRemove,
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
