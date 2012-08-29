import processing.serial.*;
import java.util.*;

Serial robot;

// Segment stuff
int numSegments = 2;
float[] x = new float[numSegments];
float[] y = new float[numSegments];
float[] angle = new float[numSegments];
int[] servos = new int[numSegments+2];
float segLength = 400;
float targetX, targetY;

int headTilt = 0;

int independent = 0;
int destinationMode = 0;
int destination = 1;

PFont font;

int delayTimeGoToStart = 1000;

LinkedList<PVector> marks;

void setup() {
  // Drawing / arm setup
  size(1200, 800);
  smooth(); 
  strokeWeight(20.0);
  stroke(0, 100);
  x[x.length-1] = 400;     // Set base x-coordinate
  y[x.length-1] = 800;  // Set base y-coordinate
  marks = new LinkedList<PVector>();

  // Font setup
  font = loadFont("HelveticaNeue-12.vlw");
  textFont(font, 10);
  
  // Serial port setup
  String portName = Serial.list()[0];
  robot = new Serial(this, portName, 115200);
  servos[3] = 110;
}



void draw() {
  background(226);
  cursor(CROSS);
  
  int destX = mouseX;
  int destY = mouseY;
  
  // Draw all marked points
  if(marks.size() > 0) {
    for(int i=0; i < marks.size(); i++) {
      pushMatrix();
      stroke(0);
      strokeWeight(2);
      PVector mark = marks.get(i);
      point(mark.x, mark.y);
      translate(mark.x + 5, mark.y);
      text(i+1, 0, 0);
      popMatrix();
    }
  }
  
  if(destinationMode == 0) {
    // Calculate segments and draw the arm.
    drawArm(destX, destY);
  }
  else {
    if(marks.size() > 0) {
      PVector dest = marks.get(destination-1);
      println(destination);
      drawArm(int(dest.x), int(dest.y));
    }
  }
  
  // Store angles in servo values
  servos[1] = round(degrees(angle[0]-angle[1]));
  servos[0] = round(180-degrees((angle[1]) * -1));
  
  if(independent == 0) {
    servos[2] = 270 - servos[1] - servos[0];
  }
  else {
    servos[2] = constrain(headTilt, 0, 180);
  }
  
  

  // Send commands
  if (mousePressed) {
    robot.write(servos[0] + "," + servos[1] + "," + servos[2] + "," + servos[3] + "," + "45" + "\n");
  }
  else {
    robot.write(servos[0] + "," + servos[1] + "," + servos[2] + "," + servos[3] + "," + "90" + "\n");
  }
}

// Switch between different modes & controls depending on key events
void keyPressed() {
  if(key == 'm' || key == 'M') {
    marks.addLast(new PVector(mouseX, mouseY));
  }
  else if(key == 'c' || key == 'C') {
    marks.clear();
  }
  else if(key == 'd' || key == 'D') {
    destinationMode = 1 - destinationMode;
  }
  else if(key == CODED) {
    if(keyCode == SHIFT) {
     independent = 1-independent;
    } 
    else if(keyCode == UP) {
      headTilt++;
    }
    else if(keyCode == DOWN) {
      headTilt--;
    }
    else if(keyCode == LEFT) {
      servos[3] = servos[3] - 80;
    }
    else if(keyCode == RIGHT) {
      servos[3] = servos[3] + 80;
    }
  }
  else {
    destination = key-48;
  }
}




void positionSegment(int a, int b) {
  x[b] = x[a] + cos(angle[a]) * segLength;
  y[b] = y[a] + sin(angle[a]) * segLength;
}

void reachSegment(int i, float xin, float yin) {
  float dx = xin - x[i];
  float dy = yin - y[i];
  angle[i] = atan2(dy, dx);  
  targetX = xin - cos(angle[i]) * segLength;
  targetY = yin - sin(angle[i]) * segLength;
}

void segment(float x, float y, float a, float sw) {
  strokeWeight(sw);
  pushMatrix();
  translate(x, y);
  rotate(a);
  line(0, 0, segLength, 0);
  text(degrees(a) + "deg.", segLength/4, 15);
  popMatrix();

  pushMatrix();
  translate(x, y);
  rotate(a);
  translate(segLength/9, 0);
  rotate(-a);

  popMatrix();
}

void drawArm(int tX, int tY) {
  strokeWeight(20.0);
  stroke(0, 100);
  reachSegment(0, tX, tY);
  for (int i=1; i<numSegments; i++) {
    reachSegment(i, targetX, targetY);
  }
  for (int i=x.length-1; i>=1; i--) {
    positionSegment(i, i-1);
  } 

  fill(0);
  text("---Relative angles---", 490, 20);

  for (int i=0; i<x.length; i++) {
    segment(x[i], y[i], angle[i], (i+1)*4); 
    if (i < x.length-1) {
      text("Seg" + i + ": " + degrees(angle[i]-angle[i+1]), 490, 30 + i*10);
    }
    else {
      text("Seg" + i + ": " + degrees(angle[i]), 490, 30 + i*10);
    }
  }
}

