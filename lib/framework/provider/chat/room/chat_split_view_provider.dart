import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:flutter_riverpod/legacy.dart';

final chatSplitViewWeightsProvider = StateNotifierProvider<
  ChatSplitViewWeightsNotifier,
  List<double>
>((ref) {
  return ChatSplitViewWeightsNotifier();
});

class ChatSplitViewWeightsNotifier extends StateNotifier<List<double>> {
  static const String _storageKey = 'chat_split_view_weights';
  static const List<double> _defaultWeights = <double>[0.2, 0.8];

  ChatSplitViewWeightsNotifier() : super(_loadWeights());

  static List<double> _loadWeights() {
    final raw = SPUtil.instance.getStringList(
      _storageKey,
      defValue: const <String>['0.2', '0.8'],
    );

    if (raw == null || raw.length < 2) {
      return _defaultWeights;
    }

    final left = double.tryParse(raw[0]);
    final right = double.tryParse(raw[1]);
    if (left == null || right == null || left <= 0 || right <= 0) {
      return _defaultWeights;
    }

    final sum = left + right;
    if (sum <= 0) {
      return _defaultWeights;
    }

    return <double>[left / sum, right / sum];
  }

  Future<void> updateWeights(List<double?> weights) async {
    if (weights.length < 2) {
      return;
    }

    final left = weights[0];
    final right = weights[1];
    if (left == null || right == null || left <= 0 || right <= 0) {
      return;
    }

    final sum = left + right;
    if (sum <= 0) {
      return;
    }

    final normalized = <double>[left / sum, right / sum];
    if (_sameWeights(state, normalized)) {
      return;
    }

    state = normalized;
    await SPUtil.instance.setStringList(
      _storageKey,
      normalized.map((value) => value.toString()).toList(),
    );
  }

  Future<void> reset() async {
    state = _defaultWeights;
    await SPUtil.instance.setStringList(
      _storageKey,
      _defaultWeights.map((value) => value.toString()).toList(),
    );
  }

  bool _sameWeights(List<double> a, List<double> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index++) {
      if ((a[index] - b[index]).abs() > 0.0001) {
        return false;
      }
    }

    return true;
  }
}