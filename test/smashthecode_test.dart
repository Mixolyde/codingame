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
      Move move0 = new Move(0, 0);
      Move move1 = new Move(0, 1);
      Move move2 = new Move(1, 2);
      Move move3 = new Move(0, 3);
      expect(move0.isValid(board), true);
      expect(move1.isValid(board), true);
      expect(move2.isValid(board), true);
      expect(move3.isValid(board), true);
      board[0] = new List.filled(10, Cell.red);
      expect(move0.isValid(board), true);
      expect(move1.isValid(board), true);
      expect(move2.isValid(board), true);
      expect(move3.isValid(board), true);

      board[0] = new List.filled(11, Cell.red);
      expect(move0.isValid(board), true);
      expect(move1.isValid(board), false);
      expect(move2.isValid(board), true);
      expect(move3.isValid(board), false);

      board[0] = new List.filled(12, Cell.red);
      expect(move0.isValid(board), false);
      expect(move1.isValid(board), false);
      expect(move2.isValid(board), false);
      expect(move3.isValid(board), false);


    });

  });

  group('connected colors:', () {
    test('empty board', () {
      var board = getEmptyBoard();
      Map<int, Set<Point>> result = connectedColors(board);
      expect(result.isEmpty, true);
    });
    test('1 pair', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(1, Cell.blue);
      Map<int, Set<Point>> result = connectedColors(board);
      expect(result.isEmpty, false);
      expect(result.keys.length, 2);
      expect(result[0].length, 1);
      expect(result[1].length, 1);
    });
  });

  group('validNeighbors:', () {
    test('empty board', () {
      var board = getEmptyBoard();
      var result = validNeighbors(new Point(0,0), board);
      expect(result.length, 0);
    });
    test('vertical pair', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(2, Cell.red);
      var result = validNeighbors(new Point(0,0), board);
      expect(result.length, 1);
      result = validNeighbors(new Point(1,0), board);
      expect(result.length, 1);
    });
    test('horizontal pair', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(1, Cell.red);
      var result = validNeighbors(new Point(0,0), board);
      expect(result.length, 1);
      result = validNeighbors(new Point(0,1), board);
      expect(result.length, 1);
    });
    test('three neighbors', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(2, Cell.red);
      board[2] = new List.filled(1, Cell.red);
      var result = validNeighbors(new Point(0,0), board);
      expect(result.length, 1);
      result = validNeighbors(new Point(0,1), board);
      expect(result.length, 3);
      result = validNeighbors(new Point(0,2), board);
      expect(result.length, 1);
    });
    test('four neighbors', () {
      var board = getEmptyBoard();
      //r r
      //r r r
      //r r
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(3, Cell.red);
      board[2] = new List.filled(2, Cell.red);
      var result = validNeighbors(new Point(0,0), board);
      expect(result.length, 2);
      result = validNeighbors(new Point(1,0), board);
      expect(result.length, 2);
      result = validNeighbors(new Point(0,1), board);
      expect(result.length, 3);
      result = validNeighbors(new Point(1,1), board);
      expect(result.length, 4);
      result = validNeighbors(new Point(2,1), board);
      expect(result.length, 1);
      result = validNeighbors(new Point(0,2), board);
      expect(result.length, 2);
      result = validNeighbors(new Point(1,2), board);
      expect(result.length, 2);
    });
  });

  group('threeConnectedCount:', () {
    test('empty board', () {
      var board = getEmptyBoard();
      int result = threeConnectedCount(board);
      expect(result, 0);
    });
    test('6 pairs', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(2, Cell.blue);
      board[2] = new List.filled(2, Cell.yellow);
      board[3] = new List.filled(2, Cell.green);
      board[4] = new List.filled(2, Cell.pink);
      board[5] = new List.filled(2, Cell.red);
      int result = threeConnectedCount(board);
      expect(result, 0);
    });
    test('1 and 2', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(2, Cell.red);
      printBoard(board);

      int result = threeConnectedCount(board);
      expect(result, 1);
    });
    test('2 and 1', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(1, Cell.red);
      printBoard(board);

      int result = threeConnectedCount(board);
      expect(result, 1);
    });
  });

}

List<List<Cell>> getEmptyBoard() { return new List.generate(6, (int index) => new List<Cell>()); }
