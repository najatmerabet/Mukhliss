/// ============================================================
/// Store Entity Tests
/// ============================================================
///
/// Tests unitaires pour StoreEntity
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/features/stores/domain/entities/store_entity.dart';

void main() {
  group('StoreEntity', () {
    test('should create StoreEntity with all properties', () {
      // Arrange
      final store = StoreEntity(
        id: '123',
        name: 'Test Store',
        description: 'A test store',
        address: '123 Test Street',
        phone: '0612345678',
        latitude: 35.7595,
        longitude: -5.8340,
        categoryId: 'cat-1',
        isActive: true,
        logoUrl: 'https://example.com/logo.png',
        createdAt: DateTime(2024, 1, 1),
      );

      // Assert
      expect(store.id, equals('123'));
      expect(store.name, equals('Test Store'));
      expect(store.description, equals('A test store'));
      expect(store.address, equals('123 Test Street'));
      expect(store.phone, equals('0612345678'));
      expect(store.latitude, equals(35.7595));
      expect(store.longitude, equals(-5.8340));
      expect(store.categoryId, equals('cat-1'));
      expect(store.isActive, isTrue);
      expect(store.logoUrl, equals('https://example.com/logo.png'));
    });

    test('should have default isActive value of true', () {
      // Arrange
      final store = StoreEntity(
        id: '123',
        name: 'Test Store',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      // Assert
      expect(store.isActive, isTrue);
    });

    test('should handle null optional properties', () {
      // Arrange
      final store = StoreEntity(
        id: '123',
        name: 'Test Store',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      // Assert
      expect(store.description, isNull);
      expect(store.address, isNull);
      expect(store.phone, isNull);
      expect(store.logoUrl, isNull);
      expect(store.categoryId, isNull);
    });

    test('distanceFrom should calculate distance between two points', () {
      // Arrange
      final store = StoreEntity(
        id: '123',
        name: 'Test Store',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      // Act
      final distance = store.distanceFrom(35.7600, -5.8350);

      // Assert - distance should be a positive number
      expect(distance, greaterThan(0));
    });

    test('two stores with same id should be equal', () {
      // Arrange
      final store1 = StoreEntity(
        id: '123',
        name: 'Store 1',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      final store2 = StoreEntity(
        id: '123',
        name: 'Store 2 (different name)',
        latitude: 36.0,
        longitude: -6.0,
      );

      // Assert - equality based on id
      expect(store1, equals(store2));
      expect(store1.hashCode, equals(store2.hashCode));
    });

    test('two stores with different id should not be equal', () {
      // Arrange
      final store1 = StoreEntity(
        id: '123',
        name: 'Store',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      final store2 = StoreEntity(
        id: '456',
        name: 'Store',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      // Assert
      expect(store1, isNot(equals(store2)));
    });

    test('toString should return readable format', () {
      // Arrange
      final store = StoreEntity(
        id: '123',
        name: 'My Store',
        latitude: 35.7595,
        longitude: -5.8340,
      );

      // Act
      final stringRep = store.toString();

      // Assert
      expect(stringRep, contains('123'));
      expect(stringRep, contains('My Store'));
    });
  });
}
