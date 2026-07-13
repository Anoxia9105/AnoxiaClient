/// 第一版经济平衡表。后续调数值只改这里，不要把价格散落到 UI 和关卡代码中。
abstract final class RestaurantBalance {
  static const initialCoins = 3500;
  static const dayDurationSeconds = 120;

  static const equipmentPrices = {
    'tables': 600,
    'kitchen': 800,
    'cashier': 400,
  };
  static const employeeHirePrices = {'waiter': 500, 'cleaner': 300};
  static const employeeDailyWages = {'waiter': 180, 'cleaner': 120};

  static const ingredientBundleSize = 10;
  static const ingredientUnitPrices = {
    'meat': 8,
    'vegetable': 4,
    'seafood': 10,
    'seasoning': 3,
  };
  static const ingredientNames = {
    'meat': '肉类',
    'vegetable': '蔬菜',
    'seafood': '海鲜',
    'seasoning': '调料',
  };
  static const ingredientSpriteIndexes = {
    'meat': 0,
    'vegetable': 1,
    'seafood': 2,
    'seasoning': 3,
  };

  static const dishes = <String, DishDefinition>{
    'dish_01': DishDefinition(
      id: 'dish_01',
      name: '招牌汤饭',
      iconAsset: 'assets/images/flame_resources/raw/cai_ico_s_01.png',
      basePrice: 45,
      recipe: {'vegetable': 2, 'seasoning': 1},
    ),
    'dish_02': DishDefinition(
      id: 'dish_02',
      name: '秘制肉料理',
      iconAsset: 'assets/images/flame_resources/raw/cai_ico_s_02.png',
      basePrice: 58,
      recipe: {'meat': 2, 'vegetable': 1, 'seasoning': 1},
    ),
  };

  static int dishPrice(String id, int level) {
    final base = dishes[id]!.basePrice;
    return (base * (1 + (level - 1) * .18)).round();
  }

  static int dishUpgradeCost(int currentLevel) => 450 * currentLevel;
}

class DishDefinition {
  const DishDefinition({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.basePrice,
    required this.recipe,
  });

  final String id;
  final String name;
  final String iconAsset;
  final int basePrice;
  final Map<String, int> recipe;
}
