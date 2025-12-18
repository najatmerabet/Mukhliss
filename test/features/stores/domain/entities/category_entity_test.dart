/// ============================================================
/// Category Entity Tests
/// ============================================================
///
/// Tests unitaires pour CategoryEntity
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';

void main() {
  group('CategoryEntity', () {
    test('should create CategoryEntity with all properties', () {
      // Arrange
      final category = CategoryEntity(
        id: 1,
        name: 'Restaurants',
        nameFr: 'Restaurants',
        nameAr: 'مطاعم',
        nameEn: 'Restaurants',
      );

      // Assert
      expect(category.id, equals(1));
      expect(category.name, equals('Restaurants'));
      expect(category.nameFr, equals('Restaurants'));
      expect(category.nameAr, equals('مطاعم'));
      expect(category.nameEn, equals('Restaurants'));
    });

    test('getName should return correct localized name for French', () {
      // Arrange
      final category = CategoryEntity(
        id: 1,
        name: 'Restaurants',
        nameFr: 'Restaurants FR',
        nameAr: 'مطاعم',
        nameEn: 'Restaurants EN',
      );

      // Act
      final frenchName = category.getName('fr');

      // Assert
      expect(frenchName, equals('Restaurants FR'));
    });

    test('getName should return correct localized name for Arabic', () {
      // Arrange
      final category = CategoryEntity(
        id: 1,
        name: 'Restaurants',
        nameFr: 'Restaurants FR',
        nameAr: 'مطاعم',
        nameEn: 'Restaurants EN',
      );

      // Act
      final arabicName = category.getName('ar');

      // Assert
      expect(arabicName, equals('مطاعم'));
    });

    test('getName should return correct localized name for English', () {
      // Arrange
      final category = CategoryEntity(
        id: 1,
        name: 'Restaurants',
        nameFr: 'Restaurants FR',
        nameAr: 'مطاعم',
        nameEn: 'Restaurants EN',
      );

      // Act
      final englishName = category.getName('en');

      // Assert
      expect(englishName, equals('Restaurants EN'));
    });

    test('getName should fallback to default name for unknown locale', () {
      // Arrange
      final category = CategoryEntity(
        id: 1,
        name: 'Restaurants',
        nameFr: 'Restaurants FR',
        nameAr: 'مطاعم',
        nameEn: 'Restaurants EN',
      );

      // Act
      final unknownLocaleName = category.getName('es');

      // Assert
      expect(unknownLocaleName, equals('Restaurants'));
    });

    test('getLocalizedName should return localized name with fallback', () {
      // Arrange
      final category = CategoryEntity(
        id: 1,
        name: 'Default Name',
        nameFr: '',
        nameAr: '',
        nameEn: '',
      );

      // Act & Assert
      expect(category.getLocalizedName('fr'), equals('Default Name'));
      expect(category.getLocalizedName('ar'), equals('Default Name'));
    });

    test('two categories with same id should be equal', () {
      // Arrange
      final cat1 = CategoryEntity(
        id: 1,
        name: 'Category 1',
        nameFr: 'Cat1 FR',
        nameAr: 'Cat1 AR',
        nameEn: 'Cat1 EN',
      );

      final cat2 = CategoryEntity(
        id: 1,
        name: 'Different',
        nameFr: 'Different',
        nameAr: 'مختلف',
        nameEn: 'Different',
      );

      // Assert
      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
    });

    test('two categories with different id should not be equal', () {
      // Arrange
      final cat1 = CategoryEntity(
        id: 1,
        name: 'Category',
        nameFr: 'Cat FR',
        nameAr: 'Cat AR',
        nameEn: 'Cat EN',
      );

      final cat2 = CategoryEntity(
        id: 2,
        name: 'Category',
        nameFr: 'Cat FR',
        nameAr: 'Cat AR',
        nameEn: 'Cat EN',
      );

      // Assert
      expect(cat1, isNot(equals(cat2)));
    });
  });
}
