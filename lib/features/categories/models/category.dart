import 'package:cloud_firestore/cloud_firestore.dart';

/// What the category can be used for.
enum CategoryKind {
  both,
  expense,
  income;

  static CategoryKind fromId(String? id) => CategoryKind.values.firstWhere(
    (k) => k.name == id,
    orElse: () => CategoryKind.both,
  );
}

/// A user-defined category (icon + color), used by transactions and budgets.
class Category {
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    required this.iconCode,
    required this.colorValue,
    this.kind = CategoryKind.both,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String nameAr;
  final String nameFr;
  final int iconCode;
  final int colorValue;
  final CategoryKind kind;
  final bool isDefault;
  final DateTime? createdAt;

  String name({required bool isAr}) => isAr ? nameAr : nameFr;

  Category copyWith({
    String? nameAr,
    String? nameFr,
    int? iconCode,
    int? colorValue,
    CategoryKind? kind,
  }) {
    return Category(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameFr: nameFr ?? this.nameFr,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Category(
      id: doc.id,
      nameAr: d['nameAr'] as String? ?? '',
      nameFr: d['nameFr'] as String? ?? '',
      iconCode: (d['iconCode'] as num?)?.toInt() ?? 0xe5d3,
      colorValue: (d['colorValue'] as num?)?.toInt() ?? 0xFF00873D,
      kind: CategoryKind.fromId(d['kind'] as String?),
      isDefault: d['isDefault'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nameAr': nameAr,
    'nameFr': nameFr,
    'iconCode': iconCode,
    'colorValue': colorValue,
    'kind': kind.name,
    'isDefault': isDefault,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
