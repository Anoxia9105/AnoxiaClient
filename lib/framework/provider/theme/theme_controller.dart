import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/constants/storage_keys.dart';
import '../../../common/utils/sp_util.dart';
import '../../domain/app_background.dart';
import '../auth/token_provider.dart';
import '../core/app_background_repository_provider.dart';
import '../../theme/app_theme.dart';

part 'theme_controller.g.dart';

class ThemeModeController extends legacy.StateNotifier<Brightness> {
  static const String _storageKey = 'theme_brightness';

  ThemeModeController() : super(_load());

  static Brightness _load() {
    final saved = SPUtil.instance.get(_storageKey, defValue: 'light');
    return saved == 'dark' ? Brightness.dark : Brightness.light;
  }

  void setMode(Brightness brightness) {
    if (state == brightness) return;
    state = brightness;
    SPUtil.instance.set(
      _storageKey,
      brightness == Brightness.dark ? 'dark' : 'light',
    );
  }
}

final themeModeProvider =
    legacy.StateNotifierProvider<ThemeModeController, Brightness>(
      (ref) => ThemeModeController(),
    );

class ThemeAccentController extends legacy.StateNotifier<int> {
  static const String _storageKey = 'theme_accent_index';

  ThemeAccentController() : super(_load());

  static int _load() {
    final saved = SPUtil.instance.getInt(_storageKey, defValue: 0) ?? 0;
    return saved < 0 || saved >= AppTheme.accentOptions.length ? 0 : saved;
  }

  void setAccent(int index) {
    final safeIndex = index < 0 || index >= AppTheme.accentOptions.length
        ? 0
        : index;
    if (state == safeIndex) return;
    state = safeIndex;
    SPUtil.instance.setInt(_storageKey, safeIndex);
  }
}

final themeAccentProvider =
    legacy.StateNotifierProvider<ThemeAccentController, int>(
      (ref) => ThemeAccentController(),
    );

/// 自定义强调色控制器
///
/// null 表示使用预设强调色；非 null 时覆盖预设。
class CustomAccentColorController extends legacy.StateNotifier<Color?> {
  CustomAccentColorController() : super(_load());

  static Color? _load() {
    final enabled = SPUtil.instance.getBool(StorageKeys.customAccentEnabled, defValue: false) ?? false;
    if (!enabled) return null;
    final value = SPUtil.instance.getInt(StorageKeys.customAccentColor);
    if (value == null) return null;
    return Color(value);
  }

  void setCustomColor(Color? color) {
    if (color == null) {
      state = null;
      SPUtil.instance.setBool(StorageKeys.customAccentEnabled, false);
      SPUtil.instance.delete(StorageKeys.customAccentColor);
      return;
    }
    state = color;
    SPUtil.instance.setBool(StorageKeys.customAccentEnabled, true);
    SPUtil.instance.setInt(StorageKeys.customAccentColor, color.toARGB32());
  }

  void clear() => setCustomColor(null);
}

final customAccentColorProvider =
    legacy.StateNotifierProvider<CustomAccentColorController, Color?>(
      (ref) => CustomAccentColorController(),
    );

/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。
@Riverpod(keepAlive: true)
class ThemeIndex extends _$ThemeIndex {
  @override
  int build() {
    final themeIndex = SPUtil.instance.getInt('theme_index', defValue: 0);
    return themeIndex ?? 0;
  }

  /// 设置主题
  ///
  /// [index] 主题索引，对应 [AppTheme.getTheme] 的参数
  void setTheme(int index) {
    state = index;
    SPUtil.instance.setInt('theme_index', index);
  }
}

/// 应用主题 Provider
///
/// 固定字体：JetBrainsMono（拉丁/等宽）+ NotoSansSC（CJK 回退），全平台（含 Web）强制使用
/// 若存在自定义强调色则优先使用。
@riverpod
ThemeData appTheme(Ref ref) {
  final brightness = ref.watch(themeModeProvider);
  final customColor = ref.watch(customAccentColorProvider);
  if (customColor != null) {
    return AppTheme.getThemeForCustomColor(
      brightness: brightness,
      color: customColor,
    );
  }
  final accentIndex = ref.watch(themeAccentProvider);
  return AppTheme.getThemeByModeAndAccent(
    brightness: brightness,
    accentIndex: accentIndex,
  );
}

class AppBackgroundController extends Notifier<AppBackgroundState> {
  int _preferenceRevision = 0;
  Future<void> _preferenceWriteQueue = Future<void>.value();

  @override
  AppBackgroundState build() {
    final token = ref.watch(tokenCacheProvider);
    if (token != null && token.isNotEmpty) {
      Future<void>.microtask(refresh);
    }
    return const AppBackgroundState();
  }

  Future<void> refresh() async {
    if (state.loading) return;
    final preferenceRevision = _preferenceRevision;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final remote = await ref.read(appBackgroundRepositoryProvider).fetch();
      if (preferenceRevision != _preferenceRevision) {
        state = state.copyWith(loading: false);
        return;
      }
      final local = state;
      await _replace(
        local.mergeRemote(
          remote,
          preserveUpload: local.uploading,
          surfaceOpacityOverride: local.uploading ? local.surfaceOpacity : null,
        ),
      );
    } catch (_) {
      if (preferenceRevision == _preferenceRevision) {
        state = state.copyWith(loading: false, error: 'load_failed');
      } else {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> upload(Uint8List bytes, String fileName) async {
    if (state.uploading) return;
    state = state.copyWith(
      uploading: true,
      uploadProgress: 0,
      clearError: true,
    );
    final preferenceRevision = _preferenceRevision;
    try {
      final remote = await ref
          .read(appBackgroundRepositoryProvider)
          .upload(
            bytes: bytes,
            fileName: fileName,
            onProgress: (sent, total) {
              state = state.copyWith(
                uploadProgress: AppBackgroundState.displayUploadProgress(
                  sent,
                  total,
                ),
              );
            },
          );
      final desiredOpacity = state.surfaceOpacity;
      final desiredAssetId = preferenceRevision == _preferenceRevision
          ? remote.activeAssetId
          : state.activeAssetId;
      final persisted =
          desiredOpacity == remote.surfaceOpacity &&
              desiredAssetId == remote.activeAssetId
          ? remote
          : await ref
                .read(appBackgroundRepositoryProvider)
                .updatePreference(
                  activeAssetId: desiredAssetId,
                  surfaceOpacity: desiredOpacity,
                );
      await _replace(
        state.mergeRemote(persisted, surfaceOpacityOverride: desiredOpacity),
      );
    } catch (_) {
      state = state.copyWith(
        uploading: false,
        clearUploadProgress: true,
        error: 'upload_failed',
      );
      rethrow;
    }
  }

  void previewOpacity(double opacity) {
    state = state.copyWith(surfaceOpacity: opacity);
  }

  Future<void> savePreference({int? activeAssetId}) async {
    final revision = ++_preferenceRevision;
    if (state.uploading) {
      if (activeAssetId != null) {
        state = state.copyWith(activeAssetId: activeAssetId);
      }
      return;
    }
    final previous = state;
    if (activeAssetId != null) {
      state = state.copyWith(activeAssetId: activeAssetId);
    }
    final desiredAssetId = state.activeAssetId;
    final desiredOpacity = state.surfaceOpacity;
    final operation = _preferenceWriteQueue.then((_) async {
      try {
        final remote = await ref
            .read(appBackgroundRepositoryProvider)
            .updatePreference(
              activeAssetId: desiredAssetId,
              surfaceOpacity: desiredOpacity,
            );
        if (revision != _preferenceRevision) return;
        final local = state;
        await _replace(
          local.mergeRemote(
            remote,
            preserveUpload: local.uploading,
            surfaceOpacityOverride: local.surfaceOpacity,
          ),
        );
      } catch (_) {
        if (revision != _preferenceRevision) return;
        state = state.uploading
            ? state.copyWith(error: 'save_failed')
            : previous.copyWith(error: 'save_failed');
        rethrow;
      }
    });
    _preferenceWriteQueue = operation.catchError((_) {});
    return operation;
  }

  Future<void> disable() async {
    final revision = ++_preferenceRevision;
    final previous = state;
    state = state.copyWith(clearActiveAsset: true);
    try {
      final remote = await ref
          .read(appBackgroundRepositoryProvider)
          .updatePreference(
            activeAssetId: null,
            surfaceOpacity: state.surfaceOpacity,
          );
      if (revision == _preferenceRevision) await _replace(remote);
    } catch (_) {
      if (revision != _preferenceRevision) return;
      state = previous.copyWith(error: 'save_failed');
      rethrow;
    }
  }

  Future<void> deleteAsset(int assetId) async {
    await _replace(
      await ref.read(appBackgroundRepositoryProvider).delete(assetId),
    );
  }

  Future<void> _replace(AppBackgroundState next) {
    state = next;
    return Future<void>.value();
  }
}

final appBackgroundProvider =
    NotifierProvider<AppBackgroundController, AppBackgroundState>(
      AppBackgroundController.new,
    );
