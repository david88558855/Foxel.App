import 'package:flutter/material.dart';

import 'package:foxel/core/models/account.dart';
import 'package:foxel/core/storage/download_dir_store.dart';
import 'package:foxel/features/accounts/widgets/account_avatar.dart';

/// 账户中心：当前账户卡 + 其他账户列表 + 数据隔离概览 + 本账户设置。
class AccountCenterPage extends StatefulWidget {
  const AccountCenterPage({
    super.key,
    required this.accounts,
    required this.activeId,
    required this.runningTaskCounts,
    required this.onSwitchAccount,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onRemoveAccount,
    required this.onClearLocalData,
    required this.onOpenSwitcher,
  });

  final List<Account> accounts;
  final String? activeId;
  final Map<String, int> runningTaskCounts;
  final ValueChanged<Account> onSwitchAccount;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final ValueChanged<Account> onRemoveAccount;
  final ValueChanged<Account> onClearLocalData;
  final VoidCallback onOpenSwitcher;

  @override
  State<AccountCenterPage> createState() => _AccountCenterPageState();
}

class _AccountCenterPageState extends State<AccountCenterPage> {
  String? _downloadDir;

  Account? get _active {
    final id = widget.activeId;
    for (final account in widget.accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return widget.accounts.isEmpty ? null : widget.accounts.first;
  }

  @override
  void initState() {
    super.initState();
    _loadDownloadDir();
  }

  @override
  void didUpdateWidget(covariant AccountCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) {
      _loadDownloadDir();
    }
  }

  Future<void> _loadDownloadDir() async {
    final active = _active;
    if (active == null) {
      return;
    }
    final dir = await DownloadDirStore.currentDirFor(active.id);
    if (mounted) {
      setState(() => _downloadDir = dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final others = <Account>[
      for (final account in widget.accounts) if (account.id != active?.id) account,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 126),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '账户',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '共 ${widget.accounts.length} 个账户',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF93A0AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: widget.onAddAccount,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '添加账户',
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (active != null) ...[
              _CurrentAccountCard(
                account: active,
                runningTasks: widget.runningTaskCounts[active.id] ?? 0,
                onEdit: () => widget.onEditAccount(active),
                onOpenSwitcher: widget.onOpenSwitcher,
              ),
              const SizedBox(height: 16),
              _SectionLabel(text: otherLabel(others.length)),
              const SizedBox(height: 8),
              if (others.isEmpty)
                const _EmptyHint(text: '还没有其他账户，添加后可一键切换')
              else
                _Group(
                  children: [
                    for (final account in others)
                      _AccountTile(
                        account: account,
                        runningTasks: widget.runningTaskCounts[account.id] ?? 0,
                        onTap: () => widget.onSwitchAccount(account),
                        onEdit: () => widget.onEditAccount(account),
                        onRemove: () => widget.onRemoveAccount(account),
                        onClearLocalData: () =>
                            widget.onClearLocalData(account),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              _SectionLabel(text: '数据隔离'),
              const SizedBox(height: 8),
              _IsolationOverview(account: active),
              const SizedBox(height: 16),
              _SectionLabel(text: '本账户设置'),
              const SizedBox(height: 8),
              _Group(
                children: [
                  _SettingsRow(
                    icon: Icons.folder_rounded,
                    title: '下载目录',
                    subtitle: _downloadDir ?? '加载中',
                    onTap: () => _editDownloadDir(active),
                  ),
                  _SettingsRow(
                    icon: Icons.add_rounded,
                    title: '添加账户',
                    subtitle: '手动输入或扫码登录',
                    onTap: widget.onAddAccount,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(text: '危险操作'),
              const SizedBox(height: 8),
              _Group(
                children: [
                  _SettingsRow(
                    icon: Icons.cleaning_services_rounded,
                    title: '清除本地数据',
                    subtitle: '删除缓存与下载目录配置，保留账户',
                    warning: true,
                    onTap: () => widget.onClearLocalData(active),
                  ),
                  _SettingsRow(
                    icon: Icons.person_remove_rounded,
                    title: '移除此账户',
                    subtitle: '本地数据与登录态一并删除',
                    destructive: true,
                    onTap: () => widget.onRemoveAccount(active),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '移除账户不会影响服务器上的文件',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF93A0AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else
              const _EmptyHint(text: '还没有账户，点击右上角添加第一个'),
          ],
        ),
      ),
    );
  }

  static String otherLabel(int count) {
    return count == 0 ? '其他账户' : '其他账户 ($count)';
  }

  Future<void> _editDownloadDir(Account account) async {
    final current =
        _downloadDir ?? await DownloadDirStore.currentDirFor(account.id);
    final defaultDir = await DownloadDirStore.defaultDirFor(account.id);
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('下载目录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '下载目录完整路径',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '默认：$defaultDir',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF93A0AF),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                DownloadDirStore.resetDirFor(account.id);
                Navigator.of(dialogContext).pop('');
              },
              child: const Text('恢复默认'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (result == null) {
      return;
    }
    if (result.isEmpty) {
      await DownloadDirStore.resetDirFor(account.id);
    } else {
      final writable = await DownloadDirStore.isWritable(result);
      if (!writable && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该目录不可写入')));
        return;
      }
      await DownloadDirStore.setDirFor(account.id, result);
    }
    await _loadDownloadDir();
  }
}

class _CurrentAccountCard extends StatelessWidget {
  const _CurrentAccountCard({
    required this.account,
    required this.runningTasks,
    required this.onEdit,
    required this.onOpenSwitcher,
  });

  final Account account;
  final int runningTasks;
  final VoidCallback onEdit;
  final VoidCallback onOpenSwitcher;

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccountAvatar(account: account, size: 56, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.accountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF93A0AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.hostLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF93A0AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  account.isStale ? '需重新验证' : '使用中',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: account.isStale ? const Color(0xFFF59E0B) : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(
                label: '传输中',
                value: '$runningTasks',
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: '上次使用',
                  value: _formatLastUsed(account.lastUsedAt),
                  color: const Color(0xFF93A0AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenSwitcher,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('切换'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF93A0AF)),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.runningTasks,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
    required this.onClearLocalData,
  });

  final Account account;
  final int runningTasks;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onClearLocalData;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: AccountAvatar(account: account, size: 40),
      title: Text(
        account.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${account.hostLabel} · ${_formatLastUsed(account.lastUsedAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: account.isStale
              ? const Color(0xFFF59E0B)
              : const Color(0xFF93A0AF),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (account.isStale)
            const _Tag(text: '失效', color: Color(0xFFF59E0B))
          else if (runningTasks > 0)
            _Tag(text: '$runningTasks 传输', color: const Color(0xFF93A0AF)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'clear') {
                onClearLocalData();
              } else if (value == 'remove') {
                onRemove();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑账户')),
              PopupMenuItem(value: 'clear', child: Text('清除本地数据')),
              PopupMenuItem(value: 'remove', child: Text('移除账户')),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _IsolationOverview extends StatelessWidget {
  const _IsolationOverview({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return _Group(
      children: [
        _IsolationRow(
          icon: Icons.key_rounded,
          title: '登录凭证',
          subtitle: '每个账户独立保存，互不影响',
          enabled: true,
        ),
        _IsolationRow(
          icon: Icons.folder_copy_rounded,
          title: '下载目录',
          subtitle: 'Foxel/${account.id}',
          enabled: account.isolatedDownloadDir,
        ),
        _IsolationRow(
          icon: Icons.sync_alt_rounded,
          title: '传输任务',
          subtitle: '切换账户时中断本账户任务',
          enabled: account.isolatedTasks,
        ),
        _IsolationRow(
          icon: Icons.history_rounded,
          title: '浏览位置',
          subtitle: '切回时恢复上次目录与排序',
          enabled: account.rememberBrowseState,
        ),
        _IsolationRow(
          icon: Icons.image_rounded,
          title: '媒体缓存',
          subtitle: '播放进度等随账户清理',
          enabled: account.isolatedCache,
        ),
      ],
    );
  }
}

class _IsolationRow extends StatelessWidget {
  const _IsolationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon, size: 20, color: const Color(0xFF5C6B7A)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF93A0AF)),
      ),
      trailing: Icon(
        enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
        size: 20,
        color: enabled ? const Color(0xFF12B886) : const Color(0xFFB6C0CD),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF93A0AF),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFE5484D)
        : warning
        ? const Color(0xFFF59E0B)
        : const Color(0xFF5C6B7A);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: destructive || warning ? color : const Color(0xFF16202C),
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF93A0AF)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF2), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF93A0AF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF93A0AF)),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatLastUsed(DateTime? time) {
  if (time == null) {
    return '从未使用';
  }
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) {
    return '刚刚';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} 分钟前';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} 小时前';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} 天前';
  }
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}
