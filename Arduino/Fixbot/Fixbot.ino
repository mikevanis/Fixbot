#include <Servo.h>

String command;

Servo seg0;
Servo seg1;
Servo seg2;
Servo seg3;
Servo seg4;

void setup() {
  Serial.begin(115200);
  seg0.attach(8);
  seg1.attach(9);
  seg2.attach(10);
  seg3.attach(11);
  seg4.attach(12);
}

void loop() {
  if(Serial.available() > 0) {
    char inChar = Serial.read();
    command += inChar;
    if(inChar == '\n') {
      // clear command
      performCmd(command);
      command = "";
    }
    Serial.flush();
  }
}

void performCmd(String cmd) {
  int comma1 = cmd.indexOf(',');
  int comma2 = cmd.indexOf(',', comma1+1);
  int comma3 = cmd.indexOf(',', comma2+1);
  int comma4 = cmd.indexOf(',', comma3+1);
  
  int cmd0 = stringToInt(cmd.substring(0, comma1));
  int cmd1 = stringToInt(cmd.substring(comma1+1, comma2));
  int cmd2 = stringToInt(cmd.substring(comma2+1, comma3));
  int cmd3 = stringToInt(cmd.substring(comma3+1, comma4));
  int cmd4 = stringToInt(cmd.substring(comma4+1, cmd.length()));
  
  seg0.write(cmd0);
  seg1.write(cmd1);
  seg2.write(cmd2);
  seg3.write(cmd3);
  seg4.write(cmd4);
  
}

int stringToInt(String str) {
  String tmp = String(str);
  return str.toInt();
}
