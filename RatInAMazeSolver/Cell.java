
import java.util.ArrayList;
import java.util.List;

public class Cell {
  Pos pos;
  Cell prevCell;
  Move move;

  public Cell(Pos p, Cell pC, Move m) {
    this.pos = p;
    this.prevCell = pC;
    this.move = m;
  }

  public List<Move> getMovesAsList() {
    List<Move> moves = new ArrayList<>();
    Cell cell = this;
    while (cell.move != null) {
      moves.add(cell.move);
      cell = cell.prevCell;
    }
    return moves;
  }
}
