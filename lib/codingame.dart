// Copyright (c) 2016, Brian Grey. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:math';

//Common classes used in codingames
class Point {
    num x;
    num y;
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

    Point closer(Point a, Point b){
        return distance2(a) < distance2(b) ? a : b;
    }

    Point closestClamp(Point a, Point b){
        return closest(a, b, true);
    }

    Point closestNoClamp(Point a, Point b){
        return closest(a, b, false);
    }

    Point closest(Point a, Point b, bool clamp) {
        num atx = this.x - a.x;
        num aty = this.y - a.y;
        num abx = b.x - a.x;
        num aby = b.y - a.y;
        num det = abx * abx + aby * aby;
        num at_ab = atx*abx + aty*aby;
        num cx = 0;
        num cy = 0;

        if (det != 0) {
            num t = at_ab / det;
            if(clamp){
                t = t < 0 ? 0 : t;
                t = t > 1 ? 1: t;
            }
            cx = (a.x + abx * t);
            cy = (a.y + aby * t);
        } else {
            // The point is already on the line
            cx = this.x;
            cy = this.y;
        }

        return new Point(cx, cy);
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
