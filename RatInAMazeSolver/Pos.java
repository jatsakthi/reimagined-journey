
public class Pos {
  int row, col;

  public Pos(int r, int c) {
    this.row = r;
    this.col = c;
  }

  public Pos moveLeft() {
    return new Pos(row, col - 1);
  }

  public Pos moveRight() {
    return new Pos(row, col + 1);
  }

  public Pos moveUp() {
    return new Pos(row - 1, col);
  }

  public Pos moveDown() {
    return new Pos(row + 1, col);
  }

  public String toString() {
    return "(" + row + "," + col + ")";
  }

  @Override public boolean equals(Object obj) {
    if (this == obj) return true;
    if (obj.getClass() != this.getClass() || obj == null) return false;
    Pos p = (Pos) obj;
    return this.row == p.row && this.col == p.col;
  }

  @Override public int hashCode() {
    return ("" + row + "," + col).hashCode();
  }

  public int getRow() {
    return this.row;
  }

  public int getCol() {
    return this.col;
  }
}
