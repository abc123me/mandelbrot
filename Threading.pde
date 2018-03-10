void joinThreadArr(Thread[] threads){
  try{
    for(Thread t : threads)
      t.join();
  }
  catch(Exception e){
    System.err.println("Main thread interrupted: " + e);
    e.printStackTrace();
  }
}
void drawThreadResults(CalcThread[] threads, boolean sqrt){
  for(CalcThread t : threads){
    int[][] res = t.getResults();
    for(int x = 0; x < t.workingArea.w; x++){
      for(int y = 0; y < t.workingArea.h; y++){
        color c = getColor(res[x][y], gradients[selectedGradient], sqrt);
        int px = x + t.workingArea.x, py = y + t.workingArea.y;
        set(px, py, c);
      }
    }
  }
}