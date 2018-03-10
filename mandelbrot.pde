public final color[][] gradients = {
  {color(0, 0, 0), color(255, 0, 0), color(255, 255, 0), color(255, 255, 255)}, //Heatmap
  {color(0), color(255, 0, 0), color(255, 255, 0), color(0, 255, 0), color(0, 255, 255), color(0, 0, 255), color(255, 0, 255), color(255, 0, 0)}, //Rainbow
  {color(0), color(255)} // Black & White
};

public int threads = 8;
public Bounds mandelbrotViewport, juliaViewport;
public int maxIterations = 250;
public Complex maxRangeM, minRangeM;
public Complex maxRangeJ, minRangeJ;
public boolean modifyCToAspRatio = true;
public boolean saveNextFrameAsScreenshot = false;
public int selectedGradient = 1;
public CalcThread[] mThreads, jThreads;
public long avgRenderTime = -1;
public float mandelRange = 2, juliaRange = 2;
public float curMandelRange = mandelRange, curJuliaRange = juliaRange;
public int viewPosX, viewPosY;
public int zoomLevel = 0, lastZoomLevel = 0;
public Complex offset = new Complex();
public boolean mandelbrotNeedsUpdating = true;
public boolean juliaNeedsUpdating = true;
public boolean mouseMode = true;
public boolean sqrtGradient = false;

void settings(){
  //float asp = 16 / 9.0;
  //int h = 512;
  //size((int)(h * asp), h);
  fullScreen();
}
void setup(){
  frameRate(60);
  threads = Runtime.getRuntime().availableProcessors();
  println("Detected " + threads + " cores");
  makeViewports(width, height);
  background(255);
}

void draw(){
  //background(255);
  checkInputs();
  Complex c = positionToComplex(juliaViewport, maxRangeM, minRangeM, viewPosX, viewPosY);
  if(saveNextFrameAsScreenshot){
    renderScreenshot(c);
    saveNextFrameAsScreenshot = false;
    return;
  }
  
  startFractals(c);
  drawThreadResults(mThreads, sqrtGradient);
  drawUI(c);
}

void startFractals(Complex c){
  if(juliaNeedsUpdating){
    long startMillis = millis();
    jThreads = createThreadsJulia(threads, true, juliaViewport, minRangeJ, maxRangeJ, c);
    joinThreadArr(jThreads);
    juliaNeedsUpdating = false;
    long renderTime = millis() - startMillis;
    if(avgRenderTime < 0) avgRenderTime = renderTime;
    else avgRenderTime = (avgRenderTime + renderTime) / 2;
    drawThreadResults(jThreads, sqrtGradient);
  }
  if(mandelbrotNeedsUpdating){
    mThreads = createThreadsMandelbrot(threads, true, mandelbrotViewport, minRangeM, maxRangeM);
    joinThreadArr(mThreads);
    mandelbrotNeedsUpdating = false;
  }
}
void renderScreenshot(Complex c){
  jThreads = createThreadsJulia(threads, true, juliaViewport, minRangeJ, maxRangeJ, c);
  joinThreadArr(jThreads);
  drawThreadResults(jThreads, sqrtGradient);
  saveFrame();
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
void makeViewports(int w, int h){
  mandelbrotViewport = new Bounds(0, 0, w / 5, h / 5);
  juliaViewport = new Bounds(0, 0, w, h);
  maxRangeM = calculateRangeMaxForAspRatio(mandelbrotViewport, curMandelRange);
  minRangeM = calculateRangeMinForAspRatio(mandelbrotViewport, -curMandelRange);
  maxRangeJ = calculateRangeMaxForAspRatio(juliaViewport, curJuliaRange);
  minRangeJ = calculateRangeMinForAspRatio(juliaViewport, -curJuliaRange);
}
void checkInputs(){
  if(mouseMode) {
    if(viewPosX != mouseX || viewPosY != mouseY){
      juliaNeedsUpdating = true;
      viewPosX = mouseX;
      viewPosY = mouseY;
    }
    if(zoomLevel != 0){
      float modificationIntensity = 1 / curJuliaRange;
      curJuliaRange += zoomLevel * modificationIntensity;
      curMandelRange += zoomLevel * modificationIntensity;
      makeViewports(width, height);
      offset = positionToComplex(juliaViewport, maxRangeM, minRangeM, viewPosX, viewPosY);
      offset.real *= -zoomLevel;
      offset.imag *= -zoomLevel;
      maxRangeJ.translateBy(offset);
      minRangeJ.translateBy(offset);
      maxRangeM.translateBy(offset);
      minRangeM.translateBy(offset);
      println(offset);
      mandelbrotNeedsUpdating = true;
      juliaNeedsUpdating = true;
      zoomLevel = 0;
    }
  }
}
void keyPressed(){
  if(key == 'P' || key == 'p')
    saveNextFrameAsScreenshot = true;
  if(key == 'M' || key == 'm'){
    mouseMode = !mouseMode;
    println("Mouse mode toggled!");
  }
  if(key == 'S' || key == 's'){
    sqrtGradient = !sqrtGradient;
    println("Toggled gradient square-rooting!");
    juliaNeedsUpdating = true;
    mandelbrotNeedsUpdating = true;
  }
  if(!mouseMode){
    if(keyCode == UP)
      viewPosY++;
    if(keyCode == DOWN)
      viewPosY--;
    if(keyCode == RIGHT)
      viewPosX++;
    if(keyCode == LEFT)
      viewPosX--;
    juliaNeedsUpdating = true;
  }
}
void mouseWheel(MouseEvent event){
  if(mouseMode)
    zoomLevel += event.getCount();
}