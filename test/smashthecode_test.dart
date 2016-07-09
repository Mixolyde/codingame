// Copyright (c) 2016, Brian Grey. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../bin/smashthecode.dart';
import 'package:test/test.dart';

enum Dir {up, right, down, left}

void main() {
  group('points:', () {
    test('2 points are equal', () {
      Point a = new Point(3, 4);
      Point b = new Point(3, 4);
      expect(a == b, equals(true));
    });
    test('points have 4 neighbors4', () {
      Point a = new Point(3, 4);
      var neighbors = a.neighbors4;
      expect(4, neighbors.length);
      expect(neighbors.contains(new Point(2, 4)), equals(true));
      expect(neighbors.contains(new Point(4, 4)), equals(true));
      expect(neighbors.contains(new Point(3, 3)), equals(true));
      expect(neighbors.contains(new Point(3, 5)), equals(true));
    });
  });

  group('pairs:', () {
    test('non-matching pair has 22 moves', () {
      Pair a = new Pair(Cell.red, Cell.blue);
      expect(a.allMoves().length, equals(22));
    });
    test('matching pair has 11 moves', () {
      Pair a = new Pair(Cell.red, Cell.red);
      expect(a.allMoves().length, equals(11));
    });
  });

  group('moves:', () {
    test('is valid', () {
      var board = getEmptyBoard();
      Move move = new Move(0, 3);
      expect(move.isValid(board), true);

      board[0] = new List.filled(11, Cell.red);
      expect(move.isValid(board), false);
    });

  });

}

List<List<Cell>> getEmptyBoard() { return new List.generate(6, (int index) => new List<Cell>()); }
