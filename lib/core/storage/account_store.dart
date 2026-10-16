import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:foxel/core/models/account.dart';

/// 多账户存储。
///
/// 全局层只保存「账户索引 + 当前账户指针 + 各账户 token」，
/// 其余数据（下载目录 / 浏览状态 / 播放进度 / 任务）全部挂在
/// `foxel_acc_<id>_*` 前缀下，形成每账户一个沙箱。
class AccountStore {
  static const _indexKey = 'foxel_accounts_index';
  static const _activeKey = 'foxel_active_account_id';

  /// 旧版本（单会话）遗留 key，仅用于迁移。
  static const _legacyBaseUrlKey = 'foxel_base_url';
  static const _legacyUsernameKey = 'foxel_username';
  static const _legacyTokenKey = 'foxel_token';
  static const _legacyEmailKey = 'foxel_email';
  static const _legacyAvatarUrlKey = 'foxel_avatar_url';

  static String tokenKey(String accountId) => 'foxel_acc_${accountId}_token';

  /// 读取全部账户，必要时执行一次旧版本迁移。
  Future<List<Account>> loadAccounts({bool migrate = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    final accounts = <Account>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final id = item['id'] as String? ?? '';
              if (id.isEmpty) {
                continue;
              }
              accounts.add(
                Account.fromJson(
                  item,
                  token: prefs.getString(tokenKey(id)) ?? '',
                ),
              );
            }
          }
        }
      } catch (_) {
        // 索引损坏时按空列表处理，避免应用无法启动。
      }
    }

    if (accounts.isEmpty && migrate) {
      final migrated = _migrateLegacy(prefs);
      if (migrated != null) {
        await upsert(migrated);
        await setActiveId(migrated.id);
        return <Account>[migrated];
      }
    }

    return accounts;
  }

  Account? _migrateLegacy(SharedPreferences prefs) {
    final baseUrl = prefs.getString(_legacyBaseUrlKey);
    final username = prefs.getString(_legacyUsernameKey);
    final token = prefs.getString(_legacyTokenKey);
    if (baseUrl == null ||
        baseUrl.isEmpty ||
        username == null ||
        username.isEmpty ||
        token == null ||
        token.isEmpty) {
      return null;
    }
    return Account(
      id: Account.generateId(),
      alias: '默认账户',
      baseUrl: baseUrl,
      username: username,
      token: token,
      email: prefs.getString(_legacyEmailKey) ?? '',
      avatarUrl: prefs.getString(_legacyAvatarUrlKey) ?? '',
      colorValue: Account.defaultColorValue,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
  }

  Future<String?> activeId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activeKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  /// 当前账户；不存在时回退到最近使用的账户。
  Future<Account?> activeAccount() async {
    final accounts = await loadAccounts();
    if (accounts.isEmpty) {
      return null;
    }
    final id = await activeId();
    for (final account in accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return accounts.first;
  }

  Future<void> setActiveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
  }

  /// 新增或更新账户（token 单独存放）。
  Future<void> upsert(Account account) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await loadAccounts(migrate: false);
    final next = <Account>[
      for (final item in accounts) if (item.id != account.id) item,
      account,
    ];
    await prefs.setString(_indexKey, jsonEncode(next.map(_toIndex).toList()));
    await prefs.setString(tokenKey(account.id), account.token);
  }

  Map<String, dynamic> _toIndex(Account account) {
    final json = account.toJson();
    json.remove('token');
    return json;
  }

  Future<void> updateToken(String id, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey(id), token);
  }

  /// 记录「最后使用时间」。
  Future<void> touch(String id) async {
    final accounts = await loadAccounts(migrate: false);
    for (final account in accounts) {
      if (account.id == id) {
        await upsert(account.copyWith(lastUsedAt: DateTime.now()));
        return;
      }
    }
  }

  /// 标记账户失效（token 过期等），本地沙箱数据保留。
  Future<void> markStale(String id, {required bool stale}) async {
    final accounts = await loadAccounts(migrate: false);
    for (final account in accounts) {
      if (account.id == id) {
        await upsert(account.copyWith(isStale: stale));
        return;
      }
    }
  }

  /// 移除账户及其沙箱内的全部本地数据。
  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await loadAccounts(migrate: false);
    final next = <Account>[
      for (final item in accounts) if (item.id != id) item,
    ];
    await prefs.setString(_indexKey, jsonEncode(next.map(_toIndex).toList()));

    final prefix = 'foxel_acc_${id}_';
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(prefix)) {
        await prefs.remove(key);
      }
    }

    final active = prefs.getString(_activeKey);
    if (active == id) {
      if (next.isEmpty) {
        await prefs.remove(_activeKey);
      } else {
        await prefs.setString(_activeKey, next.first.id);
      }
    }
  }

  /// 清除账户的本地缓存与状态，但保留账户与登录态。
  Future<void> clearLocalData(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'foxel_acc_${id}_';
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(prefix) && key != tokenKey(id)) {
        await prefs.remove(key);
      }
    }
  }
}
