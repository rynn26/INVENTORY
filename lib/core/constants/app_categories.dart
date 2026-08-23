import 'package:flutter/material.dart';

class AppCategories {
  AppCategories._();

  static const List<String> all = [
    'Makanan Berat & Nasi',
    'Gorengan & Fritters',
    'Kue Basah & Tradisional',
    'Kue Kering & Pastry',
    'Roti & Donat',
    'Jajanan Pasar & Dimsum',
    'Lauk Pauk & Sayur',
    'Minuman Dingin & Segar',
    'Kopi & Minuman Hangat',
    'Snack & Keripik',
    'Dessert & Puding',
    'Frozen Food & Olahan',
    'Sembako & Kebutuhan',
    'Lainnya',
  ];

  static List<String> get filterList => ['Semua', ...all];

  /// Mengembalikan icon yang sesuai untuk masing-masing kategori
  static IconData getIcon(String? category) {
    if (category == null) return Icons.category_rounded;
    final cat = category.toLowerCase();

    if (cat.contains('nasi') || cat.contains('makanan berat') || cat.contains('rice')) {
      return Icons.rice_bowl_rounded;
    }
    if (cat.contains('gorengan') || cat.contains('fritter')) {
      return Icons.lunch_dining_rounded;
    }
    if (cat.contains('kue basah') || cat.contains('tradisional')) {
      return Icons.cake_rounded;
    }
    if (cat.contains('kue kering') || cat.contains('pastry') || cat.contains('cookie')) {
      return Icons.cookie_rounded;
    }
    if (cat.contains('roti') || cat.contains('donat') || cat.contains('bread') || cat.contains('bakery')) {
      return Icons.bakery_dining_rounded;
    }
    if (cat.contains('jajanan') || cat.contains('dimsum') || cat.contains('siomay') || cat.contains('pempek')) {
      return Icons.set_meal_rounded;
    }
    if (cat.contains('lauk') || cat.contains('sayur') || cat.contains('dapur')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('minuman dingin') || cat.contains('es') || cat.contains('jus') || cat.contains('segar')) {
      return Icons.local_drink_rounded;
    }
    if (cat.contains('kopi') || cat.contains('hangat') || cat.contains('coffee') || cat.contains('teh')) {
      return Icons.coffee_rounded;
    }
    if (cat.contains('snack') || cat.contains('keripik') || cat.contains('kerupuk') || cat.contains('camilan')) {
      return Icons.emoji_food_beverage_rounded;
    }
    if (cat.contains('dessert') || cat.contains('puding') || cat.contains('es krim') || cat.contains('salad')) {
      return Icons.icecream_rounded;
    }
    if (cat.contains('frozen') || cat.contains('olahan') || cat.contains('nugget') || cat.contains('sosis')) {
      return Icons.ac_unit_rounded;
    }
    if (cat.contains('sembako') || cat.contains('kebutuhan') || cat.contains('grocery')) {
      return Icons.shopping_basket_rounded;
    }
    return Icons.category_rounded;
  }
}
