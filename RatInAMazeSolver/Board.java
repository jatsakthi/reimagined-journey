import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class Board {
  int[][] p;
  final int start = 2;
  final int end = 3;
  final int free = 0;
  final int barrier = 1;
  int[] spos;

  public Board(int r, int c) {
    p = new int[r][c];
    spos = preparePlayGround();
  }

  public Pos getSpos() {
    return new Pos(spos[0], spos[1]);
  }

  public int[] preparePlayGround() {
    Random ran = new Random();
    // Get starting position and ending position
    int[] spos = new int[] { ran.nextInt(p.length), ran.nextInt(p[0].length) };
    int[] epos = new int[] { ran.nextInt(p.length), ran.nextInt(p[0].length) };
    // Fill in the spos and epos
    p[spos[0]][spos[1]] = start;
    p[epos[0]][epos[1]] = end;
    // randomly generate the matrix

    for (int i = 0; i < p.length; i++) {
      for (int j = 0; j < p[0].length; j++) {
        if (p[i][j] == start || p[i][j] == end) continue;
        int k = ran.nextInt(100); // in the range [0,99]
        k = k > 29 ? free : barrier; // P(0) = 0.6, P(1) = 0.4
        p[i][j] = k;
      }
    }
    return spos;
  }

  public void show() {
    for (int i = 0; i < p.length; i++)
      System.out.println(Arrays.toString(p[i]));
  }

  public boolean isGoal(Pos pos) {
    return p[pos.row][pos.col] == end;
  }

  public boolean isBarrier(Pos pos) {
    return p[pos.row][pos.col] == barrier;
  }

  public List<Move> getLegalMoves(Pos pos) {
    List<Move> legalMoves = new ArrayList<>();
    int r = pos.row;
    int c = pos.col;
    if (c - 1 >= 0) legalMoves.add(Move.LEFT);
    if (c + 1 < p[0].length) legalMoves.add(Move.RIGHT);
    if (r - 1 >= 0) legalMoves.add(Move.UP);
    if (r + 1 < p.length) legalMoves.add(Move.DOWN);
    return legalMoves;
  }

  public Pos move(Pos pos, Move move) {
    if (move == Move.LEFT) return pos.moveLeft();
    else if (move == Move.RIGHT) return pos.moveRight();
    else if (move == Move.UP) return pos.moveUp();
    return pos.moveDown();
  }
}
