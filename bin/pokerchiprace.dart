import 'dart:collection';
import 'dart:io';
import 'dart:math';

late int playerChipCount;
int turn = 0;

Random rand = new Random(3);
Map<int, Solution> lastSolutions = {};
late Game lastGame;
List<Wall> walls = [];
int maxId = 0;

int MAX_WIDTH = 800;
int MAX_HEIGHT = 515;

num WAIT_CHANCE = 0.25;
num MOVE_MUTATE_RATE = .5;
num CROSSOVER_RATE = .25;

int totalEvals = 0;

/**
 * It's the survival of the biggest!
 * Propel your chips across a frictionless table top to avoid getting eaten by bigger foes.
 * Aim for smaller oil droplets for an easy size boost.
 * Tip: merging your chips will give you a sizeable advantage.
 **/
void main() {
    List inputs;
    int playerId = int.parse(stdin.readLineSync()!); // your id (0 to 4)
    // stderr.writeln("My playerId $playerId");
    
    walls = [
        new Wall(0, 0, 0),
        new Wall(1, MAX_WIDTH, 0),
        new Wall(2, 0, MAX_HEIGHT),
        new Wall(3, 0, 0)
    ];

    Map<int, Unit> unitsGlobal = new SplayTreeMap<int, Unit>();
    Game currentGame = new Game(unitsGlobal);
    List<Chip> myChips = [];
    List<Chip> oppChips = [];
    List<Droplet> droplets = [];
    
    Map firstGeneticMap = {};

    // game loop
    while (true) {
        maxId = 0;
        myChips.clear();
        oppChips.clear();
        droplets.clear();
        
        playerChipCount = int.parse(stdin.readLineSync()!); // The number of chips under your control
        
        int entityCount = int.parse(stdin.readLineSync()!); // The total number of entities on the table, including your chips
        List<int> aliveIds = [];
        for (int i = 0; i < entityCount; i++) {
            inputs = stdin.readLineSync()!.split(' ');
            // stderr.writeln(inputs);
            int id = int.parse(inputs[0]); // Unique identifier for this entity
            if (id > maxId){
                //udpate the maximum id seen
                maxId = id;
            }
            int player = int.parse(inputs[1]); // The owner of this entity (-1 for neutral droplets)
            double radius = double.parse(inputs[2]); // the radius of this entity
            double x = double.parse(inputs[3]); // the X coordinate (0 to 799)
            double y = double.parse(inputs[4]); // the Y coordinate (0 to 514)
            double vx = double.parse(inputs[5]); // the speed of this entity along the X axis
            double vy = double.parse(inputs[6]); // the speed of this entity along the Y axis
            
            aliveIds.add(id);
            
            Unit unit;
            if (player == playerId ) {
                unit = new Chip(id, player, radius, x, y, vx, vy);
                myChips.add(unit);
            } else if (player >=0 ) {
                unit = new Chip(id, player, radius, x, y, vx, vy);
                oppChips.add(unit);
            } else {
                unit = new Droplet(id, radius, x, y, vx, vy);
                droplets.add(unit);
            }
            if(unitsGlobal[id] == null){
                unitsGlobal[id] = unit;
            } else {
                unitsGlobal[id]!.radius = radius;
                unitsGlobal[id]!.x = x;
                unitsGlobal[id]!.y = y;
                unitsGlobal[id]!.vx = vx;
                unitsGlobal[id]!.vy = vy;
                unitsGlobal[id]!.simTime = 0;
                unitsGlobal[id]!.father = unitsGlobal[id]!;
            }
            
        }
        
        unitsGlobal.keys.toList()
            .forEach((id) { 
                if(!aliveIds.contains(id)) 
                    unitsGlobal.remove(id);
            });
                
        Stopwatch globalSW = new Stopwatch();
        globalSW.start();
        
        // printUnits(unitsGlobal.values);
        
        currentGame.save();
        
        if(lastGame != null){
            // compareGames(currentGame, lastGame);
        }
        
        // stderr.writeln("Playing one turn of current game");
        // stderr.writeln("Simulating straight left move");
        // lastGame.units[0].apply(new Move(1, 0), lastGame);
        // playGame(lastGame);
        int solLength = 7;
        
        // Solution naVive = new Solution.random([playerId], solLength);
        // num naiveScore = naive.score(currentGame, playerId, null);
        
        // for(int i = 0; i < 5; i++){
        //     num scoreAgain = naive.score(currentGame, playerId, null);
        //     stderr.writeln("assert($naiveScore == $scoreAgain)");
        //     assert(naiveScore == scoreAgain);
        // }
        
        stderr.writeln("MyChips (${myChips.length}): $myChips");
        stderr.writeln("OppChips (${oppChips.length}): $oppChips");
        
        List<int> playersNotMe = unitsGlobal.values.fold([], (prev, unit) {
            if(unit.playerId != playerId && unit.playerId >= 0 &&
            !prev.contains(unit.playerId)){
                prev.add(unit.playerId);
            }
            return prev;
        }).toList();
        
        updateLastSolution(currentGame);
        
        // stderr.writeln("1 GlobalSW ${globalSW.elapsedMilliseconds} PlayersNotMe $playersNotMe");
        
        
        //really rough first solution
        // Solution firstGeneticSol = genetic(playerId, currentGame, solLength, 5, false, null);
        
        
        // firstGeneticMap[playerId] = firstGeneticSol;
        Map<int, Solution> oppSolutions = {};
        num opptime = 50.0 / playersNotMe.length;
        playersNotMe.forEach((pid) {
            if(turn == 0 || globalSW.elapsedMilliseconds < 50) {
                stderr.writeln("Opp Sol: GlobalSW ${globalSW.elapsedMilliseconds}");
                oppSolutions[pid] = 
                genetic(pid, currentGame, solLength, opptime, true, null);
                // genetic(pid, currentGame, solLength, opptime, true, firstGeneticMap);
            }
        });
        
        num timeLeft = turn == 0 
            ? 900 - globalSW.elapsedMilliseconds
            : 99 - globalSW.elapsedMilliseconds;
        stderr.writeln("Timeleft $timeLeft GlobalSW ${globalSW.elapsedMilliseconds}");
        
        Solution geneticSol;
        // geneticSol = genetic(playerId, currentGame, solLength, 50, false, null); 
        // geneticSol = genetic(playerId, currentGame, solLength, timeLeft, true, null); 
        
        if(timeLeft > 0){
            // geneticSol = genetic(playerId, currentGame, solLength, timeLeft, true, null); 
            geneticSol = genetic(playerId, currentGame, solLength, timeLeft, true, oppSolutions); 
        } else {
            geneticSol = firstGeneticSol;
        }

        // stderr.writeln("4 GlobalSW ${globalSW.elapsedMilliseconds}");
        stderr.writeln("EvalCount average: ${totalEvals / (turn + 1)}");
        
        // lastSolution = monte;
        lastSolutions[playerId] = geneticSol;
        
        stderr.writeln("$geneticSol");
        
        geneticSol.chipMoves.keys.forEach((key) {
            // stderr.writeln("Printing move for unitid $key");
            var geneticMove = geneticSol.chipMoves[key].first;
            print(geneticMove.printMove(currentGame.units[key]));
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
    int playerId;
    num radius;
    num vx;
    num vy;
    Unit father;
    bool alive = true;
    
    num sx;
    num sy;
    num sr;
    num svx;
    num svy;
    
    num simTime = 0;
    
    Unit(this.id, this.playerId, this.radius, num x, num y, this.vx, this.vy) : super(x, y){
        father = this;
    }
    
    // num get mass => PI * radius * radius;
    num get mass => radius * radius;
    
    void end() {}
    
    void save(){
        sx = x;
        sy = y;
        sr = radius;
        svx = vx;
        svy = vy;
    }
    
    void reset(){
        x = sx;
        y = sy;
        radius = sr;
        vx = svx;
        vy = svy;
        alive = true;
    }

    void bounce(Unit u) {
        u.father = u;
        this.father = this;
        if(radius == u.radius){
            // stderr.writeln("Same Radius Bouncing ${u.id} off $id");
            num m1 = this.mass;
            num m2 = u.mass;
            num mcoeff = (m1 + m2) / (m1 * m2);
            //relative position vector
            num nx = this.x - u.x;
            num ny = this.y - u.y;

            // Square of the distance between the 2 units 
            num nxnysquare = nx*nx + ny*ny;

            //relative velocity vector
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
            
        } else if (u is Wall) {
            Wall wall = u as Wall;
            switch (wall.id){
                case 0:
                case 2:
                    this.vy = -1 * this.vy;
                    break;
                case 1:
                case 3:
                    this.vx = -1 * this.vx;
                    break;
                default:
                    break;
            }
        } else {
            Unit bigger;
            Unit smaller;
            
            //remove the smaller unit from the collision
            if (radius < u.radius){
                bigger = u;
                smaller = this;
                this.alive = false;
            } else {
                bigger = this;
                smaller = u;
                u.alive = false;
            }
            
            // stderr.writeln("${bigger.id} eats ${smaller.id} in bounce method");
            
            //update position, velocity and size of bigger
            //position
            num massSum = bigger.mass + smaller.mass;
            num relx = smaller.x - bigger.x;
            num rely = smaller.y - bigger.y;
            num baryRatio = smaller.mass / massSum;
            num newX = bigger.x + baryRatio * relx;
            num newY = bigger.y + baryRatio * rely;
            
            //velocity
            num newVx = bigger.vx * bigger.mass + smaller.vx * smaller.mass;
            newVx /= massSum;
            num newVy = bigger.vy * bigger.mass + smaller.vy * smaller.mass;
            newVy /= massSum;
            
            //radius
            num newRadius = sqrt(bigger.radius * bigger.radius
                + smaller.radius * smaller.radius);
            
            // assert(newRadius > bigger.radius);
                
            // stderr.writeln("Old Bigger $bigger");
            bigger.radius = newRadius;
            bigger.x = newX;
            bigger.y = newY;
            bigger.vx = newVx;
            bigger.vy = newVy;
            
            //edge detection
            if(bigger.x < bigger.radius){
                bigger.x = bigger.radius;
                father = this;
            } else if ( bigger.x + bigger.radius > MAX_WIDTH) {
                bigger.x = MAX_WIDTH - bigger.radius;
                father = this;
            }
            
            if(bigger.y < bigger.radius){
                bigger.y = bigger.radius;
                father = this;
            } else if ( bigger.y + bigger.radius > MAX_HEIGHT) {
                bigger.y = MAX_HEIGHT - bigger.radius;
                father = this;
            }
            // stderr.writeln("Bigger $bigger");
        }
        
    }

    Collision collision(Unit u) {
        if(this.father == u.father){
            // stderr.writeln("Collision with child droplet detected at time 0, skipping $u");
            return null;
        }
        // Square of the distance
        num dist = distance2(u);

        // Sum of the radii squared
        num sr = (this.radius + u.radius)*(this.radius + u.radius);

        // We take everything squared to avoid calling sqrt uselessly. It is better for performance

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
    
    void move(double t) {
        num tolerance = 0.000001;
        // assert(t >= 0);
        // assert(t <= 1.0);
        this.x += this.vx * t;
        this.y += this.vy * t;
        this.simTime += t;
        // stderr.writeln("Unit after moving $this");
        // assert(x - radius >= -1 * tolerance);
        // assert(y - radius >= -1 * tolerance);
        // assert(x + radius <= MAX_WIDTH + tolerance);
        // assert(y + radius <= MAX_HEIGHT + tolerance);
    }
}

class Chip extends Unit {
    Chip(int id, int playerId, num radius, num x, num y,
        num vx, num vy) :
        super(id, playerId, radius, x, y, vx, vy){
        // stderr.writeln(this);
    }
    
    String toString() => "Chip id:$id pid:$playerId r:$radius [$x,$y] {$vx, $vy}";
    
    void apply(Move move, Game game){
        //need game to create a new droplet if necessary
        if (move.wait > WAIT_CHANCE && radius > 5){
            
            //convert angle 0 - 1.0 to -PI to PI
			num alpha = (move.angle * 2 * PI) - PI;
			num cosAlpha = cos(alpha);
			num sinAlpha = sin(alpha);
			num dropRadius = radius * sqrt(1.0 / 15);
			this.radius *= sqrt(14.0 / 15);
			num dropX = x - (radius - dropRadius) * cosAlpha;
			num dropY = y - (radius - dropRadius) * sinAlpha;
			num dropVx = vx - 200 * cosAlpha;
			num dropVy = vy - 200 * sinAlpha;
			this.vx += 200 * cosAlpha / 14;
			this.vy += 200 * sinAlpha / 14;

            maxId++;
			Droplet drop = new Droplet(maxId, dropRadius, dropX, dropY, dropVx, dropVy);
			drop.father = this;
			game.newDroplets[maxId] = drop;
            // stderr.writeln("Created new droplet in apply move: $drop");
        }
        //on WAIT, do nothing
    }
    
}

class Droplet extends Unit {
    Droplet(int id, num radius, num x, num y, num vx, num vy) :
        super(id, -1, radius, x, y, vx, vy){
        // stderr.writeln(this);        
    }
    
    String toString() => "Droplet $id $radius [$x,$y] {$vx, $vy}";
}

class Wall extends Unit {
    //id is the diretion
    // 0, 1, 2, 3
    // up, right, down, left
    Wall(int id, num x, num y) :
        super(id, -2, 0, x, y, 0, 0){
    }
    
    String toString() => "Wall $id {$x, $y}";
}

class Move {
    num wait;
    num angle;
    Move(this.wait, this.angle);
    
    Move.random() {
        wait = rand.nextDouble();
        angle = rand.nextDouble();
    }
    
    Move clone() => new Move(this.wait, this.angle);
    
    String toString() => "Wait: $wait Angle $angle";
    
    String printMove(Unit unit) {
        if(wait < WAIT_CHANCE || unit.radius < 5){
            return "WAIT";
        } else {
			num alpha = (angle * 2 * PI) - PI;
			num cosAlpha = cos(alpha);
			num sinAlpha = sin(alpha);
			num targetX = unit.x + 1000 * cosAlpha;
			num targetY = unit.y + 1000 * sinAlpha;
// 			stderr.writeln("Target for angle: $angle [$targetX,$targetY]");
			return "$targetX $targetY";
            
        }
    }
    
    void mutate(num amplitude) {
        num halfAmp = amplitude / 2.0;
        wait = wait + rand.nextDouble() * amplitude
            - halfAmp;
        wait %= 1.0;
        angle = angle + rand.nextDouble() * amplitude
            - halfAmp;
        angle %= 1.0;
        
    }
    
}

class Solution {
    //player 0 moves
    Map<int, List<Move>> chipMoves;
    num result;
    
    Solution(this.chipMoves);
    
    String toString() {
        return chipMoves.keys
            .map((key) => 
                "UnitId $key moves: ${chipMoves[key]}")
            .join("\n");
    }
    
    Solution clone() {
        // clone copies of lists of moves
        Map<int, List<Move>> newMoves = {};
        chipMoves.keys.forEach((key) {
            newMoves[key] = 
            chipMoves[key].map((move) => move.clone()).toList();
        });
        return new Solution(newMoves);
    }
    
    Solution.allWaits(List<int> ids, int turns) {
        this.chipMoves = {};
        ids.forEach((id) {
            chipMoves[id] = 
            new List.generate(turns, (turn) => new Move(0, 0)).toList();
        });
    }
    
    Solution.random(List<int> ids, int turns) {
        this.chipMoves = {};
        ids.forEach((id) {
            chipMoves[id] = 
            new List.generate(turns, (turn) => new Move.random()).toList();
        });
    }
    
    num score(Game origGame, int pid,
        Map<int, Solution> otherSolutions, bool debug) {
        //clone the units to ensure originals are not harmed
        result = 0;
            // stderr.writeln("Scoring solution:\n$this");
        // Play out the turns
        bool gameOver = false;
        for (int j = 0; j < chipMoves[chipMoves.keys.first].length && !gameOver; j++) {
            for(int i in chipMoves.keys) {
                // Apply the moves to the units before playing
                if(origGame.units[i] != null){
                    origGame.units[i].apply(chipMoves[i][j], origGame);
                }
            }
            // apply the enemy solutions
            if(otherSolutions != null){
                for(int opid in otherSolutions.keys){
                    var oChipMoves = otherSolutions[opid].chipMoves;
                    for(int i in oChipMoves.keys){
                        if(origGame.units[i] != null && j < oChipMoves[i].length){
                            origGame.units[i].apply(oChipMoves[i][j], origGame);
                        }
                    }
                }
            }
            playGame(origGame, debug);
            result += evaluation(origGame, pid) * pow(.70, j);
            gameOver = origGame.isGameOver(pid);
        }
        
        origGame.reset();

        // stderr.writeln("After simulating best solution");
        // printUnits(origGame.units.values);
        return result;
    }

    num evaluation(Game game, int pid){
        num eval = 0;
        List myIds = idsOfPlayer(game.units, pid);
        int myCount = myIds.length;
        List notMyIds = idsOfNotPlayer(game.units, pid);
        int notMyCount = notMyIds.length;
        
        if(myCount == 0){
            //lost game
            return -100000000000000000000;
        } else if (notMyCount == 0) {
            //won game
            return  100000000000000000000;
        }
        
        num massScore = 0;
        num myLargestMass = 0;
        num enemyLargestMass = 0;
        num otherMass = 0;
        
        num myMassSum = 0;
        num baryX = 0;
        num baryY = 0;
        
        eval -= notMyCount * 1000;
        
        game.units.values
            .where((u) => u.alive)
            .forEach((u){
            if(u.playerId == pid){
                //my chips
                num umass = u.mass;
                massScore += umass * umass;
                myMassSum += umass;
                baryX += u.x * umass;
                baryY += u.y * umass;
                if(umass > myLargestMass){
                    myLargestMass = umass;
                }
            } else if (u.playerId != pid && u.playerId >= 0){
                //other player chip
                num umass = u.mass;
                massScore -= umass * umass;
                otherMass += umass;
                if(umass > enemyLargestMass){
                    enemyLargestMass = umass;
                }
            } else {
                //droplet
                massScore -= u.mass;
                otherMass += u.mass;
            }
        });
        
        //newly created droplets that are still alive
        game.newDroplets.values
            .where((u) => u.alive)
            .forEach((u) {
            massScore -= u.mass;
            otherMass += u.mass;
        });
        
        baryX /= myMassSum;
        baryY /= myMassSum;
        
        eval += massScore * 100;
            
        // stderr.writeln("Eval after radius: $eval");
        if(myLargestMass > otherMass){
            // stderr.writeln("Winning mass $myMass > $otherMass");
            // eval += 5000;
        }
        
        eval += myLargestMass * 5;
        eval -= enemyLargestMass * 50;
        
        for(int id in myIds){
            //distance to my chip barycenter
            eval -= (game.units[id].x - baryX).abs() * 1000;
            eval -= (game.units[id].y - baryY).abs() * 1000;
            
            // eval += game.units[id].vx.abs();
            // eval += game.units[id].vy.abs();
            
            
            //find closest opponent
            
            // num dist;
            // Unit closestOpp;
            // for(int otherId in notMyIds){
            //     num compareDist = game.units[otherId].distance2(game.units[id]);
            //     if(dist == null || compareDist < dist){
            //         dist = compareDist;
            //         closestOpp = game.units[otherId];
            //     }
            // }
            
            // if(closestOpp.radius < game.units[id].radius){
            //     eval -= sqrt(dist);
            // } else {
            //     eval += sqrt(dist);
            // }
        
            // //find closest droplet
            // Unit closestDrop;
            // game.units.values.where((u) => u.playerId == -1).forEach((unit) {
            //     num compareDist = unit.distance2(game.units[id]);
            //     if(dist == null || compareDist < dist){
            //         dist = compareDist;
            //         closestDrop = unit;
            //     }
            // });
            
            // if(closestDrop != null) {
            //     if( closestDrop.radius > game.units[id].radius){
            //         eval += dist;
            //     } else {
            //         eval -= dist;
            //     }
            // }
        }
        
        return eval;
    }
    
    void mutate(num amplitude){
        for(int i in chipMoves.keys){
            for(Move move in chipMoves[i]){
                if(rand.nextDouble() < MOVE_MUTATE_RATE){
                    move.mutate(amplitude);
                }
            }
        }
    }
    
}

void updateLastSolution(Game game) {
    //remove old chip keys
    lastSolutions.keys.forEach((pid) {
        lastSolutions[pid].chipMoves.keys.toList()
        .forEach((key) {
            var unitIds = idsOfPlayer(game.units, pid);
            if(!unitIds.contains(key)){
                lastSolutions[pid].chipMoves.remove(key);
            }
        });
        lastSolutions[pid].chipMoves.values.forEach((moves) {
            var last = moves.removeAt(0);
            moves.add(last);
        });
        lastSolutions[pid].result = null;
    });
}

class Game {
    Map<int, Unit> units;
    Map<int, Droplet> newDroplets;
    
    Game(this.units){
        newDroplets = {};
    }
    
    bool isGameOver(int pid){
        var myAlive = idsOfPlayer(this.units, pid);
        var notMineAlive = idsOfNotPlayer(this.units, pid);
        
        return myAlive.length == 0 || notMineAlive.length == 0;
    }
    
    void save(){
        for(var u in units.values) {
            u.save();
        }
    }
    
    void reset(){
        for(var u in units.values) {
            u.reset(); 
        }
        newDroplets.keys.toList()
            .forEach((key) => newDroplets.remove(key));
        
    }
}

void playGame(Game game, debug){
    // This tracks the time during the turn. The goal is to reach 1.0
    num t = 0.0;
    // List<Collision> processed = [];
    // game.units.values.forEach((u) => u.simTime = 0);
    
    Collision lastCollision = null;

    while (t < 1.0) {
        //update list of pods in case any were removed in previous bounce
        List<Unit> pods = game.units.values.where((u) => u.alive).toList();
        pods.addAll(game.newDroplets.values.where((u) => u.alive).toList());
        // if(debug) { stderr.writeln("Checking collisions at time $t pods length: ${pods.length}"); }
        Collision firstCollision = null;
        
        // We look for all the collisions that are going to occur during the turn
        for (int i = 0; i < pods.length; ++i) {
            // Collision with another pod?
            for (int j = i + 1; j < pods.length; ++j) {
                Collision col = pods[i].collision(pods[j]);

                // If the collision occurs earlier than the one we currently have we keep it
                if (col != null && col.t + t < 1.0 && 
                // !processed.contains(col) &&
                (firstCollision == null || col.t < firstCollision.t ) ) {
                    if(lastCollision == null || !lastCollision.ignorable(col) ){
                        firstCollision = col;
                    }
                }
            }
            
            if(debug && firstCollision != null && t > 0.69 && firstCollision.t == 0.0){
                stderr.writeln("First collision detected: $firstCollision");
                stderr.writeln("Last  collision detected: $lastCollision");
            }

            num timeLeft = 1.0 - t;
            num vxLeft = pods[i].vx * timeLeft;
            num vyLeft = pods[i].vy * timeLeft;
            
            walls.forEach((wall){
                Collision wallCol;
                Unit unit = pods[i];
                switch(wall.id) {
                    case 0:
                        //up, negative y direction
                        if(pods[i].y + vyLeft - pods[i].radius <= 0){
                            num wallt = -1 * (pods[i].y - pods[i].radius) / pods[i].vy;
                            // stderr.writeln("Collision with up wall detected by unit ${unit.id} at time $wallt");
                            wallCol = new Collision(pods[i], wall, wallt);
                        }
                        break;
                    case 1:
                        //right, positive x direction
                        if(pods[i].x + vxLeft + pods[i].radius >= wall.x){
                            num wallt = (wall.x - pods[i].radius - pods[i].x) / pods[i].vx;
                            // stderr.writeln("Collision with right wall detected by unit ${unit.id} at time $wallt");
                            wallCol = new Collision(pods[i], wall, wallt);
                        }
                        break;
                    case 2:
                        //down, positive y direction
                        if(pods[i].y + vyLeft + pods[i].radius >= wall.y){
                            num wallt = (wall.y - pods[i].radius - pods[i].y) / pods[i].vy;
                            // stderr.writeln("Collision with down wall detected by unit ${unit.id} at time $wallt");
                            wallCol = new Collision(pods[i], wall, wallt);
                        }
                        break;
                    case 3:
                        //left, negative x direction
                        if(pods[i].x + vxLeft - pods[i].radius <= 0){
                            num wallt = -1 * (pods[i].x - pods[i].radius) / pods[i].vx;
                            // stderr.writeln("Collision with left wall detected by unit ${unit.id} at time $wallt");
                            wallCol = new Collision(pods[i], wall, wallt);
                        }
                        break;
                    default:
                        break;
                }
                
                if(debug && wallCol != null && t > 0.69 && wallCol.t == 0.0){
                    stderr.writeln("Wall collision detected: $wallCol");
                }
                
                if(wallCol != null && wallCol.t + t < 1.0 &&
                    (firstCollision == null || wallCol.t < firstCollision.t)){
                    firstCollision = wallCol;
                }
            });
        }

        if (firstCollision == null) {
            // No collision, we can move the pods until the end of the turn
            for (int i = 0; i < pods.length; ++i) {
                // stderr.writeln("No more collisions, moving by time ${1.0 - t}");
                pods[i].move(1.0 - t);
                // stderr.writeln("Time on unit 0 ${game.units[0].simTime}");
            }

            // End of the turn
            t = 1.0;
        } else {
            // Move the pods to reach the time `t` of the collision
            // stderr.writeln("Collision detected $firstCollision, moving all units by time ${firstCollision.t}");
            for (int i = 0; i < pods.length; ++i) {
                pods[i].move(firstCollision.t);
            }
            
            // Play out the collision
            firstCollision.a.bounce(firstCollision.b);
            // processed.add(firstCollision);
            lastCollision = firstCollision;
            
            if(debug && firstCollision != null && t > 0.69 && firstCollision.t == 0.0){
                stderr.writeln("ELSE First collision detected: $firstCollision");
                stderr.writeln("ELSE Last  collision detected: $lastCollision");
            }


            t += firstCollision.t;
        }
        
    }
    
    // assert(t == 1.0);
    // num totalSimTime = 0;
    // for(Unit u in game.units.values){
        // totalSimTime += u.simTime;
    // }
    // stderr.writeln("TotalSimTime $totalSimTime");
    // assert(totalSimTime == 1.0 * game.units.values.length);

}

Solution genetic(int pid, Game game, int length, 
    num limit, bool isTimeLimit,
    Map<int, Solution> otherSolutions){
    int poolSize = 5;
    int evalCount = 0;

    Stopwatch sw = new Stopwatch();
    sw.start();
    
    List<int> unitIds = idsOfPlayer(game.units, pid).toList();

    Solution naive = new Solution.allWaits(unitIds, length);
    
    List<Solution> pool = [];
    num naiveEval = naive.score(game, pid, otherSolutions, false);
    evalCount++;
    pool.add(naive);
    // stderr.writeln("Created naive $naiveEval time: ${sw.elapsedMilliseconds}");
    
    if(lastSolutions[pid] != null){
        num updateEval = lastSolutions[pid].score(game, pid, otherSolutions, false);
        pool.add(lastSolutions[pid]);
        evalCount++;
    }

    while(pool.length < poolSize){
        Solution randomSolution = new Solution.random(unitIds, length);
        // if(debug)
        //      stderr.writeln("before score ${pool.length} $poolSize");
        num randomEval = randomSolution.score(game, pid, otherSolutions, false);
        pool.add(randomSolution);
        evalCount++;
    }

    num lowestEval = pool.first.result;
    pool.forEach((sol) {
        if(sol.result < lowestEval){
            lowestEval = sol.result;
        }
    });
    
    // stderr.writeln("Filled pool ${pool.length} low: $lowestEval time ${sw.elapsedMilliseconds}");

    while (
        (isTimeLimit && sw.elapsedMilliseconds < limit) ||
        (!isTimeLimit && evalCount < limit )){
        // if(evalCount % 20 == 0) {
        //     stderr.writeln("Creating GA ${sw.elapsedMilliseconds} evals $evalCount limit $limit");
        // }

        Solution mutatedSolution;
        if(rand.nextDouble() > CROSSOVER_RATE || pool.length < 2){
            //mutation
            mutatedSolution = pool[rand.nextInt(pool.length)].clone();
            mutatedSolution.mutate((limit - sw.elapsedMilliseconds) / (limit + 1) );
            // mutatedSolution.mutate(.25);
        } else {
            //crossover
            int a = rand.nextInt(pool.length);
            int b = a + rand.nextInt(pool.length - 1);
            b = b % pool.length;
            
            Solution mother = pool[a];
            Solution father = pool[b];
            mutatedSolution = crossover(mother, father);

        }

        num geneticEval = mutatedSolution.score(game, pid, otherSolutions, false);
        if( geneticEval > lowestEval){
            // stderr.writeln("Keeping GA solution $geneticEval");
            pool.add(mutatedSolution);
            if(pool.length > poolSize){
                pool.sort((a, b) => a.result.compareTo(b.result));
                // stderr.writeln("Removing solution eval ${pool.first.result}");
                pool.removeAt(0);
                lowestEval = pool.first.result;
            }
            
        }
        
        evalCount++;
    }
    pool.sort((a, b) => a.result.compareTo(b.result));
    stderr.writeln("End Pool first ${pool.first.result} last ${pool.last.result} after $evalCount evals time ${sw.elapsedMilliseconds}");
    
    totalEvals += evalCount;
    lastSolutions[pid] = pool.last;

    return pool.last;

}

Solution crossover(Solution mother, Solution father){
    Map newMoves = {};
    // stderr.writeln("Crossover mother keys ${mother.chipMoves.keys} Crossover father keys ${father.chipMoves.keys}");

    for(int i in mother.chipMoves.keys){
        newMoves[i] = [];
        for(int j = 0; j < mother.chipMoves[i].length; j++){
            if(rand.nextDouble() < 0.5){
                newMoves[i].add(mother.chipMoves[i][j].clone());
            } else {
                newMoves[i].add(father.chipMoves[i][j].clone());
            }
        }
    }

    return new Solution(newMoves);
}

printUnits(Iterable<Unit> pods){
    if(pods.length > 0){
        stderr.writeln(" ID|  P|   R   |   X   |   Y   |   VX  |   VY");
    }
    String id;
    String p;
    String r;
    String x;
    String y;
    String vx;
    String vy;
    for(Unit pod in pods){
        id = pod.id.toString().padLeft(3);
        p = pod.playerId.toString().padLeft(3);
        r = pod.radius.toStringAsFixed(3).padLeft(7);
        x = pod.x.toStringAsFixed(3).padLeft(7);
        vx = pod.vx.toStringAsFixed(3).padLeft(7);
        y = pod.y.toStringAsFixed(3).padLeft(7);
        vy = pod.vy.toStringAsFixed(3).padLeft(7);
        stderr.writeln("$id|$p|$r|$x|$y|$vx|$vy");
    }
}

bool compareGames(Game currentGame, Game predictedGame){
    // stderr.writeln("Comparing current game to predicted game");
    if(currentGame.units.values.length == 
        predictedGame.units.values.length){
        stderr.writeln("Unit Count ${currentGame.units.values.length}: MATCH");
    } else {
        stderr.writeln("Unit Count ${currentGame.units.values.length} - ${predictedGame.units.values.length}: NO MATCH");
    }
    
    num tolerance = 0.000012;
    stderr.writeln(" ID|  P|   R   |   X   |   Y   |   VX  |   VY");
    String id;
    String p;
    String r;
    String x;
    String y;
    String vx;
    String vy;
    for (int i in currentGame.units.keys){
        if(predictedGame.units[i] != null){
            // stderr.writeln("Comparing unit id: $i with $tolerance tolerance");
            Unit pod = currentGame.units[i];
            Unit lastPod = predictedGame.units[i];
            id = pod.id.toString().padLeft(3);
            p = pod.playerId.toString().padLeft(3);
            r = printFloat(pod.radius - lastPod.radius, 7, tolerance);
            x = printFloat(pod.x - lastPod.x, 7, tolerance);
            vx = printFloat(pod.vx - lastPod.vx, 7, tolerance);
            y = printFloat(pod.y - lastPod.y, 7, tolerance);
            vy = printFloat(pod.vy - lastPod.vy, 7, tolerance);
            
            stderr.writeln("$id|$p|$r|$x|$y|$vx|$vy");
        }
        
    }
    
}

String printFloat(num float, size, num tolerance){
    if(float < tolerance){
        return "0.0".padLeft(size);
    }
    stderr.writeln("Value outside tolerance: $float");
    var fString = float.toString();
    if(fString.length > size){
        fString = fString.substring(0, size - 1);
    }
    return fString.padLeft(size);
}

List<int> idsOfPlayer(Map units, int player){
    return units.values
        .where((u) => u.playerId == player && u.alive)
        .map((u) => u.id).toList();
}

List<int> idsOfNotPlayer(Map units, int player){
    return units.values
        .where((u) => u.playerId != player && u.playerId >= 0 && u.alive)
        .map((u) => u.id).toList();
}

class Collision {
    Unit a;
    Unit b;
    num t;

    Collision(this.a, this.b, this.t){
        // assert(t >= 0.0);
        // assert(t < 1.0);
    }

    String toString() { return "$a will collide $b at time $t"; }

    bool ignorable(Collision other) {
        return other.t == 0 &&
        ((a.id == other.a.id && b.id == other.b.id) ||
         (a.id == other.b.id && b.id == other.a.id));
    }

    int get hashCode {
        int result = 17;
        result = 37 * result + a.id + b.id;
        result = 37 * result + t.hashCode;
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
