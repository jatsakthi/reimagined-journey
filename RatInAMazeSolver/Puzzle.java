
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.Set;

/*
Find the shortest possible way to reach from starting position to ending position.


 */
public class Puzzle {
  public static void main(String[] args) {
    Board b = new Board(10000, 5000);
    //b.show();
    System.out.println("Staring posistion: " + b.getSpos());

    ConcurrentSolver cs = new ConcurrentSolver(b);
    timedSolve("Concurrent",cs);

    SequentialSolver ss = new SequentialSolver(b);
    timedSolve("Sequential",ss);
  }
  public static void timedSolve(String s, Solver solver){
    Long starTime = System.nanoTime();
    List<Move> moves = solver.solve();
    System.out.println(moves);
    System.out.println(String.format("%s found shortest path in %d sec",s,(System.nanoTime()-starTime)/1000000000));
  }
}


