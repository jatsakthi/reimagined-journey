
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.Set;

public class SequentialSolver extends Solver{
  static final Set<Pos> visited = new HashSet<>();
  public SequentialSolver(Board b) {
    super(b);
  }

  public List<Move> solve() {
    List<Move> moves = solveSequentially(b, new Cell(b.getSpos(), null, null));
    if (moves != null) Collections.reverse(moves);
    return moves;
  }

  public static List<Move> solveSequentially(Board b, Cell cell) {
    // do a BFS to find the shortest path
    Queue<Cell> current = new LinkedList<>();
    current.offer(cell);
    while (!current.isEmpty()) {
      int size = current.size();
      for (int i = 0; i < size; i++) {
        Cell c = current.poll();
        if (!visited.contains(c.pos) && !b.isBarrier(c.pos)) {
          visited.add(c.pos);
          if (b.isGoal(c.pos)) return c.getMovesAsList();
          for (Move move : b.getLegalMoves(c.pos)) {
            //System.out.println(cell.pos+" On this move: "+move);
            Pos pos = b.move(c.pos, move);
            Cell newCell = new Cell(pos, c, move);
            current.offer(newCell);
          }
        }
      }

    }
    return null;
  }
}
