// Copyright (c) 2016, Brian Grey. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:math';

//Common classes used in codingames
class Point {
    int x;
    int y;
    Point parent;

    Point(this.x, this.y);

    String toString() { return "{$x,$y}"; }


    List<Point> get neighbors4 =>
        [
        new Point(x + 1, y),
        new Point(x - 1, y),
        new Point(x, y + 1),
        new Point(x, y - 1)
        ];

    List<Point> get neighbors8 =>
        [
        new Point(x + 1, y),
        new Point(x - 1, y),
        new Point(x, y + 1),
        new Point(x, y - 1),
        new Point(x + 1, y + 1),
        new Point(x - 1, y - 1),
        new Point(x - 1, y + 1),
        new Point(x + 1, y - 1)
        ];

    num distance(Point other) {
        return sqrt(distance2(other));
    }

    int distance2(Point other){
        int dx = x - other.x;
        int dy = y - other.y;
        return dx * dx + dy * dy;
    }

    // Override hashCode using strategy from Effective Java,
    // Chapter 11.
    int get hashCode {
        int result = 17;
        result = 37 * result + x;
        result = 37 * result + y;
        return result;
    }

    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Point) return false;
        Point point = other;
        return (point.x == x &&
            point.y == y);
    }
}

class Velocity {
    final Point first;
    final Point second;

    int dx;
    int dy;
    num dist;

    Velocity(this.first, this.second){
        dx = second.x - first.x;
        dy = second.y - first.y;
        dist = sqrt(dx * dx + dy * dy);
    }

    String toString() { return "$first to $second dx: $dx dy $dy dist $dist"; }
}
