import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:foxel/core/api/foxel_api.dart';

enum TransferTaskType { upload, download }

enum TransferTaskStatus { running, success, failed }

class TransferTask {
  const TransferTask({
    required this.id,
    required this.type,
    required this.name,
    required this.remotePath,
    required this.transferredBytes,
    required this.totalBytes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.localPath,
    this.errorMessage,
  });

  final int id;
  final TransferTaskType type;
  final String name;
  final String remotePath;
  final String? localPath;
  final int transferredBytes;
  final int? totalBytes;
  final TransferTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;

  double? get progress {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return (transferredBytes / total).clamp(0.0, 1.0).toDouble();
  }

  TransferTask copyWith({
    String? localPath,
    int? transferredBytes,
    int? totalBytes,
    bool clearTotalBytes = false,
    TransferTaskStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransferTask(
      id: id,
      type: type,
      name: name,
      remotePath: remotePath,
      localPath: localPath ?? this.localPath,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: clearTotalBytes ? null : totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TransferTaskController {
  final ValueNotifier<List<TransferTask>> tasks =
      ValueNotifier<List<TransferTask>>(<TransferTask>[]);

  int _nextId = 1;
  bool _disposed = false;

  /// 已被主动中断（切账户/删账户）的任务 id。
  /// 用于防止底层请求「抢跑成功」把状态又翻回「已完成」。
  final Set<int> _interrupted = <int>{};

  void dispose() {
    _disposed = true;
    _interrupted.clear();
    tasks.dispose();
  }

  /// 切换账户时中断本账户仍在进行的任务（方案 A：不跨账户并行传输）。
  void interruptAll(String reason) {
    if (_disposed) {
      return;
    }
    for (final task in tasks.value) {
      if (task.status == TransferTaskStatus.running) {
        _interrupted.add(task.id);
      }
    }
    tasks.value = [
      for (final task in tasks.value)
        if (task.status == TransferTaskStatus.running)
          task.copyWith(
            status: TransferTaskStatus.failed,
            errorMessage: reason,
          )
        else
          task,
    ];
  }

  void clearFinished() {
    if (_disposed) {
      return;
    }
    tasks.value = tasks.value
        .where((task) => task.status == TransferTaskStatus.running)
        .toList();
  }

  void startUpload({
    required FoxelApi api,
    required String name,
    required String remotePath,
    required String localPath,
    VoidCallback? onSuccess,
  }) {
    final task = _addTask(
      type: TransferTaskType.upload,
      name: name,
      remotePath: remotePath,
      localPath: localPath,
    );
    if (task == null) {
      return;
    }

    unawaited(
      _runTask(
        task.id,
        () => api.uploadFile(
          remotePath: remotePath,
          localPath: localPath,
          onProgress: (sent, total) {
            _updateTask(
              task.id,
              (task) =>
                  task.copyWith(transferredBytes: sent, totalBytes: total),
            );
          },
        ),
        onSuccess: onSuccess,
      ),
    );
  }

  void startDownload({
    required FoxelApi api,
    required String name,
    required String remotePath,
    required File outputFile,
  }) {
    final task = _addTask(
      type: TransferTaskType.download,
      name: name,
      remotePath: remotePath,
      localPath: outputFile.path,
    );
    if (task == null) {
      return;
    }

    unawaited(
      _runTask(
        task.id,
        () => api.downloadFile(
          remotePath: remotePath,
          outputFile: outputFile,
          onProgress: (received, total) {
            _updateTask(
              task.id,
              (task) => task.copyWith(
                transferredBytes: received,
                totalBytes: total,
                clearTotalBytes: total == null,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 新增任务；控制器已释放（账户被删除 / 页面销毁）时返回 null，
  /// 调用方拿到 null 必须直接返回，避免发起无记录的真实传输。
  TransferTask? _addTask({
    required TransferTaskType type,
    required String name,
    required String remotePath,
    required String localPath,
  }) {
    if (_disposed) {
      return null;
    }
    final now = DateTime.now();
    final task = TransferTask(
      id: _nextId++,
      type: type,
      name: name,
      remotePath: remotePath,
      localPath: localPath,
      transferredBytes: 0,
      totalBytes: null,
      status: TransferTaskStatus.running,
      createdAt: now,
      updatedAt: now,
    );
    tasks.value = [task, ...tasks.value];
    return task;
  }

  Future<void> _runTask(
    int id,
    Future<void> Function() action, {
    VoidCallback? onSuccess,
  }) async {
    try {
      await action();
      // 已被切账户/删账户中断：保持「已中断」状态，不翻回成功。
      if (_interrupted.remove(id)) {
        return;
      }
      _updateTask(
        id,
        (task) => task.copyWith(
          status: TransferTaskStatus.success,
          transferredBytes: task.totalBytes ?? task.transferredBytes,
          clearError: true,
        ),
      );
      onSuccess?.call();
    } catch (error) {
      if (_interrupted.remove(id)) {
        return;
      }
      _updateTask(
        id,
        (task) => task.copyWith(
          status: TransferTaskStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _updateTask(int id, TransferTask Function(TransferTask task) update) {
    if (_disposed) {
      return;
    }
    tasks.value = [
      for (final task in tasks.value) task.id == id ? update(task) : task,
    ];
  }
}
