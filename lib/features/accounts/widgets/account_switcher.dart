import 'package:flutter/material.dart';

import 'package:foxel/core/models/account.dart';
import 'package:foxel/features/accounts/widgets/account_avatar.dart';

/// 快速切换账户：底部半屏弹层，返回被选中的账户 ID。
class AccountSwitcher {
  static Future<String?> show({
    required BuildContext context,
    required List<Account> accounts,
    required String? activeId,
    required Map<String, int> runningTaskCounts,
    required VoidCallback onAddAccount,
    required VoidCallback onManageAccounts,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE3EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '切换账户',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onManageAccounts();
                      },
                      child: const Text('管理'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final account in accounts)
                          _SwitcherTile(
                            account: account,
                            isActive: account.id == activeId,
                            runningTasks: runningTaskCounts[account.id] ?? 0,
                            onTap: () =>
                                Navigator.of(sheetContext).pop(account.id),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.add_rounded,
                  title: '添加账户',
                  subtitle: '手动输入或扫码登录',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAddAccount();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SwitcherTile extends StatelessWidget {
  const _SwitcherTile({
    required this.account,
    required this.isActive,
    required this.runningTasks,
    required this.onTap,
  });

  final Account account;
  final bool isActive;
  final int runningTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : const Color(0xFFE7ECF2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: AccountAvatar(account: account, size: 40),
        title: Text(
          account.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          account.hostLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF93A0AF)),
        ),
        trailing: _trailing(color),
        onTap: onTap,
      ),
    );
  }

  Widget _trailing(Color color) {
    if (account.isStale) {
      return _Tag(text: '失效', color: const Color(0xFFF59E0B));
    }
    if (isActive) {
      return _Tag(text: '当前', color: color);
    }
    if (runningTasks > 0) {
      return _Tag(text: '$runningTasks 传输', color: const Color(0xFF93A0AF));
    }
    return const SizedBox.shrink();
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4C6FFF)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF93A0AF)),
        ),
        onTap: onTap,
      ),
    );
  }
}
