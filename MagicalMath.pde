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
Complex calculateRangeMaxForAspRatio(Bounds area, double cTarget){
  Complex max = new Complex(cTarget, cTarget);
  if(area.h > area.w)
    max.real *= area.h / ((float) area.w);
  else
    max.imag *= area.h / ((float) area.w);
  return max;
}
Complex calculateRangeMinForAspRatio(Bounds area, double cTarget){
  Complex min = new Complex(cTarget, cTarget);
  if(area.h > area.w)
    min.real *= area.h / ((float) area.w);
  else
    min.imag *= area.h / ((float) area.w);
  return min;
}
public color getColor(int iter, color[] gradient, boolean sqrt){
  int pos = round(map(iter, 0, maxIterations, 0, gradient.length - 2));
  float perc = map(iter, 0.0, maxIterations, 0.0, 1.0);
  if(sqrt) perc = sqrt(perc);
  return lerpColor(gradient[pos], gradient[pos + 1], perc * gradient.length);
}
Complex positionToComplex(Bounds area, Complex max, Complex min, int x, int y){
  Complex pos = new Complex();
  pos.real = map(x, area.x, area.getXMax(), min.real, max.real);
  pos.imag = map(y, area.y, area.getYMax(), min.imag, max.imag);
  return pos;
}
int complexToX(Bounds area, Complex max, Complex min, Complex pos){
  return (int) map(pos.real, min.real, max.real, area.x, area.getXMax());
}
int complexToY(Bounds area, Complex max, Complex min, Complex pos){
  return (int) map(pos.imag, min.imag, max.imag, area.getYMax(), area.y);
}