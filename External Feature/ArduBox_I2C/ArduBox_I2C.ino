#include <Versatile_RotaryEncoder.h>
#include <Wire.h>
#include <DFRobot_DHT11.h>


#define POT_1 A0
#define DHT11 A1
#define IR_LINE 7
#define BUZZ 8
#define LED_R 5
#define LED_G 6
#define LED_B 9
#define EncCLK 2
#define EncDT 3
#define EncSW 4

char reg;
char cmd;
unsigned char valueEncoder = 0;
unsigned char tokenBtnEncoder = 0;
int encoderVal = 0;

#define interval 30000
unsigned long previousMillis = 0;

DFRobot_DHT11 DHT;

// Functions prototyping to be handled on each Encoder Event
void handleRotate(int8_t rotation);
void handlePressRotate(int8_t rotation);
void handleHeldRotate(int8_t rotation);
void handlePress();
void handlePressRelease();
void handleLongPress();
void handleLongPressRelease();
void handlePressRotateRelease();
void handleHeldRotateRelease();

// Create a global pointer for the encoder object
Versatile_RotaryEncoder *versatile_encoder;

void setup() {
    analogReference(EXTERNAL);

    Serial.begin(9600);
	  versatile_encoder = new Versatile_RotaryEncoder(EncCLK, EncDT, EncSW);

    // Load to the encoder all nedded handle functions here (up to 9 functions)
    versatile_encoder->setHandleRotate(handleRotate);
    versatile_encoder->setHandlePressRotate(handlePressRotate);
    versatile_encoder->setHandleHeldRotate(handleHeldRotate);
    versatile_encoder->setHandlePress(handlePress);
    versatile_encoder->setHandlePressRelease(handlePressRelease);
    versatile_encoder->setHandleLongPress(handleLongPress);
    versatile_encoder->setHandleLongPressRelease(handleLongPressRelease);
    versatile_encoder->setHandlePressRotateRelease(handlePressRotateRelease);
    versatile_encoder->setHandleHeldRotateRelease(handleHeldRotateRelease);

    pinMode(IR_LINE, INPUT);
    pinMode(BUZZ, OUTPUT);
    pinMode(LED_R, OUTPUT);
    pinMode(LED_G, OUTPUT);
    pinMode(LED_B, OUTPUT);

    Wire.begin(8);                // join i2c bus with address #8
    Wire.onReceive(receiveEvent); // register event
    Wire.onRequest(requestEvent);

    Serial.println("Ready!");

    // set your own defualt values (optional)
    // versatile_encoder->setInvertedSwitch(true); // inverts the switch behaviour from HIGH to LOW to LOW to HIGH
    // versatile_encoder->setReadIntervalDuration(1); // set 2ms as long press duration (default is 1ms)
    // versatile_encoder->setShortPressDuration(35); // set 35ms as short press duration (default is 50ms)
    // versatile_encoder->setLongPressDuration(550); // set 550ms as long press duration (default is 1000ms)

}

void loop() {

    // Do the encoder reading and processing
    if (versatile_encoder->ReadEncoder()) {
        // Do something here whenever an encoder action is read 
    }

  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    DHT.read(DHT11);
  }
}

// Implement your functions here accordingly to your needs

void handleRotate(int8_t rotation) {
	//Serial.print("#1 Rotated: ");
    if (rotation > 0) {
      if(valueEncoder < 255) {valueEncoder++;}
	    //Serial.println("Right");
      encoderVal++;
    } else {
      if(valueEncoder > 0) {valueEncoder--;}
	    //Serial.println("Left");
      encoderVal--;
    }
    Serial.println(valueEncoder, DEC);
}

void handlePressRotate(int8_t rotation) {
	Serial.print("#2 Pressed and rotated: ");
    if (rotation > 0)
	    Serial.println("Right");
    else
	    Serial.println("Left");
}

void handleHeldRotate(int8_t rotation) {
	Serial.print("#3 Held and rotated: ");
    if (rotation > 0)
	    Serial.println("Right");
    else
	    Serial.println("Left");
}

void handlePress() {
	Serial.println("#4 Pressed");
  tokenBtnEncoder = 1;
}

void handlePressRelease() {
	Serial.println("#5 Press released");
  tokenBtnEncoder = 2;
}

void handleLongPress() {
	Serial.println("#6 Long pressed");
  tokenBtnEncoder = 3;
}

void handleLongPressRelease() {
	Serial.println("#7 Long press released");
  tokenBtnEncoder = 4;
}

void handlePressRotateRelease() {
	Serial.println("#8 Press rotate released");
}

void handleHeldRotateRelease() {
	Serial.println("#9 Held rotate released");
}

void receiveEvent(int howMany) {
  if(howMany == 1) {
    reg = Wire.read();
    cmd = 0xff;
  } else if(howMany == 2) {
    reg = Wire.read();
    cmd = Wire.read();

    // Write
    if(reg == 0x02) {
      valueEncoder = cmd;
    }

    if(reg == 0x06) {
      digitalWrite(BUZZ, cmd);
    }

    if(reg == 0x07) {
      analogWrite(LED_R, cmd);
    }

    if(reg == 0x08) {
      analogWrite(LED_G, cmd);
    }

    if(reg == 0x09) {
      analogWrite(LED_B, cmd);
    }



  } else {
    reg = -1;
    Serial.print("Invalid: ");
    while (1 < Wire.available()) { // loop through all but the last
      char c = Wire.read(); // receive byte as a character
      Serial.print(c, HEX);         // print the character
    }
    int x = Wire.read();    // receive byte as an integer
    Serial.println(x, HEX);         // print the integer
  }
}


void requestEvent() {
  if (reg == 0x01) {
    Wire.write(valueEncoder);
  } 

  if (reg == 0x03) {
    Wire.write(tokenBtnEncoder);
  }

  if (reg == 0x04) {
    int val = analogRead(POT_1);
    unsigned char valPot = map(val, 0, 1023, 0, 255);
    Wire.write(valPot);
  }

  if (reg == 0x05) {
    bool p = digitalRead(IR_LINE);
    Wire.write(p);
  }

  if (reg == 0x0A) {
    Wire.write(DHT.temperature);
  }

  if (reg == 0x0B) {
    Wire.write(DHT.humidity);
  }

  if (reg == 0x0C) {
    byte b1 =  encoderVal & 255;
    byte b2 = (encoderVal >> 8)  & 255;
    Wire.write(b1);
    Wire.write(b2);
  }
}