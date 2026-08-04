import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pop_it/game/road_to_glory_controller.dart';

void main() {
  group('RoadToGloryController', () {
    test('starts with 4x5 batch of 2', () {
      final game = RoadToGloryController(random: Random(1))..start();
      expect(game.rows, 4);
      expect(game.cols, 5);
      expect(game.batchSize, 2);
      expect(game.baseBatchSize, 2);
      expect(game.activeBatch.length, 2);
      expect(game.phase, RoadPhase.playing);
    });

    test('correct tap pops and deals next from remaining', () {
      final game = RoadToGloryController(random: Random(2))..start();
      final first = game.activeBatch.first;
      expect(game.onBubbleTapped(first), isTrue);
      expect(game.popped.contains(first), isTrue);
      expect(game.activeBatch.length, 1);
      expect(game.activeBatch.contains(first), isFalse);
    });

    test('wrong tap fails the run', () {
      final game = RoadToGloryController(random: Random(3))..start();
      final active = Set<int>.from(game.activeBatch);
      final wrong =
          [for (var i = 0; i < 20; i++) i].firstWhere((i) => !active.contains(i));
      expect(game.onBubbleTapped(wrong), isFalse);
      expect(game.phase, RoadPhase.failed);
    });

    test('clearing the board increases batch size', () {
      final game = RoadToGloryController(random: Random(4))..start();
      while (game.batchSize == 2 && game.popped.length < 20) {
        final id = game.activeBatch.first;
        game.onBubbleTapped(id);
      }
      expect(game.batchSize, 3);
      expect(game.popped, isEmpty);
      expect(game.activeBatch.length, 3);
    });

    test('restartStage keeps batch size and clears board', () {
      final game = RoadToGloryController(random: Random(5))..start();
      while (game.batchSize == 2) {
        game.onBubbleTapped(game.activeBatch.first);
      }
      expect(game.batchSize, 3);
      game.onBubbleTapped(99);
      expect(game.phase, RoadPhase.failed);
      game.restartStage();
      expect(game.phase, RoadPhase.playing);
      expect(game.batchSize, 3);
      expect(game.popped, isEmpty);
      expect(game.activeBatch.length, 3);
    });

    test('enlarges grid and bumps base batch by 1', () {
      final game = RoadToGloryController(random: Random(6))..start();
      var guard = 0;
      while (game.gridIndex == 0 && game.batchSize < game.enlargeAt && guard < 2000) {
        guard++;
        final batch = Set<int>.from(game.activeBatch);
        for (final id in batch) {
          game.onBubbleTapped(id);
        }
      }
      while (game.gridIndex == 0 && guard < 4000) {
        guard++;
        final batch = Set<int>.from(game.activeBatch);
        for (final id in batch) {
          game.onBubbleTapped(id);
        }
      }
      expect(game.gridIndex, greaterThan(0));
      expect(game.baseBatchSize, 3);
      expect(game.batchSize, 3);
      expect(game.rows, 5);
      expect(game.cols, 6);
      expect(game.activeBatch.length, 3);
    });
  });
}
