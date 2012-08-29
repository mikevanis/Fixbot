import processing.serial.*;
import java.util.*;

Serial robot;

// Segment stuff
int numSegments = 2;
float[] x = new float[numSegments];
float[] y = new float[numSegments];
float[] angle = new float[numSegments];
int[] servos = new int[numSegments+1];
float segLength = 400;
float targetX, targetY;

PFont font;

int delayTimeGoToStart = 1000;

LinkedList<Command> arm;

float distThreshold = 300;

int startTime;
int durationTime;
int mouseReleasedTime;

PVector currentPos = new PVector(0, 0), oldPos = new PVector(0, 0);

int ellipseSize = 5;

void setup() {
  // Drawing / arm setup
  size(1200, 800);
  smooth(); 
  strokeWeight(20.0);
  stroke(0, 100);
  x[x.length-1] = 400;     // Set base x-coordinate
  y[x.length-1] = 800;  // Set base y-coordinate

  // Font setup
  font = loadFont("HelveticaNeue-12.vlw");
  textFont(font, 10);

  // Serial port setup
  String portName = Serial.list()[4];
  robot = new Serial(this, portName, 115200);

  arm = new LinkedList<Command>();
}



void draw() {
  background(226);
  cursor(CROSS);

  // Show all points in arm buffer
  if (arm.size() > 0) {
    for (int i=0; i<arm.size(); i++) {
      PVector p = arm.get(i).getOrig();
      fill(color(0, 150, 0), 75);
      ellipse(p.x, p.y, ellipseSize+2, ellipseSize+2);
    }
  }

  // Show current point in sequence
  if (!mousePressed && arm.size() > 0) {
    int currentTime = (millis() - mouseReleasedTime) % durationTime;

    // Show current time
    fill(color(0, 150, 0));
    rect(0, height-3, map(currentTime, 0, durationTime, 0, width), 2);

    // Find best matching point in sequences
    int bestMatchIndex = timeToIndex(currentTime, arm);

    float distToLastPoint = 0;
    PVector commandArm = new PVector(0, 0);

    // Best matches
    if (bestMatchIndex != -1) {
      commandArm = arm.get(bestMatchIndex).getPoint();
      currentPos = arm.get(bestMatchIndex).getOrig();
      fill(color(0, 150, 0));
      ellipse(currentPos.x, currentPos.y, ellipseSize*2, ellipseSize*2);
      distToLastPoint = dist(currentPos.x, currentPos.y, oldPos.x, oldPos.y);
      oldPos.x = currentPos.x;
      oldPos.y = currentPos.y;
    }

    // Draw arm and send command!
    int destX = (int)commandArm.x;
    int destY = (int)commandArm.y;
    drawArm(destX, destY);
    String commandString = servos[0] + "," + servos[1] + "," + servos[2] + "\n";
    robot.write(commandString);
    println(commandString);

    // Wait if we have big gaps
    if (distToLastPoint > distThreshold) {
      delay(delayTimeGoToStart);
      mouseReleasedTime = millis();
    }
  }
  /*
  // Send commands
   if (mousePressed) {
   robot.write(servos[0] + "," + servos[1] + "," + "20" + "\n");
   }
   else {
   robot.write(servos[0] + "," + servos[1] + "," + servos[2] + "\n");
   }
   println(servos[0] + "," + servos[1] + "," + servos[2]);
   */
}



void mouseDragged() {
  if (arm.size() == 0) startTime = millis();

  // Store commands for robot
  int t = millis();

  t -= startTime;
  durationTime = t;
  arm.addLast(new Command(mouseX, mouseY, t));

  drawArm(mouseX, mouseY);
  String commandString = servos[0] + "," + servos[1] + "," + servos[2] + "\n";
  robot.write(commandString);
  println(commandString);
}

void mouseReleased() {
  mouseReleasedTime = millis();
  oldPos.x = mouseX;
  oldPos.y = mouseY;
}

void keyPressed() {
  if (key=='c' || key=='C') {
    arm.clear();
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

// Calculates arm angles and draws it on the screen
void drawArm(int tX, int tY) {
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

  // Store angles in servo values
  servos[0] = round(degrees(angle[0]-angle[1]));
  servos[1] = round(180-degrees((angle[1]) * -1));

  servos[2] = 270 - servos[0] - servos[1];
}

int timeToIndex(int theCurrentTime, LinkedList<Command> theEye) {
  int bestMatchIndex = -1;
  for (int i=theEye.size()-1; i>0; i--) {
    int t = theEye.get(i).getTime();
    if (theCurrentTime > t) {
      bestMatchIndex = max(i-1, 0);
      break;
    }
  }
  return bestMatchIndex;
}

