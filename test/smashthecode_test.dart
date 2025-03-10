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
      List<Set<Point>> result = connectedColors(board);
      expect(result.isEmpty, true);
    });
    test('2 pairs', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(2, Cell.blue);
      List<Set<Point>> result = connectedColors(board);
      expect(result.isEmpty, false);
      expect(result.length, 2);
      expect(result[0].length, 2);
      expect(result[1].length, 2);
    });
  });

  group('validNeighbors:', () {
    test('empty board', () {
      var board = getEmptyBoard();
      var result = validNeighbors(board, new Point(0,0));
      expect(result.length, 2);
    });
    test('vertical pair', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(2, Cell.red);
      var result = validNeighbors(board, new Point(0,0));
      expect(result.length, 2);
      result = validNeighbors(board, new Point(1,0));
      expect(result.length, 3);
    });
    test('horizontal pair', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(1, Cell.red);
      var result = validNeighbors(board, new Point(0,0));
      expect(result.length, 2);
      result = validNeighbors(board, new Point(0,1));
      expect(result.length, 3);
    });
    test('three neighbors', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(2, Cell.red);
      board[2] = new List.filled(1, Cell.red);
      var result = validNeighbors(board, new Point(0,0));
      expect(result.length, 2);
      result = validNeighbors(board, new Point(0,1));
      expect(result.length, 3);
      result = validNeighbors(board, new Point(0,2));
      expect(result.length, 3);
    });
    test('four neighbors', () {
      var board = getEmptyBoard();
      //r r
      //r r r
      //r r
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(3, Cell.red);
      board[2] = new List.filled(2, Cell.red);
      var result = validNeighbors(board, new Point(0,0));
      expect(result.length, 2);
      result = validNeighbors(board, new Point(1,0));
      expect(result.length, 3);
      result = validNeighbors(board, new Point(0,1));
      expect(result.length, 3);
      result = validNeighbors(board, new Point(1,1));
      expect(result.length, 4);
      result = validNeighbors(board, new Point(2,1));
      expect(result.length, 4);
      result = validNeighbors(board, new Point(0,2));
      expect(result.length, 3);
      result = validNeighbors(board, new Point(1,2));
      expect(result.length, 4);
    });
  });

  group('connectedCounts:', () {
    test('empty board', () {
      var board = getEmptyBoard();
      var result = connectedCounts(board);
      expect(result[0], 0);
      expect(result[1], 0);
    });
    test('6 pairs', () {
      var board = getEmptyBoard();
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(2, Cell.blue);
      board[2] = new List.filled(2, Cell.yellow);
      board[3] = new List.filled(2, Cell.green);
      board[4] = new List.filled(2, Cell.pink);
      board[5] = new List.filled(2, Cell.red);
      var result = connectedCounts(board);
      expect(result[0], 12);
      expect(result[1], 0);
    });
    test('1 and 2', () {
      var board = getEmptyBoard();
      //r
      //r r
      board[0] = new List.filled(1, Cell.red);
      board[1] = new List.filled(2, Cell.red);
      //printBoard(board);

      var result = connectedCounts(board);
      expect(result[0], 2);
      expect(result[1], 1);
    });
    test('2 and 1', () {
      var board = getEmptyBoard();
      //r r
      //r
      board[0] = new List.filled(2, Cell.red);
      board[1] = new List.filled(1, Cell.red);
      //printBoard(board);

      var result = connectedCounts(board);
      expect(result[0], 2);
      expect(result[1], 1);
    });
  });

}

List<List<Cell>> getEmptyBoard() { return new List.generate(6, (int index) => []); }
