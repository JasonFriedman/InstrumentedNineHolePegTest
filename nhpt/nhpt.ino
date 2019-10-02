// Code for running the instrumented nine hole peg test
// Full details for building the device can be found at https://github.com/JasonFriedman/InstrumentedNineHolePegTest

#include <Streaming.h>

int LEDs[] = {25, 27, 29, 31, 33, 35};

int diodes_5V[] =  { 7,  6,  5,  4,  3, 14, 15, 16, 17, 18,  19,  20,  21,  36, 38, 40};
int analogPins[] = {A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15};

int val_on[21];


int muxChannel[16][4] = { // From: http://bildr.org/2011/02/cd74hc4067-arduino/
  {0, 0, 0, 0}, //channel 0
  {1, 0, 0, 0}, //channel 1
  {0, 1, 0, 0}, //channel 2
  {1, 1, 0, 0}, //channel 3
  {0, 0, 1, 0}, //channel 4
  {1, 0, 1, 0}, //channel 5
  {0, 1, 1, 0}, //channel 6
  {1, 1, 1, 0}, //channel 7
  {0, 0, 0, 1}, //channel 8
  {1, 0, 0, 1}, //channel 9
  {0, 1, 0, 1}, //channel 10
  {1, 1, 0, 1}, //channel 11
  {0, 0, 1, 1}, //channel 12
  {1, 0, 1, 1}, //channel 13
  {0, 1, 1, 1}, //channel 14
  {1, 1, 1, 1} //channel 15
};

// Multiplexer pins
int S0 = 37;
int S1 = 39;
int S2 = 41;
int S3 = 43;

// 0 = off (no output), 1 = continuous output, 2 = only when requested
// Starts in mode 2
int mode = 2;

unsigned long lasttime = 0;
unsigned long lasttimesecs = 0;
int lasttimems = 0;

// Function definitions
void turnOnLEDsdiodes(int LED, int firstdiode, int lastdiode);
void turnOffLEDsdiodes(int LED, int firstdiode, int lastdiode);
void multiplexer(int channel);
void sendint(int val, int numPlacesBefore, bool trailingComma);

// the setup routine runs once when you press reset:
void setup() {
  // initialize the digital pin as an output.
  for (int i = 0; i <= 5; i++) {
    pinMode(LEDs[i], OUTPUT);
  }

  for (int i = 0; i <= 15; i++) {
    pinMode(diodes_5V[i], OUTPUT);
  }

  // Set multiplexer pins to output, and set them to 0
  pinMode(S0, OUTPUT); pinMode(S1, OUTPUT); pinMode(S2, OUTPUT); pinMode(S3, OUTPUT);
  digitalWrite(S0, 0); digitalWrite(S1, 0); digitalWrite(S2, 0); digitalWrite(S3, 0);

  Serial.begin(115200);
}

void loop() {
  int printdata = 0;
  // Read from the serial port, if it sent a "s", return a sample of data
  if (Serial.available()) {
    // Read the incoming byte
    int incoming = Serial.read();
    if (char(incoming) == '0') {
      mode = 0;
      Serial.println('0');
    } else if (char(incoming) == '1') {
      mode = 1;
      Serial.println('1');
    } else if (char(incoming) == '2') {
      mode = 2;
      Serial.println('2');
    } else if (mode == 2 && char(incoming) == 's') {
      printdata = 1;
    }
  }

  if (mode == 1) {
    printdata = 1;
  }

  if (printdata) {
    Serial.print("P");
    for (int i = 0; i <= 20; i++) {
      sendint(val_on[i], 4, 1);
    }
    // Send the time
    lasttimesecs = (lasttime / 1000) % 10000;
    lasttimems = lasttime % 1000;
    sendint(lasttimesecs, 4, 0);
    Serial << ".";
    sendint(lasttimems, 3, 0);
    Serial.println();
  }

  lasttime = millis();
  turnOnLEDsdiodes(0, 0, 3);
  for (int i = 0; i <= 3; i++) {
    val_on[i] = analogRead(analogPins[i]);
  }
  turnOffLEDsdiodes(0, 0, 3);

  turnOnLEDsdiodes(1, 4, 7);
  for (int i = 4; i <= 7; i++) {
    val_on[i] = analogRead(analogPins[i]);
  }
  turnOffLEDsdiodes(1, 4, 7);

  turnOnLEDsdiodes(2, 8, 11);
  for (int i = 8; i <= 11; i++) {
    val_on[i] = analogRead(analogPins[i]);
  }
  turnOffLEDsdiodes(2, 8, 11);

  turnOnLEDsdiodes(3, 12, 15);
  // Set the multiplexer for channel C0
  multiplexer(0);
  for (int i = 12; i <= 15; i++) {
    val_on[i] = analogRead(analogPins[i]);
  }
  // Don't turn off 15
  turnOffLEDsdiodes(3, 12, 14);

  // turn on LED 4 (diode 15 is already on)
  digitalWrite(LEDs[4], HIGH);
  for (int i = 1; i <= 4; i++) {
    // Set the multiplexer for channels C1,C2,C3,C4
    multiplexer(i);
    val_on[i + 15] = analogRead(analogPins[15]);
  }
  digitalWrite(LEDs[4], LOW);   // turn the LED off

  // turn on lone LED (diode 15 is already on)
  digitalWrite(LEDs[5], HIGH);
  // Set the multiplexer for the channel C5
  multiplexer(5);
  val_on[20] = analogRead(analogPins[15]);
  turnOffLEDsdiodes(5, 15, 15);
}

// Turn on the specified LED and diodes
void turnOnLEDsdiodes(int LED, int firstdiode, int lastdiode) {
  digitalWrite(LEDs[LED], HIGH);
  for (int i = firstdiode; i <= lastdiode; i++) {
    digitalWrite(diodes_5V[i], HIGH);
  }
}

// Turn off the specified LED and diodes
void turnOffLEDsdiodes(int LED, int firstdiode, int lastdiode) {
  digitalWrite(LEDs[LED], LOW);
  for (int i = firstdiode; i <= lastdiode; i++) {
    digitalWrite(diodes_5V[i], LOW);
  }
}

// Set the multiplexer to a given channel (between 0 and 15)
void multiplexer(int channel) {
  digitalWrite(S0, muxChannel[channel][0]);
  digitalWrite(S1, muxChannel[channel][1]);
  digitalWrite(S2, muxChannel[channel][2]);
  digitalWrite(S3, muxChannel[channel][3]);
}

// Send a fixed length integer through the Serial connection (padded with 0s at the beginning)
// numDigits - fixed number of digits to be send (0s will be added at the beginning)
// trailingComma - whether to add a comma after the number
void sendint(int val, int numPlacesBefore, bool trailingComma) {
  for (int k = numPlacesBefore - 1; k > 0; k--) {
    Serial << ( (val < pow(10, k)) ? "0" : "");
  }
  Serial << val;
  if (trailingComma) {
    Serial << ',';
  }
}
