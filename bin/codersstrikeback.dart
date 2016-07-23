import 'dart:io';
import 'dart:math';

List<Checkpoint> checkpoints = [];
List<int> lastCPs = [1, 1];
List<int> lapCounts = [0, 0];

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    int laps = int.parse(stdin.readLineSync());
    stderr.writeln("Laps $laps");
    int cpCount = int.parse(stdin.readLineSync());

    for(int i = 0; i < cpCount; i++){
        inputs = stdin.readLineSync().split(' ');
        int checkpointX = int.parse(inputs[0]); // x position of the next check point
        int checkpointY = int.parse(inputs[1]); // y position of the next check point
        checkpoints.add(new Checkpoint(i, checkpointX, checkpointY));
    }


    bool boostUsed = false;
    List<Pod> pods = new List(4);

    // game loop
    while (true) {
        for(int index = 0; index < 4; index ++){
            inputs = stdin.readLineSync().split(' ')
                .map((s) => int.parse(s)).toList();
            pods[index] = new Pod(index, inputs[0], inputs[1],
                inputs[2], inputs[3], inputs[4], inputs[5]);
        }

        pods[0].partner = pods[1];
        pods[1].partner = pods[0];

        pods[2].partner = pods[3];
        pods[3].partner = pods[2];

        //update lap count
        [0, 1].forEach((index) {
            if(pods[index + 2].nextCP == 1 &&
                lastCPs[index] != 1) {
                    lapCounts[index] += 1;
                }
            lastCPs[index] = pods[index + 2].nextCP;
        });

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');


        // You have to output the target position
        // followed by the power (0 <= thrust <= 100)
        // i.e.: "x y thrust"

        //set target to nextCP - 3xVelocity vector
        List<Point> targets = new List(2);
        Point nextCP = checkpoints[pods[0].nextCP];
        targets[0] = new Point(
            nextCP.x - pods[0].vx * 3,
            nextCP.y - pods[0].vy * 3);

        //determine target enemy pod
        Pod targetPod;
        if(lapCounts[0] != lapCounts[1]){
            targetPod = lapCounts[0] > lapCounts[1] ? pods[2] : pods[3];
        } else if(pods[2].nextCP != pods[3].nextCP){
            int pod2CP = pods[2].nextCP != 0 ? pods[2].nextCP : 10;
            int pod3CP = pods[3].nextCP != 0 ? pods[3].nextCP : 10;
            targetPod = pod2CP > pod3CP ? pods[2] : pods[3];
        } else {
            num pod2dist = pods[2].distance2(checkpoints[pods[2].nextCP]);
            num pod3dist = pods[3].distance2(checkpoints[pods[3].nextCP]);
            targetPod = pod2dist < pod3dist ? pods[2] : pods[3];
        }
        // nextCP = checkpoints[pods[1].nextCP];
        // targets[1] = new Point(
        //     nextCP.x - pods[1].vx * 3,
        //     nextCP.y - pods[1].vy * 3);
        bool harassShield = false;
        Collision col1 = pods[1].collision(pods[2]);
        Collision col2 = pods[1].collision(pods[3]);
        if(col1 != null || col2 != null){
            harassShield = true;
        }

        targets[1] = new Point(
            checkpoints[targetPod.nextCP].x -
            pods[1].vx * 3,
            checkpoints[targetPod.nextCP].y -
            pods[1].vy * 3
            );

        //prediction test
        stderr.writeln("Pod 0 start: ${pods[0].x} ${pods[0].y} ${pods[0].vx} ${pods[0].vy} ${pods[0].angle}");
        pods[0].play(targets[0], 100);
        stderr.writeln("Pod 0 prediction: ${pods[0].x} ${pods[0].y} ${pods[0].vx} ${pods[0].vy} ${pods[0].angle}");

        Point target = targets[0];
        num nextCheckpointAngle = pods[0].diffAngle(target);
        num nextCheckpointDist2 = pods[0].distance2(target);
        stderr.writeln("Next CP angle: $nextCheckpointAngle");
        stderr.writeln("Next CP Dist2: $nextCheckpointDist2");

        if(!boostUsed &&
            nextCheckpointAngle.abs() < 2 &&
            nextCheckpointDist2 > (5000 * 5000)){
            boostUsed = true;
            print("${target.x} ${target.y} BOOST");
        } else if(nextCheckpointAngle.abs() > 20){
            int thrust = thrustSigmoid(nextCheckpointAngle);
            print("${target.x} ${target.y} $thrust");
        } else if( nextCheckpointDist2 < 700 * 700){
            print("${target.x} ${target.y} 30");
        } else if( nextCheckpointDist2 < 650 * 650){
            print("${target.x} ${target.y} 50");
        } else {
            print("${target.x} ${target.y} 100");
        }

        if(!harassShield){
            print("${targets[1].x} ${targets[1].y} 100");
        } else {
            print("${targets[1].x} ${targets[1].y} SHIELD");
        }
    }
}

class Point {
    num x;
    num y;
    Point(this.x, this.y);

    String toString() { return "{$x,$y}"; }

    num distance(Point other) {
        return sqrt(distance2(other));
    }

    num distance2(Point other) {
        var dx = x - other.x;
        var dy = y - other.y;
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

abstract class Unit extends Point {
    int id;
    num radius;
    num vx;
    num vy;
    Unit(this.id, num x, num y, this.vx, this.vy) : super(x, y);

    void bounce(Unit u);

    Collision collision(Unit u) {
        // Square of the distance
        num dist = distance2(u);

        // Sum of the radii squared
        num sr = (this.radius + u.radius)*(this.radius + u.radius);

        // We take everything squared to avoid calling sqrt uselessly. It is better for performances

        if (dist < sr) {
            // Objects are already touching each other. We have an immediate collision.
            return new Collision(this, u, 0.0);
        }

        // Optimisation. Objects with the same speed will never collide
        if (this.vx == u.vx && this.vy == u.vy) {
            return null;
        }

        // We place ourselves in the reference frame of u. u is therefore stationary and is at (0,0)
        num x = this.x - u.x;
        num y = this.y - u.y;
        Point myp = new Point(x, y);
        num vx = this.vx - u.vx;
        num vy = this.vy - u.vy;
        Point up = new Point(0, 0);

        // We look for the closest point to u (which is in (0,0)) on the line described by our speed vector
        Point p = up.closestNoClamp(myp, new Point(x + vx, y + vy));

        // Square of the distance between u and the closest point to u on the line described by our speed vector
        num pdist = up.distance2(p);

        // Square of the distance between us and that point
        num mypdist = this.distance2(p);

        // If the distance between u and this line is less than the sum of the radii, there might be a collision
        if (pdist < sr) {
         // Our speed on the line
            num length = sqrt(vx*vx + vy*vy);

            // We move along the line to find the point of impact
            num backdist = sqrt(sr - pdist);
            p.x = p.x - backdist * (vx / length);
            p.y = p.y - backdist * (vy / length);

            // If the point is now further away it means we are not going the right way, therefore the collision won't happen
            if (this.distance2(p) > mypdist) {
                return null;
            }

            pdist = p.distance(myp);

            // The point of impact is further than what we can travel in one turn
            if (pdist > length) {
                return null;
            }

            // Time needed to reach the impact point
            num t = dist / length;

            return new Collision(this, u, t);
        }

        return null;
    }


}

class Pod extends Unit {
    int nextCP;
    num angle;
    Pod partner;
    int timeout = 100;
    bool shield = false;

    Pod(int id, num x, num y,
        num vx, num vy, this.angle, this.nextCP) :
        super(id, x, y, vx, vy){
        radius =  400;
        // stderr.writeln(this);
    }

    String toString() { return "Pod: $id timeout $timeout shield $shield at ${super.toString()} to [$vx, $vy]"; }

    Pod clone(){
        Pod clone = new Pod(this.id, this.x, this.y,
            this.vx, this.vy, this.angle, this.nextCP);
        clone.timeout = this.timeout;
        clone.shield = this.shield;
        clone.partner = this.partner;

        return clone;
    }

    num getAngle(Point p) {
        num d = this.distance(p);
        num ax = (p.x - this.x) / d;
        num ay = (p.y - this.y) / d;

        // Simple trigonometry. We multiply by 180.0 / PI to convert radians to degrees.
        num a = acos(ax) * 180.0 / PI;

        // If the point I want is below me, I have to shift the angle for it to be correct
        if (ay < 0) {
            a = 360.0 - a;
        }

        return a;
    }

    num diffAngle(Point p) {
        num a = this.getAngle(p);

        // To know whether we should turn clockwise or not we look at the two ways and keep the smallest
        // The ternary operators replace the use of a modulo operator which would be slower
        num right = this.angle <= a ? a - this.angle : 360.0 - this.angle + a;
        num left = this.angle >= a ? this.angle - a : this.angle + 360.0 - a;

        if (right < left) {
            return right;
        } else {
            // We return a negative angle if we must rotate to left
            return -left;
        }
    }

    void rotate(Point p) {
        num a = this.diffAngle(p);

        // Can't turn by more than 18° in one turn
        if (a > 18.0) {
            a = 18.0;
        } else if (a < -18.0) {
            a = -18.0;
        }

        this.angle += a;

        // The % operator is slow. If we can avoid it, it's better.
        if (this.angle >= 360.0) {
            this.angle = this.angle - 360.0;
        } else if (this.angle < 0.0) {
            this.angle += 360.0;
        }
    }

    void boost(int thrust) {
      // Don't forget that a pod which has activated its shield cannot accelerate for 3 turns
        if (this.shield) {
            return;
        }

        // Conversion of the angle to radiants
        num ra = this.angle * PI / 180.0;

        // Trigonometry
        this.vx += cos(ra) * thrust;
        this.vy += sin(ra) * thrust;
    }

    void move(num t) {
        this.x += this.vx * t;
        this.y += this.vy * t;
    }

    void end() {
        this.x = this.x.round();
        this.y = this.y.round();
        this.vx = (this.vx * 0.85).truncate();
        this.vy = (this.vy * 0.85).truncate();
        this.angle = this.angle.round();

        // Don't forget that the timeout goes down by 1 each turn. It is reset to 100 when you pass a checkpoint
        this.timeout -= 1;
    }

    void play(Point p, int thrust) {
        this.rotate(p);
        this.boost(thrust);
        this.move(1.0);
        this.end();
    }

    void bounce(Unit unit) {
        if (Unit is Checkpoint) {
            // Collision with a checkpoint
            this.bounceWithCheckpoint(unit);
        } else {
            Pod u = unit as Pod;
            // If a pod has its shield active its mass is 10 otherwise it's 1
            num m1 = this.shield ? 10 : 1;
            num m2 = u.shield ? 10 : 1;
            num mcoeff = (m1 + m2) / (m1 * m2);

            num nx = this.x - u.x;
            num ny = this.y - u.y;

            // Square of the distance between the 2 pods. This value could be hardcoded because it is always 800²
            num nxnysquare = nx*nx + ny*ny;

            num dvx = this.vx - u.vx;
            num dvy = this.vy - u.vy;

            // fx and fy are the components of the impact vector. product is just there for optimisation purposes
            num product = nx*dvx + ny*dvy;
            num fx = (nx * product) / (nxnysquare * mcoeff);
            num fy = (ny * product) / (nxnysquare * mcoeff);

            // We apply the impact vector once
            this.vx -= fx / m1;
            this.vy -= fy / m1;
            u.vx += fx / m2;
            u.vy += fy / m2;

            // If the norm of the impact vector is less than 120, we normalize it to 120
            num impulse = sqrt(fx*fx + fy*fy);
            if (impulse < 120.0) {
                fx = fx * 120.0 / impulse;
                fy = fy * 120.0 / impulse;
            }

            // We apply the impact vector a second time
            this.vx -= fx / m1;
            this.vy -= fy / m1;
            u.vx += fx / m2;
            u.vy += fy / m2;

            // This is one of the rare places where a Vector class would have made the code more readable.
            // But this place is called so often that I can't pay a performance price to make it more readable.
        }
    }

    void bounceWithCheckpoint(Checkpoint u){
        this.timeout = 100;
        if(u.id == this.nextCP){
            this.nextCP =
            (this.nextCP + 1) % checkpoints.length;
        }

    }
}

class Checkpoint extends Unit {
    Checkpoint(num id, num x, num y) : super(id, x, y, 0, 0){
        radius = 600;
    }

    int get hashCode {
        int result = 17;
        result = 37 * result + x;
        result = 37 * result + y;
        result = 37 * result + id;
        return result;
    }

    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Checkpoint) return false;
        Checkpoint point = other;
        return (point.x == x &&
            point.y == y &&
            point.id == id);
    }

    String toString() { return "CP: $id at ${super.toString()}"; }

    void bounce(Unit u){

    }
}

class Collision {
    Unit a;
    Unit b;
    num t;

    Collision(this.a, this.b, this.t);

    String toString() { return "$a will collide $b at time $t"; }
}

class Velocity {
    final Point first;
    final Point second;

    num dx;
    num dy;

    Velocity(this.first, this.second){
        dx = second.x - first.x;
        dy = second.y - first.y;
    }

    num get dist  => sqrt(dx * dx + dy * dy);
    num get dist2 => dx * dx + dy * dy;

    String toString() { return "$first to $second dx: $dx dy $dy dist $dist"; }
}

int thrustSigmoid(num angle){
    num steepness = 0.1;
    num exp = -1 * steepness * (angle.abs() - 30);
    num thrust = 100 * (1 - ( 1 / (1 + pow(E, exp))));
    return thrust.round();
}
