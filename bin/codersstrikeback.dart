import 'dart:collection';
import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

List<Checkpoint> checkpoints = [];
List<int> lastCPs = [1, 1, 1, 1];

int cpGoal = 0;
int cpCount = 0;
Random rand = new Random(2);
int turn = 0;
Solution? lastSolution = null;
int MYH_SQUARED = 250 * 250;
int totalEvals = 0;

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    int laps = int.parse(readLineSync());
    cpCount = int.parse(readLineSync());

    cpGoal = laps * cpCount;
    stderr.writeln("Laps $laps CPs $cpCount Goal: $cpGoal");

    for(int i = 0; i < cpCount; i++){
        inputs = readLineSync().split(' ');
        int checkpointX = int.parse(inputs[0]); // x position of the next check point
        int checkpointY = int.parse(inputs[1]); // y position of the next check point
        checkpoints.add(new Checkpoint(i, checkpointX, checkpointY));
    }

    List<Pod> pods = List<Pod>.generate(4, (_) => 
      Pod(-1, 0, 0, 0, 0, 0, 0), growable:false);

    // game loop
    while (true) {
        if(pods[0].id == -1){
            for(int index = 0; index < 4; index ++){
                inputs = readLineSync().split(' ')
                    .map((s) => int.parse(s)).toList();
                pods[index] = new Pod(index, inputs[0], inputs[1],
                    inputs[2], inputs[3], inputs[4], inputs[5]);
            }

            pods[0].partner = pods[1];
            pods[1].partner = pods[0];

            pods[2].partner = pods[3];
            pods[3].partner = pods[2];
        } else {
            for(int index = 0; index < 4; index ++){
                inputs = readLineSync().split(' ')
                    .map((s) => int.parse(s)).toList();
                pods[index].x = inputs[0];
                pods[index].y = inputs[1];
                pods[index].vx = inputs[2];
                pods[index].vy = inputs[3];
                pods[index].angle = inputs[4];
                pods[index].nextCP = inputs[5];
            }

        }

        Stopwatch globalSW = new Stopwatch();
        globalSW.start();

        //update checked count
        [0, 1, 2, 3].forEach((index) {
            if(pods[index].nextCP != lastCPs[index]){
                pods[index].checked++;
                pods[index].timeout = 100;
                pods[index].partner.timeout = 100;
            }

            lastCPs[index] = pods[index].nextCP;
        });

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        printPods(pods);

        // You have to output the target position
        // followed by the power (0 <= thrust <= 200)
        // i.e.: "x y thrust"

        if(turn == 0 && pods[0].distance2(checkpoints[1]) > 3000 * 3000){
            print("${checkpoints[1].x} ${checkpoints[1].y} BOOST 1st turn boost");
            print("${checkpoints[1].x} ${checkpoints[1].y} BOOST 1st turn boost");

        } else {

            int solLength = 6;
            
            //monte carlo the enemy players for a bit
            List<Pod> enemiesFirst = [pods[2], pods[3], pods[0], pods[1]];
            Solution enemySol = genetic(enemiesFirst, solLength, 15, null, null);

            stderr.writeln("GlobalSW before friendly solve: ${globalSW.elapsedMilliseconds}");

            Solution gen = genetic(pods, solLength, 25, lastSolution, enemySol);
            lastSolution = gen;

            stderr.writeln("GlobalSW after friendly solve: ${globalSW.elapsedMilliseconds}");
            stderr.writeln("Eval average: ${totalEvals / (turn + 1)}");
            // stderr.writeln("Genetic eval: ${gen.score(pods)}");

            pods[0].output(gen.moves0[0]);
            pods[1].output(gen.moves1[0]);
        }

        [0, 1, 2, 3].forEach((index) {
            pods[index].timeout -= 1;
        });

        [0, 1].forEach((index) {
            Pod pod = pods[index];

            if(pod.shield){
                if(pod.shieldTimeout <= 0){
                    pod.shield = false;
                    pod.shieldTimeout = 0;
                } else {
                    pod.shieldTimeout--;
                }
            }
        });

        turn++;
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
        result = 37 * result + x.toInt();
        result = 37 * result + y.toInt();
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
    num radius = 0;
    num vx;
    num vy;
    Unit(this.id, num x, num y, this.vx, this.vy) : super(x, y);

    void bounce(Unit u);

    Collision? collision(Unit u) {
        // Square of the distance
        num dist = distance2(u);

        // Sum of the radii squared
        num sr = (this.radius + u.radius)*(this.radius + u.radius);

        // We take everything squared to avoid calling sqrt uselessly. It is better for performances

        if (dist < sr) {
            // Objects are already touching each other. We have an immediate
            // collision.
            return new Collision(this, u, 0.0);
        }

        // Optimisation. Objects with the same speed will never collide
        if (this.vx == u.vx && this.vy == u.vy) {
            return null;
        }

        // We place ourselves in the reference frame of u. u is therefore
        // stationary and is at (0,0)
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
        num mypdist = myp.distance2(p);

        // If the distance between u and this line is less than the sum of the radii, there might be a collision
        if (pdist < sr) {
            // Our speed on the line
            num length = sqrt(vx*vx + vy*vy);

            // We move along the line to find the point of impact
            num backdist = sqrt(sr - pdist);
            p.x = p.x - backdist * (vx / length);
            p.y = p.y - backdist * (vy / length);

            // If the point is now further away it means we are not going
            // the right way, therefore the collision won't happen
            if (myp.distance2(p) > mypdist) {
                return null;
            }

            pdist = p.distance(myp);

            // The point of impact is further than what we can travel in one turn
            if (pdist > length) {
                return null;
            }

            // Time needed to reach the impact point
            num t = pdist / length;

            return new Collision(this, u, t);
        }

        return null;
    }


}

class Pod extends Unit {
    int nextCP;
    num angle;
    late Pod partner;
    int timeout = 100;
    bool shield = false;
    int shieldTimeout = 0;
    int checked = 0;
    bool boostUsed = false;

    Pod(int id, num x, num y,
        num vx, num vy, this.angle, this.nextCP) :
        super(id, x, y, vx, vy){
        radius =  400;
        // stderr.writeln(this);
    }

    String toString() { return "Pod: $id checked $checked timeout $timeout shield $shield at ${super.toString()} to [${vx.truncate()}, ${vy.truncate()}]"; }

    //TODO XYsetters that check for infity/nan
    
    Pod clone(){
        Pod clone = new Pod(this.id, this.x, this.y,
            this.vx, this.vy, this.angle, this.nextCP);
        clone.timeout = this.timeout;
        clone.shield = this.shield;
        clone.shieldTimeout = this.shieldTimeout;
        clone.checked = this.checked;
        clone.boostUsed = this.boostUsed;

        return clone;
    }

    num getAngle(Point p) {
        num d = this.distance(p);
        num ax = (p.x - this.x) / d;
        num ay = (p.y - this.y) / d;

        // Simple trigonometry. We multiply by 180.0 / pi to convert radians to degrees.
        num a = acos(ax) * 180.0 / pi;

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
        num ra = this.angle * pi / 180.0;

        // Trigonometry
        this.vx += cos(ra) * thrust;
        this.vy += sin(ra) * thrust;
    }

    void move(num t) {
        this.x += this.vx * t;
        this.y += this.vy * t;
    }

    void activateShield(){
        shield = true;
        shieldTimeout = 3;
    }

    void end() {
        this.x = this.x.round();
        this.y = this.y.round();
        this.vx = (this.vx * 0.85).truncate();
        this.vy = (this.vy * 0.85).truncate();
        this.angle = this.angle.round();

        // Don't forget that the timeout goes down by 1 each turn. It is reset to 100 when you pass a checkpoint
        this.timeout -= 1;

        if(shield){
            if(this.shieldTimeout <= 0){
                shield = false;
                shieldTimeout = 0;
            } else {
                shieldTimeout--;
            }
        }
    }

    void play(Point p, int thrust) {
        this.rotate(p);
        this.boost(thrust);
        this.move(1.0);
        this.end();
    }

    void bounce(Unit unit) {
        if (unit is Checkpoint) {
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
        if(u.id == this.nextCP){
            this.nextCP =
            (this.nextCP + 1) % cpCount;
            this.timeout = 100;
            this.partner.timeout = 100;
            this.checked += 1;
        }

    }

    void apply(Move move){
        //apply the angle change and thrust, but don't move
        num a = move.angle;
        if(a < -18){
            a = -18;
        }
        if(a > 18){
            a = 18;
        }

        this.angle += a;

        // The % operator is slow. If we can avoid it, it's better.
        if (this.angle >= 360.0) {
            this.angle = this.angle - 360.0;
        } else if (this.angle < 0.0) {
            this.angle += 360.0;
        }

        if(move.thrust >= 0){
            this.boost(move.thrust);
        } else if (!shield) {
            this.activateShield();
        }
    }

    void output(Move move) {
        num a = angle + move.angle;

        if (a >= 360.0) {
            a = a - 360.0;
        } else if (a < 0.0) {
            a += 360.0;
        }

        // Look for a point corresponding to the angle we want
        // Multiply by 10000.0 to limit rounding errors
        a = a * pi / 180.0;
        num px = this.x + cos(a) * 10000.0;
        num py = this.y + sin(a) * 10000.0;

        if (move.shield) {
            print("${px.round()} ${py.round()} SHIELD Shield");
            activateShield();
        } else {
            print("${px.round()} ${py.round()} ${move.thrust} $id ${move.thrust}");
        }
    }

    num score() {
        return checked*50000 - this.distance(checkpoints[this.nextCP]);
    }
}

class Checkpoint extends Unit {
    Checkpoint(int id, num x, num y) : super(id, x, y, 0, 0){
        radius = 200;
    }

    int get hashCode {
        int result = 17;
        result = 37 * result + x.toInt();
        result = 37 * result + y.toInt();
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

    bool ignorable(Collision other) {
        return other.t == 0 &&
        ((a.id == other.a.id && b.id == other.b.id) ||
         (a.id == other.b.id && b.id == other.a.id));
    }

    int get hashCode {
        int result = 17;
        result = 37 * result + a.id + b.id;
        result = 37 * result + t.toInt();
        return result;
    }

    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Collision) return false;
        Collision col = other;
        return col.t == t &&
            ((col.a.id == a.id && col.b.id == b.id) ||
             (col.b.id == a.id && col.a.id == b.id) );
    }
}

class Move {
    num angle; //damped to -18.0 to 18
    int thrust; //damped to -1 to 200 (-1 means activate shield)

    double SHIELD_PROB = .05;

    Move(this.angle, this.thrust);

    String toString() => "Move: ${angle.truncate()} $thrust";

    Move clone() => new Move(this.angle, this.thrust);

    bool get shield => thrust < 0;

    void mutate(num amplitude) {
        num ramin = this.angle - 36.0 * amplitude;
        num ramax = this.angle + 36.0 * amplitude;

        if (ramin < -18.0) {
            ramin = -18.0;
        }

        if (ramax > 18.0) {
            ramax = 18.0;
        }

        angle = rand.nextDouble() * (ramax - ramin) + ramin;

        if (!this.shield && rand.nextDouble() < SHIELD_PROB) {
            this.thrust = -1;
        } else {
            int pmin = this.thrust - (200 * amplitude).truncate();
            int pmax = this.thrust + (200 * amplitude).truncate();

            if (pmin < 0) {
                pmin = 0;
            }

            if (pmax > 0) {
                pmax = 200;
            }

            this.thrust = rand.nextInt(pmax - pmin) + pmin;

            // this.shield = false;
        }
    }
}

class Solution {
    List<Move> moves0;
    List<Move> moves1;
    List<Move> moves2;
    List<Move> moves3;

    num MOVE_MUTATE_RATE = .5;


    Solution(this.moves0, this.moves1, this.moves2, this.moves3);

    String toString() => "Move list lengths: [${moves0.length}, ${moves1.length}, ${moves2.length}, ${moves3.length}]\nMoves0: $moves0";

    Solution clone() =>
        new Solution(
            moves0.map((move) => move.clone()).toList(),
            moves1.map((move) => move.clone()).toList(),
            moves2.map((move) => move.clone()).toList(),
            moves3.map((move) => move.clone()).toList()
            );

    num score(List<Pod> startPods) {
        var pods = clonePods(startPods);
        
        num result = 0;

        // Play out the turns
        for (int i = 0; i < moves0.length; ++i) {
            // Apply the moves to the pods before playing

            pods[0].apply(moves0[i]);
            pods[1].apply(moves1[i]);
            pods[2].apply(moves2[i]);
            pods[3].apply(moves3[i]);

            play(pods, checkpoints);
            
            result += evaluation(pods) * pow(.8, i);
        }

        // Compute the score
        // num result = evaluation(pods);

        return result;
    }

    num evaluation(List<Pod> pods){
        if (pods[2].checked >= cpGoal ||
            pods[3].checked >= cpGoal ||
            pods[0].timeout <= 1 ||
            pods[1].timeout <= 1){
            return double.negativeInfinity;
        }
        if (pods[0].checked >= cpGoal ||
            pods[1].checked >= cpGoal ||
            pods[2].timeout <= 1 ||
            pods[3].timeout <= 1){
            return double.infinity;
        }

        Pod myRunner = pods[0].score() > pods[1].score() ? pods[0] : pods[1];
        //TODO factor in harassers?
        //Pod myHarasser = myRunner.partner;

        Pod oppRunner = pods[2].score() > pods[3].score() ? pods[2] : pods[3];
        //Pod oppHarasser = oppRunner.partner;

        num score = 0;
        score += (myRunner.score() - oppRunner.score());
        // score += (myHarasser.score() - oppRunner.score());
        
        Point oppCP = checkpoints[oppRunner.nextCP];
        // num cpRange = 250;
        // num dx = oppRunner.x - oppCP.x; 
        // num dy = oppRunner.y - oppCP.y; 
        // num length = sqrt(dx * dx + dy * dy);
        // num scale = cpRange / length;
        // num scaled_x = scale * dx;
        // num scaled_y = scale * dy;

        // score -= myHarasser.distance(new Point(oppCP.x + scaled_x,
        //     oppCP.y + scaled_y));
        // score -= myHarasser.distance(oppCP);
        score += oppRunner.distance(oppCP);
        // stderr.writeln("OppRunner id: ${oppRunner.id}");
            
        // score -= myHarasser.diffAngle(oppRunner);
        // score -= oppRunner.diffAngle(checkpoints[oppRunner.nextCP]) -
            //  oppRunner.diffAngle(myHarasser);
        // score -= myRunner.distance2(oppHarasser);
        // Point closestHR = myHarasser.closestClamp(oppRunner, checkpoints[oppRunner.nextCP]);
        // score -= myHarasser.distance(closestHR);
        // score += myRunner.timeout;
        // score -= oppRunner.timeout;

        return score;

    }

    void mutate(){
        for(int i = 0; i < moves0.length; i++){
            if(rand.nextDouble() < MOVE_MUTATE_RATE){
                moves0[i].mutate(.2);
            }
            if(rand.nextDouble() < MOVE_MUTATE_RATE){
                moves1[i].mutate(.2);
            }
        }
    }
}

int thrustSigmoid(num angle){
    num steepness = 0.1;
    num exp = -1 * steepness * (angle.abs() - 30);
    num thrust = 200 * (1 - ( 1 / (1 + pow(e, exp))));
    return thrust.round();
}

void play(List<Pod> pods, List<Checkpoint> checkpoints) {
    // This tracks the time during the turn. The goal is to reach 1.0
    num t = 0.0;
    List<Collision> processed = [];

    while (t < 1.0) {
        //stderr.writeln("Playing pods in while loop $processed");
        Collision? firstCollision = null;

        // We look for all the collisions that are going to occur during the turn
        for (int i = 0; i < pods.length; ++i) {
            // Collision with another pod?
            for (int j = i + 1; j < pods.length; ++j) {
                Collision? col = pods[i].collision(pods[j]);

                // If the collision occurs earlier than the one we currently have we keep it
                if (col != null && col.t + t < 1.0 && !processed.contains(col) &&
                (firstCollision == null || col.t < firstCollision.t ) ) {
                        firstCollision = col;
                }
            }

            // Collision with another checkpoint?
            // It is unnecessary to check all checkpoints here.
            // We only test the pod's next checkpoint.
            // We could look for the collisions of the pod with
            // all the checkpoints, but if such a collision happens
            // it wouldn't impact the game in any way
            Collision? col = pods[i].collision(checkpoints[pods[i].nextCP]);

            // If the collision happens earlier than the current one we keep it
            if (col != null && col.t + t < 1.0 &&
            (firstCollision == null || col.t < firstCollision.t) ) {
                firstCollision = col;
            }
        }

        if (firstCollision == null) {
            // No collision, we can move the pods until the end of the turn
            for (int i = 0; i < pods.length; ++i) {
                pods[i].move(1.0 - t);
            }

            // End of the turn
            t = 1.0;
        } else {
            // Move the pods to reach the time `t` of the collision
            for (int i = 0; i < pods.length; ++i) {
                pods[i].move(firstCollision.t);
            }

            // Play out the collision
            firstCollision.a.bounce(firstCollision.b);
            processed.add(firstCollision);

            t += firstCollision.t;
        }
    }

    for (int i = 0; i < pods.length; ++i) {
        pods[i].end();
    }
}

void testPlay(List<Pod> pods, List<Checkpoint> checkpoints) {
    for (int i = 0; i < pods.length; ++i) {
        pods[i].rotate(new Point(8000, 4500));
        pods[i].boost(200);
    }

    play(pods, checkpoints);
}

Solution naiveSolution(List<Pod> startPods, int length){
    List<Pod> pods = clonePods(startPods);
    List<List<Move>> moves = new List.generate(4, (index) => []);

    for(int moveIndex = 0; moveIndex < length; moveIndex++){
        // stderr.writeln("Naive Pods move $moveIndex of $length");
        // printPods(pods);
        [0, 1, 2, 3].forEach((index) {
            Point nextCP = checkpoints[pods[index].nextCP];
            int prevCPid = pods[index].nextCP - 1;
            if(prevCPid < 0 ){ prevCPid = cpCount - 1; }
            int nextNextCPid = pods[index].nextCP + 1;
            if(nextNextCPid >= cpCount  ){ nextNextCPid = 0; }

            num dx = checkpoints[prevCPid].x - checkpoints[nextNextCPid].x;
            num dy = checkpoints[prevCPid].y - checkpoints[nextNextCPid].y;
            num length = sqrt(dx * dx + dy * dy);
            num scaleddx = (450 / length) * dx;
            num scaleddy = (450 / length) * dy;

            Point invert1 = new Point(
                nextCP.x - scaleddy.round() - pods[index].vx * 3,
                nextCP.y + scaleddx.round() - pods[index].vy * 3);

            Point invert2 = new Point(
                nextCP.x + scaleddy.round() - pods[index].vx * 3,
                nextCP.y - scaleddx.round() - pods[index].vy * 3);

            Point target = pods[index].closer(invert1, invert2);
            target = new Point(nextCP.x, nextCP.y);

            // stderr.writeln("Pod $index Angle: ${pods[index].angle} Angle to target ${pods[index].getAngle(target)} ");
            // stderr.writeln("Pod $index Diff Angle: ${pods[index].diffAngle(target)} ");
            num diffAngle = pods[index].diffAngle(target);
            if(diffAngle.abs() > 20){
                moves[index].add(new Move(pods[index].diffAngle(target), 50));
            } else {
                moves[index].add(new Move(pods[index].diffAngle(target), 200));
            }
            pods[index].apply(moves[index].last);
        });

        play(pods, checkpoints);
    }

    // printPods(pods);

    return new Solution(
        moves[0],
        moves[1],
        moves[2],
        moves[3]
        );

}

Solution monteCarlo(List<Pod> startPods, int length, int timeout){
    Stopwatch sw = new Stopwatch();
    sw.start();
    Solution naive = naiveSolution(startPods, length);
    stderr.writeln("Naive Solution: ${naive.score(startPods)}");
    Solution bestSolution = naive;
    num bestScore = naive.score(startPods);
    while(sw.elapsedMilliseconds < timeout){
        Solution randomSolution = new Solution(
            new List.generate(length, (index) => randomMove()),
            new List.generate(length, (index) => randomMove()),
            naive.moves2,
            naive.moves3);
        num randomEval = randomSolution.score(startPods);
        if( randomEval > bestScore){
            bestSolution = randomSolution;
            bestScore = randomEval;
        }
    }

    return bestSolution;
}

Solution genetic(List<Pod> startPods, int length,
    int timeout, Solution? lastSolution, Solution? enemySol){
    int poolSize = 20;
    List<Move> moves2;
    List<Move> moves3;

    Stopwatch sw = new Stopwatch();
    sw.start();
    
    // printPods(startPods);

    Solution naive = naiveSolution(startPods, length);
    if(enemySol != null){
        naive.moves2 = enemySol.moves2;
        naive.moves3 = enemySol.moves3;
        moves2 = enemySol.moves2;
        moves3 = enemySol.moves3;
    } else {
        moves2 = naive.moves2;
        moves3 = naive.moves3;
    }

    Map<num, Solution> pool = new SplayTreeMap();
    num naiveEval = naive.score(startPods);
    pool[naiveEval] = naive;
    // stderr.writeln("Created naive $naiveEval ${sw.elapsedMilliseconds}");
    if(lastSolution != null){
        Solution updateLast = lastSolution.clone();
        //remove last turn's moves
        updateLast.moves0.removeAt(0);
        updateLast.moves1.removeAt(0);
        //add random ones
        updateLast.moves0.add(randomMove());
        updateLast.moves1.add(randomMove());

        //replace enemy moves
        updateLast.moves2 = moves2;
        updateLast.moves3 = moves3;

        num updateEval = updateLast.score(startPods);
        pool[updateEval] = updateLast;
    }

    for(int i = 0; i < poolSize; i++){
        Solution randomSolution = new Solution(
            new List.generate(length, (index) => randomMove()),
            new List.generate(length, (index) => randomMove()),
            moves2,
            moves3);
        num randomEval = randomSolution.score(startPods);
        //stderr.writeln("${pool.length} $poolSize Random eval $randomEval");
        pool[randomEval] = randomSolution;
        totalEvals++;
    }

    // stderr.writeln("Filled pool ${pool.length} ${sw.elapsedMilliseconds}");
    stderr.writeln("Start Pool first ${pool.keys.first} last ${pool.keys.last}");

    while(sw.elapsedMilliseconds < timeout){
        // stderr.writeln("Creating GAs ${sw.elapsedMilliseconds}");

        Solution mutatedSolution;
        if(rand.nextDouble() < .4 || pool.length < 2){
            //mutation
            mutatedSolution = pool[pool.keys.toList()[rand.nextInt(pool.length)]]!.clone();
            mutatedSolution.mutate();

        } else {
            //crossover
            int a = rand.nextInt(pool.length);
            int b = a + rand.nextInt(pool.length - 1);
            if(b >= pool.length){
                b -= pool.length;
            }
            Solution mother = pool[pool.keys.toList()[a]]!;
            Solution father = pool[pool.keys.toList()[b]]!;
            mutatedSolution = crossover(mother, father);

        }

        num geneticEval = mutatedSolution.score(startPods);
        if( geneticEval > pool.keys.first && !pool.containsKey(geneticEval)){
            // stderr.writeln("Keeping GA solution $geneticEval");
            pool[geneticEval] = mutatedSolution;
            pool.remove(pool.keys.first);
        }
        
        totalEvals++;
    }
    stderr.writeln("End Pool first ${pool.keys.first} last ${pool.keys.last}");
    // printPods(startPods);

    return pool[pool.keys.last]!;

}

Move randomMove(){
    return new Move(-20 + rand.nextDouble() * 40, rand.nextInt(211) - 10);
}

printPods(List<Pod> pods){
    if(pods.length > 0){
        stderr.writeln(" ID|   X   |   Y   |   A| C|  T| S");
    }
    String id;
    String x;
    String y;
    String a;
    String c;
    String t;
    String s;
    for(Pod pod in pods){
        id = pod.id.toString().padLeft(3);
        x = pod.x.round().toString().padLeft(7);
        y = pod.y.round().toString().padLeft(7);
        a = pod.angle.round().toString().padLeft(4);
        c = pod.checked.toString().padLeft(2);
        t = pod.timeout.toString().padLeft(3);
        s = pod.shield.toString().padLeft(5);
        stderr.writeln("$id|$x|$y|$a|$c|$t|$s");
    }
}

List<Pod> clonePods(List<Pod> startPods){
    List<Pod> pods = startPods.map((pod) => pod.clone()).toList();

    pods[0].partner = pods[1];
    pods[1].partner = pods[0];

    pods[2].partner = pods[3];
    pods[3].partner = pods[2];

    return pods;
}

List<Pod> swapPods(List<Pod> startPods){
    List<Pod> pods = [];
    pods.add(startPods[2]);
    pods.add(startPods[3]);
    pods.add(startPods[0]);
    pods.add(startPods[1]);
    return pods;
}

Solution crossover(Solution mother, Solution father){
    List<Move> moves0 = [];
    List<Move> moves1 = [];
    for(int i = 0; i < mother.moves0.length; i++){
        if(rand.nextDouble() < .5){
            moves0.add(mother.moves0[i]);
        } else {
            moves0.add(father.moves0[i]);
        }
        if(rand.nextDouble() < .5){
            moves1.add(mother.moves1[i]);
        } else {
            moves1.add(father.moves1[i]);
        }
    }

    //assume that enemy moves are the same in both parents
    return new Solution(moves0, moves1,
        mother.moves2,
        mother.moves3);
}
