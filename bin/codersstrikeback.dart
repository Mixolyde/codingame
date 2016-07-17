import 'dart:io';
import 'dart:math';

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    int laps = int.parse(stdin.readLineSync());
    int cpCount = int.parse(stdin.readLineSync());
    List<Point> checkpoints = [];
    for(int i = 0; i < cpCount; i++){
        inputs = stdin.readLineSync().split(' ');
        int checkpointX = int.parse(inputs[0]); // x position of the next check point
        int checkpointY = int.parse(inputs[1]); // y position of the next check point
        checkpoints.add(new Point(checkpointX, checkpointY));
    }
    
    
    bool boostUsed = false;
    Point prevPos;
    Velocity vel;
    
    stderr.writeln("Version: ${Platform.version}");

    // game loop
    while (true) {
        inputs = stdin.readLineSync().split(' ');
        int x = int.parse(inputs[0]);
        int y = int.parse(inputs[1]);
        int nextCheckpointId1 = int.parse(inputs[5]);
        Point currentPos = new Point(x, y);
        inputs = stdin.readLineSync().split(' ');
        x = int.parse(inputs[0]);
        y = int.parse(inputs[1]);
        Point currentPos2 = new Point(x, y);
        int nextCheckpointId2 = int.parse(inputs[5]);
        
        inputs = stdin.readLineSync().split(' ');
        int opponentX = int.parse(inputs[0]);
        int opponentY = int.parse(inputs[1]);
        Point oppPos = new Point(opponentX, opponentY);
        inputs = stdin.readLineSync().split(' ');
        opponentX = int.parse(inputs[0]);
        opponentY = int.parse(inputs[1]);
        Point oppPos2 = new Point(opponentX, opponentY);
        
        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');

        if(prevPos == null){
            prevPos = currentPos;
            vel = new Velocity(prevPos, currentPos);
        } else {
            vel = new Velocity(prevPos, currentPos);
            prevPos = currentPos;
        }
        
        stderr.writeln("Vel $vel");
        stderr.writeln("boostUsed $boostUsed");

        // You have to output the target position
        // followed by the power (0 <= thrust <= 100)
        // i.e.: "x y thrust"
        
        //set target to nextCP - 3xVelocity vector
        Point nextCP = checkpoints[nextCheckpointId1];
        Point target;
        target = new Point(
            nextCP.x - vel.dx * 3,
            nextCP.y - vel.dy * 3);
        int thrust = thrustSigmoid(0);
        stderr.writeln("Thrust Sigmoid: $thrust");
        
        // if(!boostUsed && 
        //     nextCheckpointAngle.abs() < 2 &&
        //     nextCheckpointDist > 7000){
        //     boostUsed = true;
        //     print("${target.x} ${target.y} BOOST");
        // } else if(nextCheckpointAngle.abs() > 20){
        //     print("${target.x} ${target.y} $thrust");
        // } else if( nextCheckpointDist < 700){
        //     print("${target.x} ${target.y} 30");
        // } else if( nextCheckpointDist < 650){
        //     print("${target.x} ${target.y} 50");
        // } else {
        //     print("${target.x} ${target.y} 100");
        // }
        
        print("${target.x} ${target.y} 100");
        print("${target.x} ${target.y} 100");
    }
}

class Point {
    int x;
    int y;
    Point(this.x, this.y);
    
    String toString() { return "{$x,$y}"; }
    
    num distanceTo(Point other) {
        var dx = x - other.x;
        var dy = y - other.y;
        return sqrt(dx * dx + dy * dy);
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

int thrustSigmoid(int angle){
    num steepness = 0.1;
    num exp = -1 * steepness * (angle.abs() - 30);
    num thrust = 100 * (1 - ( 1 / (1 + pow(E, exp))));
    return thrust.round();
}