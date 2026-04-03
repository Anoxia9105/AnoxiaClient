import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_panel_provider.g.dart';

@riverpod
class HistoryPanelNotifier extends _$HistoryPanelNotifier {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void close() => state = false;
}