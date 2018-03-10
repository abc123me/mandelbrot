CalcThread[] createThreadsJulia(int threadAmount, boolean start, Bounds totalArea, Complex min, Complex max, Complex c){
  CalcThread[] threads = new CalcThread[threadAmount];
  int pixelsPerThread = totalArea.w / threadAmount, remainingPixels = totalArea.w % threadAmount; 
  for(int i = 0, px = totalArea.x; i < threadAmount; i++){
    Bounds area = new Bounds(px, totalArea.y, pixelsPerThread + ((i >= threadAmount - 1) ? remainingPixels : 0), totalArea.h);
    threads[i] = new CalcThread(area, totalArea, min, max, c);
    if(start) threads[i].start();
    px += pixelsPerThread;
  }
  return threads;
}
CalcThread[] createThreadsMandelbrot(int threadAmount, boolean start, Bounds totalArea, Complex min, Complex max){
  CalcThread[] threads = new CalcThread[threadAmount];
  int pixelsPerThread = totalArea.w / threadAmount, remainingPixels = totalArea.w % threadAmount; 
  for(int i = 0, px = totalArea.x; i < threadAmount; i++){
    Bounds area = new Bounds(px, totalArea.y, pixelsPerThread + ((i >= threadAmount - 1) ? remainingPixels : 0), totalArea.h);
    threads[i] = new CalcThread(area, totalArea, min, max);
    if(start) threads[i].start();
    px += pixelsPerThread;
  }
  return threads;
}
public class CalcThread extends Thread{
  public final Bounds workingArea, totalArea;
  public final Complex min, max;;
  private Complex c = null;
  private int[][] results;
  
  public CalcThread(Bounds workingArea, Bounds totalArea, Complex min, Complex max, Complex c){
    this(workingArea, totalArea, min, max);
    this.c = c.copy();
  }
  public CalcThread(Bounds workingArea, Bounds totalArea, Complex min, Complex max){
    super(); 
    this.workingArea = workingArea.copy();
    this.totalArea = totalArea.copy();
    this.min = min; this.max = max;
    results = new int[workingArea.w][workingArea.h];
  }
  
  public void run(){
    for(int x = 0; x < workingArea.w; x++){
      for(int y = 0; y < workingArea.h; y++){
        double a = map(x + workingArea.x, totalArea.x, totalArea.getXMax(), min.real, max.real);
        double b = map(y + workingArea.y, totalArea.getYMax(), totalArea.y, min.imag, max.imag);
        if(c != null)
          results[x][y] = countIterations(a, b, c.real, c.imag, maxIterations);
        else
          results[x][y] = countIterations(a, b, maxIterations);
      }
    }
  }
  public Complex getC(){
    return c;
  }
  public int[][] getResults(){return results;}
}