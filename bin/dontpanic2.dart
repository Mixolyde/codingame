import 'dart:io';

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
late int nbFloors; // number of floors
late int width; // width of the area
late int nbRounds; // maximum number of rounds
late int exitFloor; // floor on which the exit is found
late int exitPos; // position of the exit on its floor
late int nbTotalClones; // number of generated clones
late int nbElevators; // number of elevators
int round = 0;

void main() {
    List inputs;
    inputs = stdin.readLineSync()!.split(' ');
    nbFloors = int.parse(inputs[0]); // number of floors
    width = int.parse(inputs[1]); // width of the area
    nbRounds = int.parse(inputs[2]); // maximum number of rounds
    exitFloor = int.parse(inputs[3]); // floor on which the exit is found
    exitPos = int.parse(inputs[4]); // position of the exit on its floor
    nbTotalClones = int.parse(inputs[5]); // number of generated clones
    int nbAdditionalElevators = int.parse(inputs[6]); // ignore (always zero)
    nbElevators = int.parse(inputs[7]); // number of elevators
    List<List<int>> elevatorPos = new List.generate(nbFloors, (i) => []);
    List<List<int>> blockPos = new List.generate(nbFloors, (i) => []);
    for (int i = 0; i < nbElevators; i++) {
        inputs = stdin.readLineSync()!.split(' ');
        elevatorPos[int.parse(inputs[0])].add(int.parse(inputs[1])); // position of the elevator on its floor
    }

    elevatorPos.forEach((l) => l.sort());

    stderr.writeln("nbFloors $nbFloors width $width nbRounds $nbRounds exitFloor $exitFloor");
    stderr.writeln("exitPos $exitPos nbAdditionalElevators $nbAdditionalElevators nbElevators $nbElevators");
    stderr.writeln("elevatorPos $elevatorPos $blockPos");

    var solution = null;

    // game loop
    while (true) {
        if(solution != null){
            //still have to grab inputs
            inputs = stdin.readLineSync()!.split(' ');
            if(solution.isNotEmpty){
                Move move = solution.first;
                solution = solution.skip(1);
                stderr.writeln("$move $solution");

                print(move);
            } else {
                print("WAIT");
            }

        } else {
            // round++;
            inputs = stdin.readLineSync()!.split(' ');
            int cloneFloor = int.parse(inputs[0]); // floor of the leading clone
            int clonePos = int.parse(inputs[1]); // position of the leading clone on its floor
            String direction = inputs[2]; // direction of the leading clone: LEFT or RIGHT

            Game game = new Game(cloneFloor, clonePos, round,
                direction == "RIGHT", nbAdditionalElevators,
                elevatorPos, blockPos, []);

            stderr.writeln("cloneFloor $cloneFloor clonePos $clonePos direction $direction");
            stderr.writeln("elevatorPos $elevatorPos blockPos $blockPos");

            stderr.writeln(game);

            solution = search(game);
            //Add wait move to be taken up by the exit
            solution.add(new WaitMove());
            if(solution != null){
                stderr.writeln("Solution length ${solution.length} found: $solution");
                Move move = solution.first;
                solution = solution.skip(1);

                print(move);

            }
        }
    }
}

class Game {
    int cloneFloor;
    int clonePos;
    int round;
    bool facingRight;
    int addlElevators;
    List<List<int>> elevatorPos;
    List<List<int>> blockPos;

    List<Move> moves;

    Game(this.cloneFloor, this.clonePos, this.round,
        this.facingRight, this.addlElevators,
        this.elevatorPos, this.blockPos,
        this.moves){
    }

    List<Move> legalMoves() {
        List<Move> legals = [];
        //if we're out of time, or above the exit floor no legal moves
        if(round >= nbRounds || cloneFloor > exitFloor){
            return legals;
        }

        bool onElevator = elevatorPos[cloneFloor].contains(clonePos);
        bool aboveElevator = cloneFloor > 0 &&
            elevatorPos[cloneFloor - 1].contains(clonePos);
        bool onBlock = blockPos[cloneFloor].contains(clonePos);
        bool containsBlock = blockPos[cloneFloor].isNotEmpty;

        bool nextCloneLimit = round + 2 > nbRounds;

        if(!nextCloneLimit){
            //determine ELEVATOR legal move (have elevators left)
            if(addlElevators > 0 &&
                !onElevator && !onBlock && cloneFloor < exitFloor){
                legals.add(new ElevatorMove());
            }

            //determine BLOCK legal move (first turn or above elevator && not already blocked)
            if( (round == 0 || aboveElevator) && !containsBlock){
                legals.add(new BlockMove());
            }
        }
        //determine WAIT legal move (not on edge facing off screen)
        if(onElevator && cloneFloor < exitFloor){
            legals.add(new WaitMove());
        } else if(!( (clonePos == 0 && !facingRight) ||
            (clonePos == width - 1 && facingRight )) ){
            legals.add(new WaitMove());
        }

        return legals;
    }

    void applyMove(Move move){
        //assume that we're already in the cloned game
        // stderr.writeln("Before applying $move: $this");
        switch (move.toString()){
            case "WAIT":
                bool onElevator = elevatorPos[cloneFloor].contains(clonePos);
                bool onBlock = blockPos[cloneFloor].contains(cloneFloor);
                if(onElevator && !onBlock){
                    cloneFloor++;
                } else {
                    if(facingRight){
                        clonePos++;
                    } else {
                        clonePos--;
                    }
                }
                round++;
                moves.add(move);
                break;
            case "ELEVATOR":
                elevatorPos[cloneFloor].add(clonePos);
                cloneFloor++;
                round++;
                round++;
                round++;
                round++;
                addlElevators--;
                moves.add(move);
                moves.add(new WaitMove());
                moves.add(new WaitMove());
                moves.add(new WaitMove());
                break;
            case "BLOCK":
                blockPos[cloneFloor].add(clonePos);
                facingRight = !facingRight;
                if(facingRight){
                    clonePos++;
                } else {
                    clonePos--;
                }
                round++;
                round++;
                round++;
                round++;
                moves.add(move);
                moves.add(new WaitMove());
                moves.add(new WaitMove());
                moves.add(new WaitMove());
                break;
            default:
                stderr.writeln("Unrecognized move!!!");
                break;
        }

        // stderr.writeln("After applying $move: $this");
    }
    String toString() => "|[$clonePos, $cloneFloor] $round $facingRight $addlElevators $elevatorPos $blockPos|";

    Game clone() {
        List<List<int>> newElevators = new List.generate(elevatorPos.length,
        (i) => new List.from(elevatorPos[i]));
        List<Move> newMoves = new List.from(moves);
        List<List<int>> newBlocks = new List.generate(blockPos.length,
        (i) => new List.from(blockPos[i]));

        return new Game(cloneFloor, clonePos, round, facingRight,
        addlElevators, newElevators, newBlocks, newMoves);
    }
}

class Move {}

class ElevatorMove extends Move {
    String toString() => "ELEVATOR";
}

class WaitMove extends Move {
    String toString() => "WAIT";
}

class BlockMove extends Move {
    String toString() => "BLOCK";
}

List<Move> search(Game game){
    List<Game> open = [];
    open.add(game);
    List<int> closestPos = [game.clonePos, game.cloneFloor];
    int closestDist = (exitPos - game.clonePos).abs() +
        (exitFloor - game.cloneFloor).abs();
    Game closestGame = game;
    while(open.isNotEmpty){
        // TODO pull out game with lowest hueristic score
        Game current = open.first;
        open = open.skip(1).toList();
        //check for goal
        if(current.cloneFloor == exitFloor && current.clonePos == exitPos){
            stderr.writeln("Reached goal location, returning solution");
            return current.moves;
        }
        int dist = (exitPos - current.clonePos).abs() +
            (exitFloor - current.cloneFloor).abs();
        if(dist < closestDist){
            closestDist = dist;
            closestPos = [current.clonePos, current.cloneFloor];
            closestGame = current;
        }
        // stderr.writeln(current);
        // stderr.writeln("Moves up to this point: ${current.moves}");
        var legalMoves = current.legalMoves();
        // stderr.writeln("Applying legal moves: $legalMoves");
        var neighbors = legalMoves.map((m) => current.clone()..applyMove(m)).toList();
        // stderr.writeln("Neighbors: $neighbors");

        // DFS
        open.insertAll(0, neighbors);
        // BFS
        // open.addAll(neighbors);
    }
    stderr.writeln("No solution found! Closest Pos: $closestPos");
    stderr.writeln("Closest Game: $closestGame");
    stderr.writeln("Closest moves: ${closestGame.moves}");
    return closestGame.moves;
}
