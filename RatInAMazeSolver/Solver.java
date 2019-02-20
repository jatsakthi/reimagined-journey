
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public abstract class Solver {
  Board b;
  public Solver(Board b){
    this.b = b;
  }
  public abstract List<Move> solve();
}
