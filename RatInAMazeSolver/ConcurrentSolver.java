
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionHandler;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.atomic.AtomicInteger;

public class ConcurrentSolver extends Solver{
  private final ExecutorService executorService;
  private final ConcurrentMap<Pos,Boolean> visited;
  final ValueLatch<Cell> solution = new ValueLatch<>();
  private final AtomicInteger taskCount = new AtomicInteger(0);

  public ConcurrentSolver(Board b) {
    super(b);
    executorService = Executors.newFixedThreadPool(2000);
    visited = new ConcurrentHashMap<>();
  }

  @Override public List<Move> solve(){
    try{
      executorService.execute(newTask(b.getSpos(),null,null));
      ((ThreadPoolExecutor) executorService).setRejectedExecutionHandler(new RejectedExecutionHandlerImpl());
      Cell solutionCell = solution.getValue();
      List<Move> solution = solutionCell == null ? null : solutionCell.getMovesAsList();
      if (solution != null) Collections.reverse(solution);
      return solution;
    } catch (InterruptedException ie){
      System.out.println("InterruptedException Caught");
      ie.printStackTrace();
    }
    finally {
      executorService.shutdownNow();
    }
    return null;
  }
  protected Runnable newTask(Pos pos, Move m, Cell cell){
    return new CountingSolverTask(pos,cell,m);
  }

  class RejectedExecutionHandlerImpl implements RejectedExecutionHandler {

    @Override public void rejectedExecution(Runnable r, ThreadPoolExecutor executor) {
      //System.out.println(r.toString() + " is rejected");
      // do Nothing
    }
  }

  class SolverTask extends Cell implements Runnable{
    String command;
    public SolverTask(Pos p, Cell pC, Move m) {
      super(p, pC, m);
      command = p.toString();
    }

    @Override public void run() {
      if(solution.isSet() || visited.putIfAbsent(pos,true) !=null || b.isBarrier(pos)) return;
      if(b.isGoal(pos)) solution.setValue(this);
      else {
        for (Move move : b.getLegalMoves(pos)){
          Pos np = b.move(pos,move);
          //System.out.println(command + " creating task for "+np);
          executorService.execute(newTask(np,move,this));
        }
      }
    }

    public String toString(){
      return command;
    }
  }

  class CountingSolverTask extends SolverTask{
    public CountingSolverTask(Pos p, Cell pC, Move m) {
      super(p, pC, m);
      taskCount.incrementAndGet();
    }

    @Override public void run() {
      try{
        super.run();
      }finally {
        if(taskCount.decrementAndGet()==0) solution.setValue(null);
      }
    }
  }
}

class ValueLatch<T>{
  private T value = null;
  private final CountDownLatch done = new CountDownLatch(1);

  public boolean isSet(){
    return done.getCount()==0;
  }

  public synchronized void setValue(T newVaue){
    if(!isSet()){
      value = newVaue;
      done.countDown();
    }
  }

  public T getValue() throws InterruptedException{
    done.await();
    synchronized (this){
      return value;
    }
  }

}
