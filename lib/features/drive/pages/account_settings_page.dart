import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:foxel/core/models/license_info.dart';
import 'package:foxel/core/storage/download_path_store.dart';
import 'package:foxel/features/drive/pages/license_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.baseUrl,
    required this.licenseInfo,
    required this.onVerifyLicense,
    required this.onSwitchServer,
    required this.onLogout,
  });

  final String username;
  final String email;
  final String avatarUrl;
  final String baseUrl;
  final LicenseInfo? licenseInfo;
  final Future<LicenseInfo> Function(String licenseKey) onVerifyLicense;
  final VoidCallback onSwitchServer;
  final VoidCallback onLogout;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _downloadPathStore = DownloadPathStore();
  String? _customDownloadPath;
  String? _defaultDownloadPath;
  bool _loadingDownloadPath = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadPaths();
  }

  Future<void> _loadDownloadPaths() async {
    final store = DownloadPathStore();
    final customPath = await store.load();
    final defaultPath = await store.defaultDownloadPath();
    if (mounted) {
      setState(() {
        _customDownloadPath = customPath;
        _defaultDownloadPath = defaultPath;
        _loadingDownloadPath = false;
      });
    }
  }

  Future<void> _pickDownloadDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择下载目录',
    );
    if (result == null || result.isEmpty) {
      return;
    }
    await _downloadPathStore.save(result);
    if (mounted) {
      setState(() {
        _customDownloadPath = result;
      });
    }
  }

  Future<void> _resetDownloadDirectory() async {
    await _downloadPathStore.clear();
    if (mounted) {
      setState(() {
        _customDownloadPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadDisplayPath = _customDownloadPath ?? _defaultDownloadPath ?? '未知';
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
            const SizedBox(height: 14),
            _AccountCard(
              username: widget.username,
              email: widget.email,
              avatarUrl: widget.avatarUrl,
              baseUrl: widget.baseUrl,
            ),
            const SizedBox(height: 14),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.verified_user_rounded,
                  title: '授权',
                  subtitle: licenseStatusText(widget.licenseInfo),
                  onTap: _openLicensePage,
                ),
                _SettingsRow(
                  icon: Icons.sync_alt_rounded,
                  title: '切换服务或重新登录',
                  subtitle: '修改后端地址、账号或刷新登录状态',
                  onTap: widget.onSwitchServer,
                ),
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: '退出登录',
                  subtitle: '清除本地登录凭证',
                  destructive: true,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsGroup(
              children: [
                _DownloadPathRow(
                  icon: Icons.folder_rounded,
                  title: '下载目录',
                  subtitle: _loadingDownloadPath
                      ? '加载中...'
                      : downloadDisplayPath,
                  isCustom: _customDownloadPath != null,
                  onTap: _pickDownloadDirectory,
                  onReset: _resetDownloadDirectory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openLicensePage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoxelLicensePage(
          baseUrl: widget.baseUrl,
          licenseInfo: widget.licenseInfo,
          onVerifyLicense: widget.onVerifyLicense,
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定清除本地登录状态？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      widget.onLogout();
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.baseUrl,
  });

  final String username;
  final String email;
  final String avatarUrl;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarImage(avatarUrl: avatarUrl, username: username, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isEmpty ? '未设置邮箱' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF697586),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '后端地址',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF697586)),
          ),
          const SizedBox(height: 6),
          Text(
            baseUrl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.avatarUrl,
    required this.username,
    required this.size,
  });

  final String avatarUrl;
  final String username;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty
        ? 'F'
        : username.characters.first.toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF1FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF276EF1),
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
    if (avatarUrl.isEmpty) {
      return fallback;
    }
    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF276EF1);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: destructive ? color : null)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _DownloadPathRow extends StatelessWidget {
  const _DownloadPathRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCustom,
    required this.onTap,
    required this.onReset,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF276EF1)),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCustom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: '恢复默认',
                  onPressed: onReset,
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
