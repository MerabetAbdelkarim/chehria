import 'package:flutter/material.dart';

import '../../features/accounts/models/account.dart';
import '../../features/categories/models/category.dart';

/// Seed data created on first sign-in (deterministic ids, batched write).
class DefaultData {
  DefaultData._();

  static IconData iconOf(int codePoint) =>
      IconData(codePoint, fontFamily: 'MaterialIcons');

  static const List<Color> colorOptions = [
    Color(0xFF00873D),
    Color(0xFFF57C00),
    Color(0xFF1E88E5),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFE53935),
    Color(0xFF6D4C41),
    Color(0xFF3949AB),
    Color(0xFF757575),
    Color(0xFF43A047),
    Color(0xFF00838F),
  ];

  static const List<IconData> iconOptions = [
    Icons.restaurant,
    Icons.directions_bus,
    Icons.local_cafe,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.favorite,
    Icons.family_restroom,
    Icons.sports_esports,
    Icons.autorenew,
    Icons.category,
    Icons.payments,
    Icons.home,
    Icons.school,
    Icons.flight,
    Icons.pets,
    Icons.checkroom,
    Icons.phone_iphone,
    Icons.wifi,
    Icons.local_hospital,
    Icons.card_giftcard,
    Icons.savings,
    Icons.shopping_cart,
    Icons.local_grocery_store,
    Icons.local_laundry_service,
    Icons.bathtub,
    Icons.child_care,
    Icons.spa,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.workspace_premium,
  ];

  static List<Category> get categories => [
    Category(
      id: 'cat_food',
      nameAr: 'أكل ومطاعم',
      nameFr: 'Alimentation',
      iconCode: Icons.restaurant.codePoint,
      colorValue: 0xFFF57C00,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_transport',
      nameAr: 'نقل ووقود',
      nameFr: 'Transport',
      iconCode: Icons.directions_bus.codePoint,
      colorValue: 0xFF1E88E5,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_coffee',
      nameAr: 'قهوة',
      nameFr: 'Café',
      iconCode: Icons.local_cafe.codePoint,
      colorValue: 0xFF6D4C41,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_shopping',
      nameAr: 'تسوّق',
      nameFr: 'Courses',
      iconCode: Icons.shopping_bag.codePoint,
      colorValue: 0xFFD81B60,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_bills',
      nameAr: 'فواتير',
      nameFr: 'Factures',
      iconCode: Icons.receipt_long.codePoint,
      colorValue: 0xFF3949AB,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_health',
      nameAr: 'صحة',
      nameFr: 'Santé',
      iconCode: Icons.favorite.codePoint,
      colorValue: 0xFFE53935,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_family',
      nameAr: 'عائلة',
      nameFr: 'Famille',
      iconCode: Icons.family_restroom.codePoint,
      colorValue: 0xFF00897B,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_leisure',
      nameAr: 'ترفيه',
      nameFr: 'Loisirs',
      iconCode: Icons.sports_esports.codePoint,
      colorValue: 0xFF8E24AA,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_subscriptions',
      nameAr: 'اشتراكات',
      nameFr: 'Abonnements',
      iconCode: Icons.autorenew.codePoint,
      colorValue: 0xFF00ACC1,
      kind: CategoryKind.expense,
      isDefault: true,
    ),
    Category(
      id: 'cat_other',
      nameAr: 'أخرى',
      nameFr: 'Autre',
      iconCode: Icons.category.codePoint,
      colorValue: 0xFF757575,
      kind: CategoryKind.both,
      isDefault: true,
    ),
    Category(
      id: 'cat_salary',
      nameAr: 'الراتب',
      nameFr: 'Salaire',
      iconCode: Icons.payments.codePoint,
      colorValue: 0xFF43A047,
      kind: CategoryKind.income,
      isDefault: true,
    ),
  ];

  static List<Account> get accounts => [
    const Account(
      id: 'acc_cash',
      name: 'نقد',
      type: AccountType.cash,
      balance: 0,
      colorValue: 0xFF00873D,
    ),
    const Account(
      id: 'acc_ccp',
      name: 'CCP / باريدي موب',
      type: AccountType.ccp,
      balance: 0,
      colorValue: 0xFF1E88E5,
    ),
    const Account(
      id: 'acc_card',
      name: 'بطاقة بنكية',
      type: AccountType.card,
      balance: 0,
      colorValue: 0xFF8E24AA,
    ),
  ];
}
