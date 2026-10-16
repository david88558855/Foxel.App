import 'package:flutter/material.dart';

import 'package:foxel/core/models/account.dart';
import 'package:foxel/core/storage/download_dir_store.dart';
import 'package:foxel/features/accounts/widgets/account_avatar.dart';

/// 设置页（底部导航第三个 Tab）。
///
/// 账户管理的入口放在这里：顶部当前账户卡内嵌「账户管理」入口行，
/// 点击进入独立的账户管理页。
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.account,
    required this.accountCount,
    required this.onOpenAccountCenter,
    required this.onAddAccount,
    required this.onClearLocalData,
  });

  final Account account;
  final int accountCount;
  final VoidCallback onOpenAccountCenter;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onClearLocalData;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _downloadDir;

  @override
  void initState() {
    super.initState();
    _loadDownloadDir();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      _loadDownloadDir();
    }
  }

  Future<void> _loadDownloadDir() async {
    final dir = await DownloadDirStore.currentDirFor(widget.account.id);
    if (mounted) {
      setState(() => _downloadDir = dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.account.colorValue);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 126),
          children: [
            Text(
              '设置',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              widget.account.displayName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF93A0AF),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _CurrentAccountCard(
              account: widget.account,
              accountCount: widget.accountCount,
              onOpenAccountCenter: widget.onOpenAccountCenter,
            ),
            const SizedBox(height: 16),
            const _SectionLabel(text: '通用'),
            const SizedBox(height: 8),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.download_rounded,
                  title: '下载目录',
                  subtitle: _downloadDir ?? '加载中',
                  onTap: _editDownloadDir,
                ),
                const _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: '关于 Foxel',
                  subtitle: '版本 1.0.0',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionLabel(text: '当前账户'),
            const SizedBox(height: 8),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.cleaning_services_rounded,
                  title: '清除本地数据',
                  subtitle: '删除缓存与下载目录配置，保留账户',
                  warning: true,
                  onTap: () => widget.onClearLocalData(widget.account),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '切换账户、添加或移除账户请进入「账户管理」',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF93A0AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.add_rounded,
                  title: '添加账户',
                  subtitle: '手动输入或扫码登录',
                  onTap: widget.onAddAccount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDownloadDir() async {
    final account = widget.account;
    final current =
        _downloadDir ?? await DownloadDirStore.currentDirFor(account.id);
    final defaultDir = await DownloadDirStore.defaultDirFor(account.id);
    final controller = TextEditingController(text: current);
    if (!mounted) {
      return;
    }
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
              onPressed: () => Navigator.of(dialogContext).pop('__reset__'),
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
    if (result == '__reset__') {
      await DownloadDirStore.resetDirFor(account.id);
      await _loadDownloadDir();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已恢复默认下载目录')));
      }
      return;
    }
    if (result.trim().isEmpty) {
      return;
    }
    final writable = await DownloadDirStore.isWritable(result);
    if (!writable) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该目录不可写入')));
      }
      return;
    }
    await DownloadDirStore.setDirFor(account.id, result);
    await _loadDownloadDir();
  }
}

class _CurrentAccountCard extends StatelessWidget {
  const _CurrentAccountCard({
    required this.account,
    required this.accountCount,
    required this.onOpenAccountCenter,
  });

  final Account account;
  final int accountCount;
  final VoidCallback onOpenAccountCenter;

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AccountAvatar(account: account, size: 48, radius: 16),
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.accountLabel} · ${account.hostLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF93A0AF),
                          fontWeight: FontWeight.w600,
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
          ),
          const Divider(height: 1, color: Color(0xFFE7ECF2)),
          InkWell(
            onTap: onOpenAccountCenter,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.manage_accounts_rounded,
                    size: 19,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '账户管理',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '共 $accountCount 个账户',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF93A0AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF93A0AF),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    this.onTap,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
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
          color: warning ? color : const Color(0xFF16202C),
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF93A0AF)),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
