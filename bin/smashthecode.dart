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
int TIMEOUT = 85;
List<Move> lastMoves = [];

//timer class
Stopwatch sw = new Stopwatch();

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
        
        num myNuisance = (score2 % (70 * 6)) / 70;
        num oppNuisance = (score1 % (70 * 6)) / 70;
        
        stderr.writeln("My N $myNuisance Opp N $oppNuisance");

        me = new Player(myBoard, score1, myNuisance, turn);
        opp = new Player(oppBoard, score2, oppNuisance, turn);

        sw = new Stopwatch();
        sw.start();
        stderr.writeln("Reset Clock: ${sw.elapsedMilliseconds}");

        stderr.writeln("Upcoming: $pairs");
        printBoard(myBoard);

        //single depth ranking until depthEval works
        // Map rankMap = rankMoves(me);
        // stderr.writeln("Rankmap $rankMap");
        // List<Move> bestMoves = rankMap[rankMap.keys.last];
        // Move move = bestMoves[rand.nextInt(bestMoves.length)];

        Solution sol = findSolution(me, opp, pairs.take(7).toList());
        Move solMove = sol.p1Moves.first;
        lastMoves = sol.p1Moves;

        // if(rankMap.keys.last > sol.p1Eval){
        //     stderr.writeln("Chose single-depth move $move");
        //     print("${move.col} ${move.rot}");
        // } else {
        //     stderr.writeln("Chose solution move $solMove");
            print("${solMove.col} ${solMove.rot}");
        // }

        turn++;
        turn++;
    }
}

class Solution{
    Player p1Start;
    Player p2Start;
    Player p1End;
    Player p2End;
    List<Move> p1Moves;
    List<Move> p2Moves;
    List<Pair> pairs;

    int p1Death = -1;
    int p2Death = -1;

    num p1Nuisance = 0;
    num p2Nuisance = 0;

    num p1Eval = -1;
    num p2Eval = -1;

    num p1Discount;
    num p2Discount;

    Solution(this.p1Start, this.p2Start, this.pairs, this.p1Moves, this.p2Moves){
        p1End = p1Start.clone();
        p2End = p2Start.clone();
        p1Discount = p1Start.score;
        p2Discount = p2Start.score;
        applySolution();
    }

    void applySolution(){
        for(int index = 0; index < pairs.length && p1End.alive; index++){
            p1End = p1End.applyMove(p1Moves[index], pairs[index]);
            p1Discount += p1End.evaluate() * pow(.7, index);
            if(p1End.alive == false){
                p1Death = index;
            }
        }

        this.p1Eval = p1End.evaluate();
        if(p1Death > 0){
            this.p1Eval = -1000 + p1Death;
        }

    }

}

class Player {
    List<List<Cell>> board = [];
    int score;
    num nuisancePoints;
    int turn;
    num generatedNuisance = 0;
    bool alive = true;
    
    num eval = -1;

    Player(this.board, this.score, this.nuisancePoints, this.turn);

    Player clone(){
        List<List<Cell>> newBoard = new List.generate(6, (index) =>
            new List.from(this.board[index]));

        Player clone = new Player(newBoard, this.score, this.nuisancePoints, this.turn);
        clone.alive = this.alive;
        clone.generatedNuisance = this.generatedNuisance;

        return clone;
    }

    int get totalBlocks => board.fold(0, (prev, element) => prev + element.length);
    int get totalSkulls => board.fold(0,
        (prev, element) => prev +
        element.where((cell) => cell == Cell.skull).length);

    num evaluate(){
        if(eval != -1){
            return eval;
        }
        if(!alive){
            eval = double.NEGATIVE_INFINITY;
            return eval;
        }
        var counts = connectedCounts(board);
        int heightDiffs =
            (board[0].length - board[1].length).abs() +
            (board[1].length - board[2].length).abs() +
            (board[2].length - board[3].length).abs() +
            (board[3].length - board[4].length).abs() +
            (board[4].length - board[5].length).abs();

        eval =
            heightDiffs * 1 +
            counts[0] * 2 +
            counts[1] * 4 +
            this.totalBlocks * -4 +
            this.totalSkulls * -10 +
            this.generatedNuisance * 10 +
            this.score * 0;
        return eval;
    }

    //TODO add skull drop update method (board, int rows);

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
            // stderr.writeln("Attempting to apply invalid move $move!");
            // printBoard(this.board);
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
        Set<Point> removals = new Set<Point>();
        int blocksCleared = 0;
        int chainPower = 0;
        int colorBonus = 0;
        int groupBonus = 0;

        //stderr.writeln("Top point $top Cell ${cellAt(newBoard, top)}");
        Set<Point> topBlob = connected(newBoard, top);
        //stderr.writeln("Top Connected: $topBlob");
        if(topBlob.length > 3){
            removals.addAll(topBlob);
            blocksCleared += topBlob.length;
            groupBonus += groupBonusValue(topBlob.length);
        }

        if(!topBlob.contains(bottom)){
            //stderr.writeln("Bottom point $bottom Cell ${cellAt(newBoard, bottom)}");
            Set<Point> bottomBlob = connected(newBoard, bottom);
            //stderr.writeln("Bottom Connected: $bottomBlob");
            if(bottomBlob.length > 3){
                if(removals.length > 0 && pair.top != pair.bottom){
                    colorBonus = 2;
                }
                removals.addAll(bottomBlob);
                blocksCleared += bottomBlob.length;
                groupBonus += groupBonusValue(bottomBlob.length);
            }
        }

        if(removals.length > 0 ){
            removeBlobs(newBoard, removals);

            int scoreUpdate = 0;
            scoreUpdate += 10 * blocksCleared *
                min(max(1, chainPower + colorBonus + groupBonus), 999);

            bool blocksRemoved = true;
            while(blocksRemoved){
                blocksRemoved = false;
                var blobsToRemove = connectedColors(newBoard)
                    .where((blob) => blob.length >= 4);
                if(blobsToRemove.length > 0){
                    // stderr.writeln("Another step of blobs to remove found $blobsToRemove");
                    blocksRemoved = true;
                    removals = new Set<Point>();
                    blocksCleared = 0;
                    if(chainPower == 0){
                        chainPower = 8;
                    } else {
                        chainPower *= 2;
                    }
                    groupBonus = 0;
                    colorBonus = 0;

                    Set<Cell> colorsRemoved = new Set<Cell>();
                    for(Set<Point> blob in blobsToRemove){
                        colorsRemoved.add(cellAt(newBoard, blob.first));
                        blocksCleared += blob.length;
                        groupBonus += groupBonusValue(blob.length);
                        removals.addAll(blob);
                    }

                    colorBonus += colorBonusValue(colorsRemoved.length);

                    removeBlobs(newBoard, removals);

                    scoreUpdate += 10 * blocksCleared *
                        min(max(1, chainPower + colorBonus + groupBonus), 999);

                }
            }

            //stderr.writeln("Score update for move $scoreUpdate");
            updated.score += scoreUpdate;

        }
        updated.generatedNuisance = (updated.score - this.score) / 70;
        return updated;

    }

    void addNuisancePoints(int np){
        nuisancePoints += np;
    }

    int groupBonusValue(int blocks){
        if(blocks > 10){
            return 8;
        } else {
            return blocks - 4;
        }
    }

    int colorBonusValue(int colors){
        return [0,2,4,8,16][colors];
    }

    void removeBlobs(List<List<Cell>> board, Set<Point> removals){
        addRemovableSkulls(board, removals);
        // stderr.writeln("Added skulls to remove: $removals");

        //mark removals
        removals.forEach((removal) =>
            board[removal.y][removal.x] = Cell.empty
        );
        //remove
        for(List<Cell> cells in board){
            for(int index = 0; index < cells.length; index++ ){
                if(cells[index] == Cell.empty){
                    cells.removeAt(index);
                    index--;
                }
            }
        }
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
        switch (rot){
            case 1:
            case 3:
                return board[col].length < 11;
            case 0:
                return board[col].length < 12 
                    && board[col + 1].length < 12;
            case 2:
                return board[col].length < 12 
                    && board[col - 1].length < 12;
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

    Point(this.x, this.y);

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

List<Point> validNeighbors(List<List<Cell>> board, Point current){
    List<Point> valids = current.neighbors4.where((neighbor) =>
        neighbor.y >= 0 && neighbor.y < 6 &&
        neighbor.x >= 0 && neighbor.x < 12
    ).toList();
    return valids;
}

Set<Point> connected(List<List<Cell>> board, Point start){
    List<Point> open = [start];
    Set<Point> closed = new Set<Point>();
    Set<Point> acc = new Set<Point>();
    return connectedRec(board, cellAt(board, start), open, closed, acc);
}

Set<Point> connectedRec(List<List<Cell>> board,
    Cell goal, List<Point> open, Set<Point> closed,
    Set<Point> acc){

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
        List<Point> valids = validNeighbors(board, current);

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
    // stderr.writeln("Ranking possible moves. Current eval ${player.evaluate()}");
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

List<Set<Point>> connectedColors(List<List<Cell>> board){
    List<Set<Point>> blobs = new List<Set<Point>>();
    Set<Point> allBlobbed = new Set<Point>();
    for(int row = 0; row < 6; row++){
        for(int col = 0; col < board[row].length; col++){
            //TODO reduce duplicate scanning with closed set
            Point cp = new Point(col, row);
            if(allBlobbed.contains(cp) || cellAt(board, cp) == Cell.skull){
                //already in a blob or not a color, skip it.
                continue;
            }
            Set<Point> blob = connected(board, cp);
            allBlobbed.addAll(blob);
            if(blob.length > 1){
                blobs.add(blob);
            }
        }
    }
    return blobs;
}

List<int> connectedCounts(List<List<Cell>> board){
    List<int> counts = [0, 0];
    for(int row = 0; row < 6; row++){
        for(int col = 0; col < board[row].length; col++){
            Cell current = board[row][col];
            if(current != Cell.empty && current != Cell.skull){
                Point cp = new Point(col, row);
                List<Point> valids = validNeighbors(board, cp);
                var group = valids.where((valid) => cellAt(board, valid) == current);
                if(group.length == 1){
                    counts[0]++;
                } else if (group.length == 2){
                    counts[1]++;
                }
            }
        }
    }
    return counts;
}

void addRemovableSkulls(List<List<Cell>> board, Set<Point> removals){
    Set<Point> skulls = new Set<Point>();
    for(int row = 0; row < 6; row++){
        for(int col = 0; col < board[row].length; col++){
            Point cp = new Point(col, row);
            if(board[row][col] == Cell.skull &&
                validNeighbors(board, cp).any((nbr) => removals.contains(nbr))){
                skulls.add(cp);
            }
        }
    }
    removals.addAll(skulls);
}

Solution findSolution(Player me, Player opp, List<Pair> pairs){
    int simCount = 0;
    //start with last turn's moves
    if(lastMoves.isNotEmpty){
        lastMoves.removeAt(0);
        lastMoves.add(pairs[lastMoves.length].allMoves()[rand.nextInt(
                pairs[lastMoves.length].allMoves().length)]);
    } else {
        lastMoves = randomMoves(pairs);
    }

    Solution current = new Solution(me, opp, pairs,
        lastMoves,
        randomMoves(pairs));

    while(sw.elapsedMilliseconds < TIMEOUT){
        Solution newSol = new Solution(me, opp, pairs,
            randomMoves(pairs),
            randomMoves(pairs));
        if(newSol.p1Discount > //  + newSol.p1Eval >
            current.p1Discount){ // + current.p1Eval){
            current = newSol;
        }
        simCount++;
    }
    stderr.writeln("$simCount sims, returning eval ${current.p1Eval}");

    return current;

}

List<Move> randomMoves(pairs){
    return new List.generate(pairs.length, (index) =>
        pairs[index].allMoves()[rand.nextInt(
            pairs[index].allMoves().length)]);
}
