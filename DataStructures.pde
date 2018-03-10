import java.text.DecimalFormat;

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
  
  public Complex add(Complex to){
    return new Complex(real + to.real, imag + to.imag);
  }
  public Complex translateBy(Complex by){
    real += by.real;
    imag += by.imag;
    return this;
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