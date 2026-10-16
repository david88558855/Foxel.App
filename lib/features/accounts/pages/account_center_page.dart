import 'package:flutter/material.dart';

import 'package:foxel/core/models/account.dart';
import 'package:foxel/features/accounts/widgets/account_avatar.dart';

/// 账户管理页。
///
/// - 有账户时：从「设置 → 账户管理」进入的独立二级页（AppBar 返回 + 右上「+」），
///   点击列表项即切换账户。
/// - 无账户时：作为启动首页呈现唯一空态（居中引导 + 添加账户 / 扫码添加），
///   此时不显示返回按钮与底部导航。
class AccountCenterPage extends StatelessWidget {
  const AccountCenterPage({
    super.key,
    required this.accounts,
    required this.activeId,
    required this.runningTaskCounts,
    required this.onSwitchAccount,
    required this.onAddAccount,
    required this.onAddManually,
    required this.onAddByQr,
    required this.onEditAccount,
    required this.onRemoveAccount,
    this.asRoot = false,
  });

  final List<Account> accounts;
  final String? activeId;
  final Map<String, int> runningTaskCounts;

  /// 切换账户；返回 true 表示切换成功。
  final Future<bool> Function(Account account) onSwitchAccount;

  /// 打开「添加账户」方式选择（手动 / 扫码）。
  final VoidCallback onAddAccount;
  final VoidCallback onAddManually;
  final VoidCallback onAddByQr;
  final ValueChanged<Account> onEditAccount;
  final ValueChanged<Account> onRemoveAccount;

  /// 无账户启动时以根页面形态呈现。
  final bool asRoot;

  Account? get _active {
    final id = activeId;
    for (final account in accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return accounts.isEmpty ? null : accounts.first;
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    if (active == null) {
      return _EmptyState(
        asRoot: asRoot,
        onAddManually: onAddManually,
        onAddByQr: onAddByQr,
      );
    }

    final others = <Account>[
      for (final account in accounts)
        if (account.id != active.id) account,
    ];

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        _CurrentAccountCard(
          account: active,
          runningTasks: runningTaskCounts[active.id] ?? 0,
          onEdit: () => onEditAccount(active),
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          text: others.isEmpty ? '其他账户' : '其他账户 · 点选即切换 (${others.length})',
        ),
        const SizedBox(height: 8),
        if (others.isEmpty)
          const _EmptyHint(text: '还没有其他账户，添加后可在这里切换')
        else
          _Group(
            children: [
              for (final account in others)
                _AccountTile(
                  account: account,
                  runningTasks: runningTaskCounts[account.id] ?? 0,
                  onTap: () => _handleSwitch(context, account),
                  onEdit: () => onEditAccount(account),
                  onRemove: () => onRemoveAccount(account),
                ),
            ],
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onAddAccount,
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加账户'),
        ),
        const SizedBox(height: 10),
        const Text(
          '点选账户即切换；切换后本账户的下载目录、任务与缓存与其他账户互相隔离。',
          style: TextStyle(
            fontSize: 11.5,
            color: Color(0xFF93A0AF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (asRoot) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: SafeArea(child: body),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('账户管理'),
        backgroundColor: const Color(0xFFF4F7FA),
        actions: [
          IconButton(
            onPressed: onAddAccount,
            icon: const Icon(Icons.add_rounded),
            tooltip: '添加账户',
          ),
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  Future<void> _handleSwitch(BuildContext context, Account account) async {
    final ok = await onSwitchAccount(account);
    if (!ok || !context.mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

/// 唯一空态：无账户时的启动页与账户管理页空态。
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.asRoot,
    required this.onAddManually,
    required this.onAddByQr,
  });

  final bool asRoot;
  final VoidCallback onAddManually;
  final VoidCallback onAddByQr;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (asRoot) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '账户',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '还没有账户',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF93A0AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 34,
                      color: Color(0xFF4C6FFF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '还没有账户',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '添加第一个 Foxel 服务器\n即可开始管理文件',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF93A0AF),
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 230,
                    child: Column(
                      children: [
                        FilledButton(
                          onPressed: onAddManually,
                          child: const Text('添加账户'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: onAddByQr,
                          child: const Text('扫码添加'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: content,
        ),
      ),
    );
  }
}

class _CurrentAccountCard extends StatelessWidget {
  const _CurrentAccountCard({
    required this.account,
    required this.runningTasks,
    required this.onEdit,
  });

  final Account account;
  final int runningTasks;
  final VoidCallback onEdit;

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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('编辑账户信息'),
            ),
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
  });

  final Account account;
  final int runningTasks;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

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
              } else if (value == 'remove') {
                onRemove();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑账户')),
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
        border: Border.all(color: const Color(0xFFE7ECF2)),
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
