import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/restaurant_character_preview.dart';
import 'package:flame/components.dart';

class RestaurantLevel1 extends World {
  static const _characterNames = [
    'waiter',
    'womanwaiter',
    'aunt',
    'uncle',
    'boy',
    'girl',
    'cleaner',
    'cop',
    'oldman',
    'oldwoman',
    'yongman',
    'yongwoman',
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final waiter = MyWaiter()..position = Vector2(24, 12);
    await add(waiter);

    waiter.changeState(WaiterState.walking);

    Future.delayed(const Duration(seconds: 4), () {
      waiter.changeState(WaiterState.carryingFood);
    });

    Future.delayed(const Duration(seconds: 8), () {
      waiter.changeState(WaiterState.idle);
    });

    for (var i = 0; i < _characterNames.length; i++) {
      final col = i % 4;
      final row = i ~/ 4;
      await add(
        RestaurantCharacterPreview(
          characterName: _characterNames[i],
          position: Vector2(180 + col * 130, 20 + row * 150),
          previewScale: 1.0,
        ),
      );
    }
  }
}
