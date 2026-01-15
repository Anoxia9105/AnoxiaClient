import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_controller.g.dart';


@riverpod
class FontController extends _$FontController {
  @override
  String build() {
    final fontFamily = SPUtil.instance.get<String>("font_family", defValue: "HarmonyOS");
    // 默认字体
    return fontFamily!;
  }

  void setFont(String fontFamily) {
    state = fontFamily;
    SPUtil.instance.set("font_family", fontFamily);
  }
}