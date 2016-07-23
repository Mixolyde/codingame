// Copyright (c) 2016, Brian Grey. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:codingame/codingame.dart';
import 'package:test/test.dart';

enum Dir {up, right, down, left}

void main() {
  test('equal points', () {
    Point a = new Point(3, 4);
    Point b = new Point(3, 4);
    expect(true, a == b);
  });
  test('4 neighbors', () {
    Point a = new Point(3, 4);
    var neighbors = a.neighbors4;
    expect(4, neighbors.length);
    expect(true, neighbors.contains(new Point(2, 4)));
    expect(true, neighbors.contains(new Point(4, 4)));
    expect(true, neighbors.contains(new Point(3, 3)));
    expect(true, neighbors.contains(new Point(3, 5)));
  });
  test('8 neighbors', () {
    Point a = new Point(3, 4);
    var neighbors = a.neighbors8;
    expect(8, neighbors.length);
    expect(true, neighbors.contains(new Point(2, 4)));
    expect(true, neighbors.contains(new Point(4, 4)));
    expect(true, neighbors.contains(new Point(3, 3)));
    expect(true, neighbors.contains(new Point(3, 5)));
  });

  test('distance2', () {
    Point a = new Point(3, 4);
    expect(a.distance2(new Point(5, 6)), 8);
  });
  test('distance', () {
    Point a = new Point(3, 4);
    expect(a.distance(new Point(6, 8)), 5);
    expect(a.distance(new Point(0, 0)), 5);
  });
  test('distance', () {
    Point a = new Point(3, 4);
    expect(a.closer(new Point(0, 0), new Point(4, 4)), new Point(4, 4));
  });
  test('closest on endpoint', () {
    Point a = new Point(0, 0);
    expect(a.closest(new Point(0, 0), new Point(4, 4), true), new Point(0, 0));
    expect(a.closest(new Point(0, 0), new Point(4, 4), false), new Point(0, 0));

    a = new Point(4, 4);
    expect(a.closest(new Point(0, 0), new Point(4, 4), true), new Point(4, 4));
    expect(a.closest(new Point(0, 0), new Point(4, 4), false), new Point(4, 4));
  });
  test('closest on line', () {
    Point a = new Point(2, 2);
    expect(a.closest(new Point(0, 0), new Point(4, 4), true), new Point(2, 2));
    expect(a.closest(new Point(0, 0), new Point(4, 4), false), new Point(2, 2));
  });
  
}
