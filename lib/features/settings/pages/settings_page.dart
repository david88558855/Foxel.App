import 'package:flutter/material.dart';

import 'package:foxel/core/models/account.dart';
import 'package:foxel/core/storage/download_dir_store.dart';
import 'package:foxel/core/theme/design_tokens.dart';
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
  int? _usageBytes;

  @override
  void initState() {
    super.initState();
    _loadDownloadDir();
    _loadUsage();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      _loadDownloadDir();
      _loadUsage();
    }
  }

  Future<void> _loadDownloadDir() async {
    final dir = await DownloadDirStore.currentDirFor(widget.account.id);
    if (mounted) {
      setState(() => _downloadDir = dir);
    }
  }

  Future<void> _loadUsage() async {
    final bytes = await DownloadDirStore.dirSizeBytes(widget.account.id);
    if (mounted) {
      setState(() => _usageBytes = bytes);
    }
  }

  String get _usageLabel {
    final bytes = _usageBytes;
    if (bytes == null) {
      return '计算中';
    }
    if (bytes == 0) {
      return '暂无已下载文件';
    }
    return '本地已下载 ${_formatBytes(bytes)}';
  }

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final text = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$text ${units[index]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.navBottom,
          ),
          children: [
            const Text('设置', style: AppText.pageTitle),
            const SizedBox(height: 2),
            Text(
              widget.account.displayName,
              style: AppText.pageSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            _CurrentAccountCard(
              account: widget.account,
              accountCount: widget.accountCount,
              onOpenAccountCenter: widget.onOpenAccountCenter,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('通用', style: AppText.sectionLabel),
            const SizedBox(height: AppSpacing.sm),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.download_rounded,
                  title: '下载目录',
                  subtitle: _downloadDir ?? '加载中',
                  onTap: _editDownloadDir,
                ),
                _SettingsRow(
                  icon: Icons.storage_rounded,
                  title: '存储用量',
                  subtitle: _usageLabel,
                  onTap: _loadUsage,
                ),
                const _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: '关于 Foxel',
                  subtitle: '版本 1.0.0',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('当前账户', style: AppText.sectionLabel),
            const SizedBox(height: AppSpacing.sm),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.cleaning_services_rounded,
                  title: '清除本地数据',
                  subtitle: '删除缓存与下载目录配置，保留账户',
                  warning: true,
                  onTap: () => widget.onClearLocalData(widget.account),
                ),
                _SettingsRow(
                  icon: Icons.add_rounded,
                  title: '添加账户',
                  subtitle: '手动输入或扫码登录',
                  onTap: widget.onAddAccount,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                '切换账户、添加或移除账户请进入「账户管理」',
                style: AppText.itemHint,
              ),
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
        _showMessage('已恢复默认：$defaultDir');
      }
      return;
    }
    if (result.trim().isEmpty) {
      return;
    }
    final writable = await DownloadDirStore.isWritable(result);
    if (!writable) {
      if (mounted) {
        _showMessage('该目录不可写入');
      }
      return;
    }
    await DownloadDirStore.setDirFor(account.id, result);
    await _loadDownloadDir();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      decoration: AppDecorations.currentAccount(color),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Row(
              children: [
                AccountAvatar(
                  account: account,
                  size: 48,
                  radius: AppRadii.avatarLarge,
                ),
                const SizedBox(width: AppSpacing.md),
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
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.accountLabel} · ${account.hostLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.itemHint,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: AppDecorations.pill(
                    account.isStale ? AppColors.warn : color,
                  ),
                  child: Text(
                    account.isStale ? '需重新验证' : '使用中',
                    style: AppText.pill.copyWith(
                      color: account.isStale ? AppColors.warn : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          InkWell(
            onTap: onOpenAccountCenter,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.card,
                AppSpacing.md,
                AppSpacing.card,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(Icons.manage_accounts_rounded, size: 19, color: color),
                  const SizedBox(width: 10),
                  Text(
                    '账户管理',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '共 $accountCount 个账户',
                    style: AppText.itemHint,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.ink3,
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

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.group(),
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
    final color = warning ? AppColors.warn : AppColors.ink2;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 2,
      ),
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        title,
        style: AppText.itemTitle.copyWith(
          color: warning ? AppColors.warn : AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.itemHint,
      ),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink3),
      onTap: onTap,
    );
  }
}
