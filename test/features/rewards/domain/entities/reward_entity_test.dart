/// ============================================================
/// Reward Entity Tests
/// ============================================================
///
/// Tests unitaires pour RewardEntity
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/features/rewards/domain/entities/reward_entity.dart';

void main() {
  group('RewardEntity', () {
    test('should create RewardEntity with all properties', () {
      // Arrange
      final reward = RewardEntity(
        id: 'reward-1',
        name: 'Free Coffee',
        description: 'Get a free coffee',
        pointsRequired: 100,
        storeId: 'store-1',
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      // Assert
      expect(reward.id, equals('reward-1'));
      expect(reward.name, equals('Free Coffee'));
      expect(reward.description, equals('Get a free coffee'));
      expect(reward.pointsRequired, equals(100));
      expect(reward.storeId, equals('store-1'));
      expect(reward.isActive, isTrue);
    });

    test(
      'isNew getter should return true for rewards created less than 7 days ago',
      () {
        // Arrange
        final recentReward = RewardEntity(
          id: 'reward-1',
          name: 'New Reward',
          pointsRequired: 50,
          storeId: 'store-1',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        // Assert
        expect(recentReward.isNew, isTrue);
      },
    );

    test(
      'isNew getter should return false for rewards created more than 7 days ago',
      () {
        // Arrange
        final oldReward = RewardEntity(
          id: 'reward-1',
          name: 'Old Reward',
          pointsRequired: 50,
          storeId: 'store-1',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        );

        // Assert
        expect(oldReward.isNew, isFalse);
      },
    );

    test('canRedeem should return true when client has enough points', () {
      // Arrange
      final reward = RewardEntity(
        id: 'reward-1',
        name: 'Test Reward',
        pointsRequired: 100,
        storeId: 'store-1',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(reward.canRedeem(150), isTrue);
      expect(reward.canRedeem(100), isTrue);
    });

    test(
      'canRedeem should return false when client has insufficient points',
      () {
        // Arrange
        final reward = RewardEntity(
          id: 'reward-1',
          name: 'Test Reward',
          pointsRequired: 100,
          storeId: 'store-1',
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(reward.canRedeem(50), isFalse);
        expect(reward.canRedeem(0), isFalse);
      },
    );

    test('canRedeem should return false when reward is inactive', () {
      // Arrange
      final inactiveReward = RewardEntity(
        id: 'reward-1',
        name: 'Inactive Reward',
        pointsRequired: 50,
        storeId: 'store-1',
        isActive: false,
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(inactiveReward.canRedeem(1000), isFalse);
    });

    test('should handle null description', () {
      // Arrange
      final reward = RewardEntity(
        id: 'reward-1',
        name: 'Test Reward',
        pointsRequired: 50,
        storeId: 'store-1',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(reward.description, isNull);
    });

    test('empty factory should create inactive reward', () {
      // Act
      final emptyReward = RewardEntity.empty();

      // Assert
      expect(emptyReward.id, isEmpty);
      expect(emptyReward.name, equals('Récompense inconnue'));
      expect(emptyReward.pointsRequired, equals(0));
      expect(emptyReward.isActive, isFalse);
    });

    test('two rewards with same id should be equal', () {
      // Arrange
      final reward1 = RewardEntity(
        id: 'reward-1',
        name: 'Reward 1',
        pointsRequired: 100,
        storeId: 'store-1',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final reward2 = RewardEntity(
        id: 'reward-1',
        name: 'Different Name',
        pointsRequired: 200,
        storeId: 'store-2',
        isActive: false,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(reward1, equals(reward2));
      expect(reward1.hashCode, equals(reward2.hashCode));
    });
  });
}
