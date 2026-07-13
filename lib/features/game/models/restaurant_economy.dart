class RecipeData {
  const RecipeData(
    this.id,
    this.name,
    this.price,
    this.cookTime,
    this.requiredLevel,
    this.experience,
  );
  final String id;
  final String name;
  final int price;
  final double cookTime;
  final int requiredLevel;
  final int experience;
}

const restaurantRecipes = [
  RecipeData('fried_rice', 'Egg Fried Rice', 20, 2.8, 1, 8),
  RecipeData('noodles', 'Beef Noodles', 28, 3.4, 2, 11),
  RecipeData('dumplings', 'Dumplings', 36, 4.0, 3, 14),
  RecipeData('fish', 'Braised Fish', 52, 5.0, 4, 18),
  RecipeData('hotpot', 'House Hotpot', 75, 6.0, 5, 25),
];

int experienceForLevel(int level) => level * 50;

class RestaurantSnapshot {
  const RestaurantSnapshot({
    required this.coins,
    required this.level,
    required this.experience,
    required this.experienceToNext,
    required this.popularity,
    required this.kitchenLevel,
    required this.cashierLevel,
    required this.kitchenUpgradeCost,
    required this.cashierUpgradeCost,
    required this.unlockedRecipes,
  });
  final int coins;
  final int level;
  final int experience;
  final int experienceToNext;
  final int popularity;
  final int kitchenLevel;
  final int cashierLevel;
  final int kitchenUpgradeCost;
  final int cashierUpgradeCost;
  final int unlockedRecipes;
}
