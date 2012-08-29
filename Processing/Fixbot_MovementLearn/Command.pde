class Command {
  PVector dest;
  PVector orig;
  int timer;
  
  Command(int x, int y, int time) {
    float xDest = x;
    float yDest = y;
    dest = new PVector(xDest, yDest);
    orig = new PVector(x, y);
    timer = time;
  }
  
  // Return a point
  PVector getPoint() {
    int x = (int)dest.x;
    int y = (int)dest.y;
    return new PVector(x, y);
  }
  
  PVector getDest() {
    return dest;
  }
  
  PVector getOrig() {
    return orig;
  }
  
  int getTime() {
    return timer;
  }
}
