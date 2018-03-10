import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.text.DecimalFormat; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class mandelbrot extends PApplet {

public final int[][] gradients = {
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

public void setup(){
  //fullScreen();
   
  frameRate(60);
  mandelbrotViewport = new Bounds(0, 0, width / 5, height / 5);
  juliaViewport = new Bounds(0, 0, width, height);
  maxRangeM = calculateRangeMaxForAspRatio(mandelbrotViewport, 2);
  minRangeM = calculateRangeMinForAspRatio(mandelbrotViewport, -2);
  maxRangeJ = calculateRangeMaxForAspRatio(juliaViewport, 2);
  minRangeJ = calculateRangeMinForAspRatio(juliaViewport, -2);
  background(255);
}

public void draw(){
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

public void drawUI(Complex c){
  stroke(255);
  text("c: " + c.toString(3), 0, textAscent());
  text("Framerate: " + frameRate, 0, 2 * textAscent());
  text("Average render time: " + avgRenderTime + "ms", 0, 3 * textAscent());
  int x = complexToX(mandelbrotViewport, maxRangeM, minRangeM, c);
  int y = complexToY(mandelbrotViewport, minRangeM, maxRangeM, c);
  line(x, mandelbrotViewport.y, x, mandelbrotViewport.getYMax());
  line(mandelbrotViewport.x, y, mandelbrotViewport.getXMax(), y);
}
public void checkInputs(){
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
public void keyPressed(){
  if(key == 'M' || key == 'm'){
    mouseMode = !mouseMode;
    println("Mouse mode toggled!");
  }
}
public CalcThread[] createThreadsJulia(int threadAmount, boolean start, Bounds totalArea, Complex min, Complex max, Complex c){
  CalcThread[] threads = new CalcThread[threadAmount];
  int pixelsPerThread = totalArea.w / THREADS, remainingPixels = totalArea.w % THREADS; 
  for(int i = 0, px = totalArea.x; i < threadAmount; i++){
    Bounds area = new Bounds(px, totalArea.y, pixelsPerThread + ((i >= THREADS - 1) ? remainingPixels : 0), totalArea.h);
    threads[i] = new CalcThread(area, totalArea, min, max, c);
    if(start) threads[i].start();
    px += pixelsPerThread;
  }
  return threads;
}
public CalcThread[] createThreadsMandelbrot(int threadAmount, boolean start, Bounds totalArea, Complex min, Complex max){
  CalcThread[] threads = new CalcThread[threadAmount];
  int pixelsPerThread = totalArea.w / THREADS, remainingPixels = totalArea.w % THREADS; 
  for(int i = 0, px = totalArea.x; i < threadAmount; i++){
    Bounds area = new Bounds(px, totalArea.y, pixelsPerThread + ((i >= THREADS - 1) ? remainingPixels : 0), totalArea.h);
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


public class Complex{
  public double real, imag;
  
  public Complex(double real, double imag){
    this.real = real;
    this.imag = imag;
  }
  public Complex(double real){this(real, 0);}
  public Complex(){this(0, 0);}
  
  public double abs(){
    return Math.sqrt(real * real + imag * imag);
  }
  
  public Complex copy(){
    return new Complex(real, imag);
  }
  public String toString(){
    if(imag < 0)
      return real + " - " + (imag * -1) + "i";
    else
      return real + " + " + imag + "i";
  }
  public String toString(int digits){
    String format = "#.";
    for(int i = 0; i < digits; i++) 
      format += "#";
    DecimalFormat df = new DecimalFormat("#.#####");
    if(imag < 0)
      return df.format(real) + " - " + df.format((imag * -1)) + "i";
    else
      return df.format(real) + " + " + df.format(imag) + "i";
  }
}
public class ComplexFloat{
  public float real, imag;
  
  public ComplexFloat(float real, float imag){
    this.real = real;
    this.imag = imag;
  }
  public ComplexFloat(float real){this(real, 0);}
  public ComplexFloat(){this(0, 0);}
  
  public double abs(){
    return Math.sqrt(real * real + imag * imag);
  }
  
  public ComplexFloat copy(){
    return new ComplexFloat(real, imag);
  }
  public String toString(){
    if(imag < 0)
      return real + " - " + (imag * -1) + "i";
    else
      return real + " + " + imag + "i";
  }
  public String toString(int digits){
    String format = "#.";
    for(int i = 0; i < digits; i++) 
      format += "#";
    DecimalFormat df = new DecimalFormat("#.#####");
    if(imag < 0)
      return df.format(real) + " - " + df.format((imag * -1)) + "i";
    else
      return df.format(real) + " + " + df.format(imag) + "i";
  }
}
public class Bounds{
  public int x, y;
  private int w, h;
  public Bounds(int x, int y, int w, int h){
    setPosition(x, y);
    setSize(w, h);
  }
  public void setSize(int w, int h){
    if(w <= 0 || h <= 0)
      throw new RuntimeException("Width and Height must be greater than 0!");
    this.w = w; 
    this.h = h;
  }
  public void setPosition(int x, int y){
    this.x = x;
    this.y = y;
  }
  public boolean inBounds(int x, int y){
    return x >= this.x && x <= getXMax() && y >= this.y && y <= getYMax();
  }
  
  public int getWidth(){return w;}
  public int getHeight(){return h;}
  public void setWidth(int w){setSize(w, h);}
  public void setHeight(int h){setSize(w, h);}
  public int getXMax(){return x + w;}
  public int getYMax(){return y + h;}
  
  public Bounds copy(){
    return new Bounds(x, y, w, h);
  }
}
public static int countIterations(double a, double b, int maxIterations){ 
  return countIterations(a, b, a, b, maxIterations);
}
public static int countIterations(double a, double b, double ca, double cb, int maxIterations){ 
  for(int i = 0; i < maxIterations; i++){
    double a2 = a * a, b2 = b * b;
    double c = 2 * a * b;
    a = a2 - b2 + ca;
    b = c + cb;
    if(a + b > 16)
      return i;
  }
  return maxIterations;
}
public static final double map(double val, double min, double max, double newMin, double newMax){
  return ((val - min) / (max - min)) * (newMax - newMin) + newMin;
}
public Complex calculateRangeMaxForAspRatio(Bounds area, double cTarget){
  Complex max = new Complex(cTarget, cTarget);
  if(area.h > area.w)
    max.real *= area.h / ((float) area.w);
  else
    max.imag *= area.h / ((float) area.w);
  return max;
}
public Complex calculateRangeMinForAspRatio(Bounds area, double cTarget){
  Complex min = new Complex(cTarget, cTarget);
  if(area.h > area.w)
    min.real *= area.h / ((float) area.w);
  else
    min.imag *= area.h / ((float) area.w);
  return min;
}
public int getColor(int iter, int[] gradient){
  int pos = round(map(iter, 0, maxIterations, 0, gradient.length - 2));
  float perc = map(iter, 0.0f, maxIterations, 0.0f, 1.0f);
  return lerpColor(gradient[pos], gradient[pos + 1], perc * gradient.length);
}
public Complex positionToComplex(Bounds area, Complex max, Complex min, int x, int y){
  Complex pos = new Complex();
  pos.real = map(mouseX, area.x, area.getXMax(), min.real, max.real);
  pos.imag = map(mouseY, area.y, area.getYMax(), min.imag, max.imag);
  return pos;
}
public int complexToX(Bounds area, Complex max, Complex min, Complex pos){
  return (int) map(pos.real, min.real, max.real, area.x, area.getXMax());
}
public int complexToY(Bounds area, Complex max, Complex min, Complex pos){
  return (int) map(pos.imag, min.imag, max.imag, area.getYMax(), area.y);
}
public void joinThreadArr(Thread[] threads){
  try{
    for(Thread t : threads)
      t.join();
  }
  catch(Exception e){
    System.err.println("Main thread interrupted: " + e);
    e.printStackTrace();
  }
}
public void drawThreadResults(CalcThread[] threads){
  for(CalcThread t : threads){
    int[][] res = t.getResults();
    for(int x = 0; x < t.workingArea.w; x++){
      for(int y = 0; y < t.workingArea.h; y++){
        int c = getColor(res[x][y], gradients[selectedGradient]);
        int px = x + t.workingArea.x, py = y + t.workingArea.y;
        set(px, py, c);
      }
    }
  }
}
  public void settings() {  size(1080, 768); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "mandelbrot" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
