
int fft_lp = 2;
int fft_bp = 3;
int fft_hp = 4;

byte incomingByte;

void setup() {
  Serial.begin(9600);  
}

void loop() {
  // see if there's incoming serial data:
  if (Serial.available() > 0) {
    // read the oldest byte in the serial buffer:
    incomingByte = Serial.read();
    
    digitalWrite(fft_lp, bitRead(incomingByte,0));
    digitalWrite(fft_bp, bitRead(incomingByte,1));
    digitalWrite(fft_hp, bitRead(incomingByte,2));
  }
}

