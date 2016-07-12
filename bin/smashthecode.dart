import 'dart:collection';
import 'dart:io';
import 'dart:math';

// Copyright (c) 2016, Brian Grey. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

Random rand = new Random(1);
Player me;
Player opp;
List inputs;
List<Pair> pairs = [];
int TURN_LIMIT = 200;
int turn = 0;

enum Cell {empty, skull, blue, green, pink, red, yellow}

void main() {
    // game loop
    while (true) {
        pairs.clear();
        //6 columns of cells, starting at the bottom
        List<List<Cell>> myBoard = new List.generate(6, (int index) => new List<Cell>());
        List<List<Cell>> oppBoard = new List.generate(6, (int index) => new List<Cell>());
        for (int i = 0; i < 8; i++) {
            inputs = stdin.readLineSync().split(' ');
            int colorA = int.parse(inputs[0]); // color of the first block
            int colorB = int.parse(inputs[1]); // color of the attached block
            pairs.add(new Pair(colorToCell(colorA), colorToCell(colorB)));
        }
        int score1 = int.parse(stdin.readLineSync());
        for (int i = 0; i < 12; i++) {
            // One line of the map ('.' = empty, '0' = skull block, '1' to '5' = colored block)
            String row = stdin.readLineSync();
            List<Cell> cells = row.split("").map( (cell) => stringToCell(cell)).toList();
            for(int j = 0; j < 6; j++){
                if(cells[j] != Cell.empty){
                    myBoard[j].insert(0, cells[j]);
                }
            }
        }
        int score2 = int.parse(stdin.readLineSync());
        for (int i = 0; i < 12; i++) {
            // One line of the map ('.' = empty, '0' = skull block, '1' to '5' = colored block)
            String row = stdin.readLineSync();
            List<Cell> cells = row.split("").map( (cell) => stringToCell(cell)).toList();
            for(int j = 0; j < 6; j++){
                if(cells[j] != Cell.empty){
                    oppBoard[j].insert(0, cells[j]);
                }
            }
        }

        me = new Player(myBoard, score1, 0, turn);
        opp = new Player(oppBoard, score2, 0, turn);

        stderr.writeln("Upcoming: $pairs");
        printBoard(myBoard);
        Map rankMap = rankMoves(me);
        stderr.writeln("Rankmap $rankMap");

        List<Move> bestMoves = rankMap[rankMap.keys.last];

        Move move = bestMoves[rand.nextInt(bestMoves.length)];

        print("${move.col} ${move.rot}");

        turn++;
        turn++;
    }
}

class Player {
    List<List<Cell>> board = [];
    int score;
    num nuisancePoints;
    num generatedNuisance = 0;
    bool alive = true;
    int turn;

    Player(this.board, this.score, this.nuisancePoints, this.turn);

    int get totalBlocks => board.fold(0, (prev, element) => prev + element.length);

    num evaluate(){
        if(!alive){
            return double.NEGATIVE_INFINITY;
        }
        int threeCount = threeConnectedCount(board);
        int twoCount = twoConnectedCount(board);
        Map blobs = connectedColors(board);

        return 
            twoCount * 5 + 
            threeCount * 10 + 
            (6 * 12) - this.totalBlocks +
            this.generatedNuisance +
            this.score;
    }

    Player applyMove(Move move, Pair pair){
        // stderr.writeln("Applying $move with $pair");
        turn += 2;
        //clone members
        List<List<Cell>> newBoard = new List.generate(6, (index) =>
        new List.from(this.board[index]));
        int newScore = this.score;

        //this player's nuisance points don't change when we move
        Player updated = new Player(newBoard, newScore, this.nuisancePoints, turn);
        if(!move.isValid(this.board)){
            stderr.writeln("Attempting to apply invalid move!");
            updated.alive = false;
            return updated;
        }

        //landing spots
        Point top;
        Point bottom;

        switch(move.rot){
            case 1:
                newBoard[move.col].add(pair.top);
                newBoard[move.col].add(pair.bottom);
                top = new Point(newBoard[move.col].length - 2, move.col);
                bottom = new Point(newBoard[move.col].length - 1, move.col);
                break;
            case 3:
                newBoard[move.col].add(pair.bottom);
                newBoard[move.col].add(pair.top);
                top = new Point(newBoard[move.col].length - 1, move.col);
                bottom = new Point(newBoard[move.col].length - 2, move.col);
                break;
            case 0:
                newBoard[move.col].add(pair.top);
                newBoard[move.col + 1].add(pair.bottom);
                top = new Point(newBoard[move.col].length - 1, move.col);
                bottom = new Point(newBoard[move.col + 1].length - 1, move.col + 1);
                break;
            case 2:
                newBoard[move.col - 1].add(pair.bottom);
                newBoard[move.col].add(pair.top);
                top = new Point(newBoard[move.col].length - 1, move.col);
                bottom = new Point(newBoard[move.col - 1].length - 1, move.col - 1);
                break;
            default:
                stderr.writeln("Illegal rotation in $move");
                break;

        }

        //detect blobs
        List<Point> removals = [];
        int blocksCleared = 0;
        int chainPower = 0;
        int colorBonus = 0;
        int groupBonus = 0;

        //stderr.writeln("Top point $top Cell ${cellAt(newBoard, top)}");
        List<Point> topBlob = connected(newBoard, top);
        //stderr.writeln("Top Connected: $topBlob");
        if(topBlob.length > 3){
            removals.addAll(topBlob);
            blocksCleared += topBlob.length;
            groupBonus += topBlob.length - 4;
        }

        if(!topBlob.contains(bottom)){
            //stderr.writeln("Bottom point $bottom Cell ${cellAt(newBoard, bottom)}");
            List<Point> bottomBlob = connected(newBoard, bottom);
            //stderr.writeln("Bottom Connected: $bottomBlob");
            if(bottomBlob.length > 3){
                if(removals.length > 0 && pair.top != pair.bottom){
                    colorBonus = 2;
                }
                removals.addAll(bottomBlob);
                blocksCleared += bottomBlob.length;
                groupBonus += bottomBlob.length - 4;
            }
        }

        if(removals.length > 0 ){
            stderr.writeln("Found blobs to remove");
            // TODO search for skulls, add to remove list

            //stderr.writeln("Removals $removals");
            //mark removals
            removals.forEach((removal) =>
                newBoard[removal.y][removal.x] = Cell.empty
            );
            //remove
            for(List<Cell> cells in newBoard){
                for(int index = 0; index < cells.length; index++ ){
                    if(cells[index] == Cell.empty){
                        cells.removeAt(index);
                        index--;
                    }
                }
            }

            //TODO fix score update logic
            int scoreUpdate = 10 * blocksCleared *
                max(1, chainPower + colorBonus + groupBonus);
            //stderr.writeln("Score update for move $scoreUpdate");
            updated.score += scoreUpdate;

            //TODO repeat until no blobs


        }
        return updated;

    }

    void addNuisancePoints(int np){
        nuisancePoints += np;
    }

}

class Pair {
    Cell top;
    Cell bottom;

    Pair(this.top, this.bottom);

    String toString() {
        return "{${cellToString(top)}:${cellToString(bottom)}}";

    }

    List<Move> allMoves() {
        if(top == bottom){
            return Move.allMovesDoublePiece;
        } else {
            return Move.allMoves;
        }
    }
}

class Move {
    int col;
    int rot;

    Move(this.col, this.rot);

    String toString() { return "{$col,$rot}"; }

    bool isValid(List<List<Cell>> board){
        List<int> heights = allHeights(board);
        switch (rot){
            case 1:
            case 3:
                return heights[col] < 11;
            case 0:
                return heights[col] < 12 && heights[col + 1] < 12;
            case 2:
                return heights[col] < 12 && heights[col - 1] < 12;
            default:
                return true;
        }
    }

    static List<Move> allMovesDoublePiece =
        [
            //middle moves for each rotation
            new Move(1, 0),
            new Move(1, 1),
            new Move(2, 0),
            new Move(2, 1),
            new Move(3, 0),
            new Move(3, 1),
            new Move(4, 0),
            new Move(4, 1),
            //first col moves
            new Move(0, 0),
            new Move(0, 1),
            //last col move
            new Move(5, 1),
        ];

    static List<Move> allMoves =
        [
            //middle moves for each rotation
            new Move(1, 0),
            new Move(1, 1),
            new Move(1, 2),
            new Move(1, 3),
            new Move(2, 0),
            new Move(2, 1),
            new Move(2, 2),
            new Move(2, 3),
            new Move(3, 0),
            new Move(3, 1),
            new Move(3, 2),
            new Move(3, 3),
            new Move(4, 0),
            new Move(4, 1),
            new Move(4, 2),
            new Move(4, 3),
            //first col moves
            new Move(0, 0),
            new Move(0, 1),
            new Move(0, 3),
            //last col moves
            new Move(5, 1),
            new Move(5, 2),
            new Move(5, 3),
        ];
}

class Point {
    int x;
    int y;
    Point parent;

    Point(this.x, this.y){
        this.parent = this;
    }

    String toString() { return "{$x,$y}"; }

    List<Point> get neighbors4 =>
        [
        new Point(x + 1, y),
        new Point(x - 1, y),
        new Point(x, y + 1),
        new Point(x, y - 1)
        ];

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

class DisJointPoints {
    Map<Point, int> map = new Map<Point, int>();

    void operator[]=(Point key, int value){
        if(map.containsKey(key)){
            map[find(key)] = value;
        } else {
            //add new key
            key.parent = key;
            map[key] = value;
        }
    }

    int operator[](Point key){
        return findGroup(key);
    }

    Point find(Point point){
        if(point.parent == point){
            return point;
        } else {
            return find(point.parent);
        }
    }

    int findGroup(Point point){
        return map[find(point)];
    }

    void union(Point a, Point b){
        Point aRoot = find(a);
        Point bRoot = find(b);
        aRoot.parent = bRoot;
    }

}

List<Point> validNeighbors(Point current, List<List<Cell>> board){
    List<Point> valids = current.neighbors4.where((neighbor) =>
        neighbor.x >= 0 && neighbor.x < board[current.y].length &&
        neighbor.y >= 0 && neighbor.y < 6
    ).toList();
    return valids;
}

List<Point> connected(List<List<Cell>> board, Point start){
    List<Point> open = [start];
    List<Point> closed = [];
    List<Point> acc = [];
    return connectedRec(board, cellAt(board, start), open, closed, acc);
}

List<Point> connectedRec(List<List<Cell>> board,
    Cell goal, List<Point> open, List<Point> closed,
    List<Point> acc){

    // stderr.writeln("Goal $goal open $open closed $closed acc $acc");
    if(open.isEmpty){
        return acc;
    }
    Point current = open.removeAt(0);
    if(cellAt(board, current) != goal){
        closed.add(current);
        return connectedRec(board, goal, open, closed, acc);
    } else {
        acc.add(current);
        closed.add(current);
        //generate neighbors and recurse
        List<Point> valids = validNeighbors(current, board);

        for(Point valid in valids){
            if(!open.contains(valid) && !closed.contains(valid)){
                open.add(valid);
            }
        }

        return connectedRec(board, goal, open, closed, acc);
    }

}

Cell cellAt(List<List<Cell>> board, Point point){
    List<Cell> cells = board[point.y];
    if(point.x < cells.length){
        return cells[point.x];
    } else {
        return Cell.empty;
    }
}

void printBoard(List<List<Cell>> board){
    for(List<Cell> row in board){
        for(Cell cell in row){
            stderr.write(cellToString(cell));
        }
        stderr.writeln("");
    }
}

int heightOfCol(int col, List<List<Cell>> board){
    return board[col].length;
}

List<int> allHeights(board){
    return [0, 1, 2, 3, 4, 5].map((col) => heightOfCol(col, board)).toList();
}

List<int> lowestCols(List<int> heights){
    int lowestHeight = 12;
    List<int> cols = [];
    for(int i = 0; i < heights.length; i++){
        if(heights[i] < lowestHeight){
            cols = [];
            cols.add(i);
            lowestHeight = heights[i];
        } else if (heights[i] == lowestHeight){
            cols.add(i);
        }
    }
    return cols;
}

Cell colorToCell(int color){
    switch (color) {
        case 1:
            return Cell.blue;
        case 2:
            return Cell.green;
        case 3:
            return Cell.pink;
        case 4:
            return Cell.red;
        case 5:
            return Cell.yellow;
        default:
            return Cell.empty;
    }
}

Cell stringToCell(String char){
    switch (char){
        case ".":
            return Cell.empty;
        case "0":
            return Cell.skull;
        default:
            return colorToCell(int.parse(char));
    }
}

String cellToString(Cell cell){
    switch (cell) {
        case Cell.empty:
            return ".";
        case Cell.skull:
            return "0";
        default:
            return cell.toString().substring(5, 6);

    }
}

Map<num, List<Move>> rankMoves(Player player){
    //SplayTreeMap iterates the keys in sorted order
    Map<num, List<Move>> rankMap = new
        SplayTreeMap<num, List<Move>>();
    stderr.writeln("Ranking possible moves. Current eval ${player.evaluate()}");
    //apply all moves, sort by score
    List<Move> validMoves = Move.allMoves.where(
        (move) => move.isValid(player.board)).toList();
    if(validMoves.length > 0){
        for(Move move in validMoves){
            Player updatedPlayer = me.applyMove(move, pairs[0]);
            num eval = updatedPlayer.evaluate();
            // stderr.writeln("Updated eval $eval");
            // printBoard(updatedPlayer.board);
            if(!rankMap.containsKey(eval)){
                rankMap[eval] = new List<Move>();
            }
            rankMap[eval].add(move);
        }
    } else {
        stderr.writeln("!!!No valid moves, game over!!!");
        rankMap[0] = [new Move(0, 0)];
    }

    return rankMap;
}

Map<int, Set<Point>> connectedColors(List<List<Cell>> board){
    Map<int, Set<Point>> blobs = new Map<int, Set<Point>>();
    Map<int, Set<int>> equivs = new Map<int, Set<int>>();
    DisJointPoints groups = new DisJointPoints();
    int groupIndex = 0;
    //TODO scan map, build blob and equivalency list
    //first pass
    for(int row = 0; row < 6; row++){
        for(int col = 0; col < board[row].length; col++){
            Point cp = new Point(col, row);
            Cell current = board[row][col];
            if(current != Cell.skull){
                bool matchesNorth = false;
                Point northPoint = new Point(col, row - 1);
                bool matchesWest = false;
                Point westPoint = new Point(col - 1, row);
                if(row > 0 && cellAt(board, northPoint) == current){
                    matchesNorth = true;
                }
                if(col > 0 && cellAt(board, westPoint) == current){
                    matchesWest = true;
                }
                if(!matchesNorth && !matchesWest){
                    blobs[groupIndex] = new Set.from([cp]);
                    equivs[groupIndex] = new Set.from([groupIndex]);
                    groups[cp] = groupIndex;
                    //increment the label index
                    groupIndex++;
                } else if (matchesNorth && !matchesWest){
                    int group = groups[northPoint];
                    blobs[group].add(cp);
                    groups[cp] = group;
                } else if (!matchesNorth && matchesWest) {
                    int group = groups[westPoint];
                    blobs[group].add(cp);
                    groups[cp] = group;
                } else if (matchesNorth && matchesWest && groups[northPoint] == groups[westPoint]) {
                    //current point matches north and west and they're already the same label
                    // p p
                    // p X
                    int group = groups[westPoint];
                    blobs[group].add(cp);
                    groups[cp] = group;
                } else {
                    //current point matches north and west, but they are different labels
                    // b p
                    // p X

                    //add to lowest label
                    int northGroup = groups[northPoint];
                    int westGroup = groups[westPoint];
                    int minGroup = min(northGroup, westGroup);
                    blobs[minGroup].add(cp);
                    groups[cp] = minGroup;

                    //update equivs
                    // union both sets of labels together
                    // for each group in labels, set equivs[group] to unioned list
                    equivs[northGroup].union(equivs[westGroup]);
                    equivs[westGroup].union(equivs[northGroup]);
                }
            }
        }
    }

    //TODO second pass
    //reduce blobs with same equivs

    return blobs;
}

int threeConnectedCount(List<List<Cell>> board){
    int threeCount = 0;
    for(int row = 0; row < 6; row++){
        for(int col = 0; col < board[row].length; col++){
            Point cp = new Point(col, row);
            Cell current = board[row][col];
            List<Point> valids = validNeighbors(cp, board);
            if(current != Cell.empty &&
            current != Cell.skull &&
            valids.where((valid) => cellAt(board, valid) == current).length == 3){
                threeCount++;
            }
        }
    }
    return threeCount;
}

int twoConnectedCount(List<List<Cell>> board){
    int twoCount = 0;
    for(int row = 0; row < 6; row++){
        for(int col = 0; col < board[row].length; col++){
            Point cp = new Point(col, row);
            Cell current = board[row][col];
            List<Point> valids = validNeighbors(cp, board);
            if(current != Cell.empty &&
            current != Cell.skull &&
            valids.where((valid) => cellAt(board, valid) == current).length == 2){
                twoCount++;
            }
        }
    }
    return twoCount;
}
