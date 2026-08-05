import 'dart:math';

import 'package:flutter/foundation.dart';

enum RoadPhase { playing, failed, stageClear }

class GridSize {
  const GridSize(this.rows, this.cols);
  final int rows;
  final int cols;
  int get total => rows * cols;
  String get label => '${rows}x$cols';
}

class RoadToGloryController extends ChangeNotifier {
  RoadToGloryController({Random? random}) : _random = random ?? Random();

  static const grids = <GridSize>[
    GridSize(4, 5),
    GridSize(5, 6),
    GridSize(6, 7),
  ];

  static const initialBaseBatch = 2;

  final Random _random;

  int _gridIndex = 0;
  int _baseBatchSize = initialBaseBatch;
  int _batchSize = initialBaseBatch;
  int _boardsCleared = 0;
  final Set<int> _popped = {};
  final Set<int> _activeBatch = {};
  RoadPhase _phase = RoadPhase.playing;
  String? _banner;

  int get rows => grids[_gridIndex].rows;
  int get cols => grids[_gridIndex].cols;
  int get totalBubbles => grids[_gridIndex].total;
  int get batchSize => _batchSize;
  int get baseBatchSize => _baseBatchSize;
  int get gridIndex => _gridIndex;
  int get boardsCleared => _boardsCleared;
  String get gridLabel => grids[_gridIndex].label;
  Set<int> get popped => _popped;
  Set<int> get activeBatch => _activeBatch;
  RoadPhase get phase => _phase;
  String? get banner => _banner;
  int get remaining => totalBubbles - _popped.length;
  int get enlargeAt => (totalBubbles * 0.5).ceil();

  void start() {
    _gridIndex = 0;
    _baseBatchSize = initialBaseBatch;
    _batchSize = _baseBatchSize;
    _boardsCleared = 0;
    _restartBoard(deal: true);
  }

  /// Hard fail restart: same grid + batch size, empty board, new first batch.
  void restartStage() {
    _restartBoard(deal: true);
  }

  void clearBanner() {
    if (_banner == null) return;
    _banner = null;
    notifyListeners();
  }

  /// Returns true if the tap was a successful pop.
  bool onBubbleTapped(int bubbleId) {
    if (_phase != RoadPhase.playing) return false;

    if (!_activeBatch.contains(bubbleId)) {
      _phase = RoadPhase.failed;
      _activeBatch.clear();
      notifyListeners();
      return false;
    }

    _activeBatch.remove(bubbleId);
    _popped.add(bubbleId);

    if (_activeBatch.isEmpty) {
      if (_popped.length >= totalBubbles) {
        _onBoardCleared();
      } else {
        _dealNextBatch();
      }
    }

    notifyListeners();
    return true;
  }

  void _restartBoard({required bool deal}) {
    _popped.clear();
    _activeBatch.clear();
    _phase = RoadPhase.playing;
    _banner = null;
    if (deal) _dealNextBatch();
    notifyListeners();
  }

  void _dealNextBatch() {
    final pool = <int>[
      for (var i = 0; i < totalBubbles; i++)
        if (!_popped.contains(i)) i,
    ];
    pool.shuffle(_random);
    final take = min(_batchSize, pool.length);
    _activeBatch
      ..clear()
      ..addAll(pool.take(take));
  }

  void _onBoardCleared() {
    _phase = RoadPhase.stageClear;
    _boardsCleared += 1;

    if (_batchSize >= enlargeAt && _gridIndex < grids.length - 1) {
      _gridIndex += 1;
      _baseBatchSize += 1;
      _batchSize = _baseBatchSize;
      _banner = 'Grid grows! $gridLabel · batch ×$_batchSize';
    } else if (_batchSize >= enlargeAt && _gridIndex >= grids.length - 1) {
      _batchSize += 1;
      if (_batchSize > totalBubbles) _batchSize = totalBubbles;
      _banner = 'Batch size → $_batchSize';
    } else {
      _batchSize += 1;
      _banner = 'Batch size → $_batchSize';
    }

    _popped.clear();
    _activeBatch.clear();
    _phase = RoadPhase.playing;
    _dealNextBatch();
  }
}
