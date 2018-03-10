public final color[][] gradients = {
  {color(0, 0, 0), color(255, 0, 0), color(255, 255, 0), color(255, 255, 255)}, //Heatmap
  {color(0), color(255, 0, 0), color(255, 255, 0), color(0, 255, 0), color(0, 255, 255), color(0, 0, 255), color(255, 0, 255), color(255, 0, 0)}, //Rainbow
  {color(0), color(255)} // Black & White
};
public final int THREADS = 4;

public Bounds mandelbrotViewport, juliaViewport;
public int maxIterations = 250;
public Complex maxRangeM, minRangeM;
public Complex maxRangeJ, minRangeJ;
public boolean modifyCToAspRatio = true;
public int selectedGradient = 1;
public CalcThread[] mThreads, jThreads;
public long avgRenderTime = -1;

public int mandelbrotViewPosX, mandelbrotViewPosY;
public boolean mandelbrotNeedsUpdating = true;
public boolean juliaNeedsUpdating = true;
public boolean mouseMode = true;

void setup(){
  //fullScreen();
  size(1080, 768); 
  frameRate(60);
  mandelbrotViewport = new Bounds(0, 0, width / 5, height / 5);
  juliaViewport = new Bounds(0, 0, width, height);
  maxRangeM = calculateRangeMaxForAspRatio(mandelbrotViewport, 2);
  minRangeM = calculateRangeMinForAspRatio(mandelbrotViewport, -2);
  maxRangeJ = calculateRangeMaxForAspRatio(juliaViewport, 2);
  minRangeJ = calculateRangeMinForAspRatio(juliaViewport, -2);
  background(255);
}

void draw(){
  //background(255);
  
  checkInputs();
  Complex c = positionToComplex(juliaViewport, maxRangeM, minRangeM, mandelbrotViewPosX, mandelbrotViewPosY);
  if(juliaNeedsUpdating){
    long startMillis = millis();
    jThreads = createThreadsJulia(THREADS, true, juliaViewport, minRangeJ, maxRangeJ, c);
    joinThreadArr(jThreads);
    juliaNeedsUpdating = false;
    long renderTime = millis() - startMillis;
    if(avgRenderTime < 0) avgRenderTime = renderTime;
    else avgRenderTime = (avgRenderTime + renderTime) / 2;
    println("Julia done in: " + renderTime + "ms");
    drawThreadResults(jThreads);
  }
  if(mandelbrotNeedsUpdating){
    long startMillis = millis();
    mThreads = createThreadsMandelbrot(THREADS, true, mandelbrotViewport, minRangeM, maxRangeM);
    joinThreadArr(mThreads);
    mandelbrotNeedsUpdating = false;
    println("Mandelbrot done in: " + (millis() - startMillis) + "ms");
  }
 
  drawThreadResults(mThreads);
 
  drawUI(c);
}

void drawUI(Complex c){
  stroke(255);
  text("c: " + c.toString(3), 0, textAscent());
  text("Framerate: " + frameRate, 0, 2 * textAscent());
  text("Average render time: " + avgRenderTime + "ms", 0, 3 * textAscent());
  int x = complexToX(mandelbrotViewport, maxRangeM, minRangeM, c);
  int y = complexToY(mandelbrotViewport, minRangeM, maxRangeM, c);
  line(x, mandelbrotViewport.y, x, mandelbrotViewport.getYMax());
  line(mandelbrotViewport.x, y, mandelbrotViewport.getXMax(), y);
}
void checkInputs(){
  if(!mouseMode){
    if(keyCode == UP || key == 'W' || key == 'w')
      mandelbrotViewPosY++;
    if(keyCode == DOWN || key == 'S' || key == 's')
      mandelbrotViewPosY--;
    if(keyCode == RIGHT || key == 'D' || key == 'd')
      mandelbrotViewPosX++;
    if(keyCode == LEFT || key == 'A' || key == 'a')
      mandelbrotViewPosX--;
    juliaNeedsUpdating = true;
  }
  if(mouseMode && (mandelbrotViewPosX != mouseX || mandelbrotViewPosY != mouseY)){
    juliaNeedsUpdating = true;
    mandelbrotViewPosX = mouseX;
    mandelbrotViewPosY = mouseY;
  }
}
void keyPressed(){
  if(key == 'M' || key == 'm'){
    mouseMode = !mouseMode;
    println("Mouse mode toggled!");
  }
}