import 'dart:convert';

import 'package:anoxia/features/game/config/crop_type_enum.dart';
import 'package:anoxia/features/game/farm_game_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// 游戏持久化：金币 / 种子背包 / 收获背包 / 每块地的状态
// 使用 shared_preferences，轻量级、无需网络
// ============================================================

class GamePersistence {
  static const _keyCoins = 'farm_coins';
  static const _keySeeds = 'farm_seeds';
  static const _keyHarvest = 'farm_harvest';
  static const _keyPlots = 'farm_plots';

  /// 加载存档；若不存在则返回 null（首次启动）
  static Future<GameSaveData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyCoins)) return null;

    final coins = prefs.getInt(_keyCoins) ?? 100;

    final seedsRaw =
        jsonDecode(prefs.getString(_keySeeds) ?? '{}') as Map<String, dynamic>;
    final seeds = <CropType, int>{};
    for (final e in seedsRaw.entries) {
      try {
        seeds[CropType.values.byName(e.key)] = (e.value as num).toInt();
      } catch (_) {}
    }

    final harvestRaw =
        jsonDecode(prefs.getString(_keyHarvest) ?? '{}')
            as Map<String, dynamic>;
    final harvest = <CropType, int>{};
    for (final e in harvestRaw.entries) {
      try {
        harvest[CropType.values.byName(e.key)] = (e.value as num).toInt();
      } catch (_) {}
    }

    final plotsRaw =
        jsonDecode(prefs.getString(_keyPlots) ?? '[]') as List<dynamic>;
    final plots =
        plotsRaw
            .whereType<Map<String, dynamic>>()
            .map(PlotSaveState.fromJson)
            .toList();

    return GameSaveData(
      coins: coins,
      seeds: seeds,
      harvest: harvest,
      plots: plots,
    );
  }

  /// 保存当前全量状态（异步 fire-and-forget）
  static Future<void> save({
    required int coins,
    required Map<CropType, int> seeds,
    required Map<CropType, int> harvest,
    required List<PlotSaveState> plots,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final seedsJson = jsonEncode({
      for (final e in seeds.entries) e.key.name: e.value,
    });
    final harvestJson = jsonEncode({
      for (final e in harvest.entries) e.key.name: e.value,
    });
    final plotsJson = jsonEncode(plots.map((p) => p.toJson()).toList());

    await Future.wait([
      prefs.setInt(_keyCoins, coins),
      prefs.setString(_keySeeds, seedsJson),
      prefs.setString(_keyHarvest, harvestJson),
      prefs.setString(_keyPlots, plotsJson),
    ]);
  }
}

// ========== 存档数据结构 ==========

class GameSaveData {
  final int coins;
  final Map<CropType, int> seeds;
  final Map<CropType, int> harvest;
  final List<PlotSaveState> plots;

  const GameSaveData({
    required this.coins,
    required this.seeds,
    required this.harvest,
    required this.plots,
  });
}

class PlotSaveState {
  final PlotStage stage;
  final CropType? crop;
  final double elapsedGrow;
  final double elapsedRipe;

  const PlotSaveState({
    required this.stage,
    required this.crop,
    required this.elapsedGrow,
    required this.elapsedRipe,
  });

  Map<String, dynamic> toJson() => {
    'stage': stage.name,
    'crop': crop?.name,
    'elapsedGrow': elapsedGrow,
    'elapsedRipe': elapsedRipe,
  };

  factory PlotSaveState.fromJson(Map<String, dynamic> json) => PlotSaveState(
    stage: PlotStage.values.byName(json['stage'] as String? ?? 'empty'),
    crop:
        json['crop'] == null
            ? null
            : () {
              try {
                return CropType.values.byName(json['crop'] as String);
              } catch (_) {
                return null;
              }
            }(),
    elapsedGrow: (json['elapsedGrow'] as num?)?.toDouble() ?? 0,
    elapsedRipe: (json['elapsedRipe'] as num?)?.toDouble() ?? 0,
  );
}
