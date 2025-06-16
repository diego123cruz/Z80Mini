//
// Diego Cruz Junho/2025
// Interface I2C - Display 7 seguimentos com 4 digitos + Som
// 
// Atmega8L - 8pu (Osc.Int 8Mhz)
// LFuse = C4
// Hfuse = D1
// 
//
#include <Wire.h>
#include "pitches.h"

#define F_CPU 8000000L

char reg;
char cmd;
char cmd1;

char dispL = 0;
char dispH = 0;
char dispS = 0;
char leds = 0;
boolean runTest = false;

char sound = 0;
boolean canPlay = false;

char freq=0;
char temp=0;
boolean canTone = false;

char codes[] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7C, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71};

#define _dig1 4
#define _dig2 5
#define _dig3 6
#define _dig4 7
#define _digLeds 17

#define _delay 1

void limpaDigitos();
void autoTest();
void playSound(char s);
void setVidas(char v);

void setup() {
  Wire.begin(7);                // Z80Mini address is 0x0E
  Wire.onReceive(receiveEvent);

  DDRB = 0xFF;  // Todos os bits de DDRB em 1 => todos os pinos de PORTB como saída
  PORTB = 0x00; // Desliga pinos

  // Seta digitos como saida.
  pinMode(_dig1, OUTPUT);
  pinMode(_dig2, OUTPUT);
  pinMode(_dig3, OUTPUT);
  pinMode(_dig4, OUTPUT);
  pinMode(_digLeds, OUTPUT);

  // Som
  pinMode(3, OUTPUT);

  // Limpa digitos.
  limpaDigitos();
}

void loop() {
  if (canPlay) {
    canPlay = false;
    playSound(sound);
  }

  if (canTone) {
    canTone = false;
    myTone(3, freq*10, temp*10);
  }

  if (runTest) {
    autoTest();
    autoTest();
    runTest = false;
  }

  // Leds
  PORTB = leds;
  digitalWrite(_dig1, LOW);
  digitalWrite(_dig2, LOW);
  digitalWrite(_dig3, LOW);
  digitalWrite(_dig4, LOW);
  digitalWrite(_digLeds, HIGH);
  delay(_delay);
  limpaDigitos();

  
  if (dispS == 0) {
    limpaDigitos();
    return;
  }

  char tmp = 0;
  if (bitRead(dispS, 0)) {
    // Display 4
    tmp = dispL & 0x0F;
    PORTB = codes[tmp];
    digitalWrite(_dig1, HIGH);
    digitalWrite(_dig2, LOW);
    digitalWrite(_dig3, LOW);
    digitalWrite(_dig4, LOW);
    digitalWrite(_digLeds, LOW);
    delay(_delay);
    limpaDigitos();

    // Display 3
    tmp = dispL >> 4;
    tmp = tmp & 0x0F;
    PORTB = codes[tmp];
    digitalWrite(_dig1, LOW);
    digitalWrite(_dig2, HIGH);
    digitalWrite(_dig3, LOW);
    digitalWrite(_dig4, LOW);
    digitalWrite(_digLeds, LOW);
    delay(_delay);
    limpaDigitos();
  }

  if (bitRead(dispS, 1)) {
    // Display 2
    tmp = dispH & 0x0F;
    PORTB = codes[tmp];
    digitalWrite(_dig1, LOW);
    digitalWrite(_dig2, LOW);
    digitalWrite(_dig3, HIGH);
    digitalWrite(_dig4, LOW);
    digitalWrite(_digLeds, LOW);
    delay(_delay);
    limpaDigitos();

    // Display 1
    tmp = dispH >> 4;
    tmp = tmp & 0x0F;
    PORTB = codes[tmp];
    digitalWrite(_dig1, LOW);
    digitalWrite(_dig2, LOW);
    digitalWrite(_dig3, LOW);
    digitalWrite(_dig4, HIGH);
    digitalWrite(_digLeds, LOW);
    delay(_delay);
    limpaDigitos();
  }

  // Pontos XX:XX
  if (bitRead(dispS, 2)) {
    PORTB = 0b10000000;
    digitalWrite(_dig1, LOW);
    digitalWrite(_dig2, LOW);
    digitalWrite(_dig3, HIGH);
    digitalWrite(_dig4, LOW);
    digitalWrite(_digLeds, LOW);
    delay(_delay);
    limpaDigitos();
  }

}

void autoTest() {
  digitalWrite(_dig1, HIGH);
  digitalWrite(_dig2, HIGH);
  digitalWrite(_dig3, HIGH);
  digitalWrite(_dig4, HIGH);

  for(int i=0; i<16; i++) {
    PORTB = codes[i];
    delay(100);
  }
  // Teste leds
  limpaDigitos();
  digitalWrite(_digLeds, HIGH);
  PORTB = 0b00101111;
  delay(100);
  digitalWrite(_digLeds, LOW);
  PORTB = 0;
  delay(100);
  digitalWrite(_digLeds, HIGH);
  PORTB = 0b00101111;
  delay(100);
  digitalWrite(_digLeds, LOW);
  PORTB = 0;
  delay(100);
  limpaDigitos();
}

void limpaDigitos() {
  digitalWrite(_dig1, LOW);
  digitalWrite(_dig2, LOW);
  digitalWrite(_dig3, LOW);
  digitalWrite(_dig4, LOW);
  digitalWrite(_digLeds, LOW);
}

void setVidas(char v) {
  switch (v) {
    case 0:
      leds = 0b00000000;
      break;
    case 1:
      leds = 0b00000010;
      break;
    case 2:
      leds = 0b00001010;
      break;
    case 3:
      leds = 0b00001110;
      break;
    case 4:
      leds = 0b00101110;
      break;
    case 5:
      leds = 0b00101111;
      break;
    default:
      leds = 0b00101111;
      break;
  }
}


void receiveEvent(int howMany) {
  if(howMany == 1) {
    reg = Wire.read();
    cmd = 0xff;

    // AutoTest
    if(reg == 0x0f) {
      runTest = true;
    }
  } else if(howMany == 2) {
    reg = Wire.read();
    cmd = Wire.read();

    // Write dispS - Status 0-OFF, >1 ON
    // 0b0000 0001 - Display LOW
    // 0b0000 0010 - Display HIGH
    // 0b0000 0011 - Both display
    if(reg == 0x00) {
      dispS = cmd;
    }

    // Write Display LOW (3 e 4)
    if(reg == 0x01) {
      dispL = cmd;
    }

    // Write Display HIGH (1 e 2)
    if(reg == 0x02) {
      dispH = cmd;
    }

    // Write Led - Set vidas (0 - 5)
    if(reg == 0x03) {
      setVidas(cmd);
    }

    // Write leds
    if(reg == 0x04) {
      leds = cmd;
    }

    // Sounds
    if(reg == 0x05) {
      sound = cmd;
      canPlay = true;
    }
  } else if(howMany == 3) {
    reg = Wire.read();
    cmd = Wire.read();
    cmd1 = Wire.read();

    // Wrte in display HIGH and LOW
    // 0x06+dispH+dispL
    // Ex: Display(1234) = 0x06+0x12+0x34
    if (reg == 0x06) {
      dispH = cmd;
      dispL = cmd1;
    }

    // Generate tone x10
    // 0x07+freq+temp
    // Ex: tone(330, 200) = 0x07+33+20
    if (reg == 0x07) {
      freq = cmd;
      temp = cmd1;
      canTone = true;
    }
  }
}


//// SOMS
void fireSound() {
  for(int i=0; i<200; i++) {
    digitalWrite(3, HIGH);
    delayMicroseconds(i);
    digitalWrite(3, LOW);
    delayMicroseconds(i);
  }
}

void fireInvSound() {
  for(int i=150; i>1; i--) {
    digitalWrite(3, HIGH);
    delayMicroseconds(i);
    digitalWrite(3, LOW);
    delayMicroseconds(i);
  }
}

void click1Sound() {
  myTone(3, 800, 20);
  myTone(3, 1000, 20);
}

void coinSound() {
  myTone(3,NOTE_B5,100);
  myTone(3,NOTE_E6,650);
}

void play1upSound() {
  myTone(3,NOTE_E6,125);
  myTone(3,NOTE_G6,125);
  myTone(3,NOTE_E7,125);
  myTone(3,NOTE_C7,125);
  myTone(3,NOTE_D7,125);
  myTone(3,NOTE_G7,125);
}

void fireballSound() {
  myTone(3,NOTE_G4,35);
  myTone(3,NOTE_G5,35);
  myTone(3,NOTE_G6,35);
}

void levelCompleteSound() {
  int melody[] = { 880, 988, 1047, 1175, 1319 };
  for (int i = 0; i < 5; i++) {
    myTone(3, melody[i], 80);
  }
}

void fallSound() {
  for (int i = 600; i > 100; i -= 100) {
    myTone(3, i, 50);
  }
}

void jumpSound() {
  myTone(3, 600, 80);
  myTone(3, 900, 50);
}

void enemySpawnSound() {
  myTone(3, 300, 150);
  myTone(3, 200, 200);
}

void laserSound() {
  for (int i = 1500; i > 700; i -= 200) {
    myTone(3, i, 20);
  }
}

void secretUnlockedSound() {
  int notes[] = { 880, 660, 990, 1320 };
  for (int i = 0; i < 4; i++) {
    myTone(3, notes[i], 100);
  }
}

void dangerApproachingSound() {
  for (int i = 0; i < 3; i++) {
    myTone(3, 200, 100);
    myTone(3, 180, 100);
  }
}

void missileSound() {
  for (int i = 300; i <= 1200; i += 100) {
    myTone(3, i, 50);
  }
  delay(100);
  myTone(3, 100, 300);  // impacto final grave
}

void bombSound() {
  for (int i = 1000; i > 100; i -= 100) {
    myTone(3, i, 40);
  }
  delay(100);
  myTone(3, 60, 200); // Som grave no final
}

void winSound() {
  int melody[] = { 523, 659, 783, 1047 };
  int durations[] = { 150, 150, 150, 300 };

  for (int i = 0; i < 4; i++) {
    myTone(3, melody[i], durations[i]);
  }
}

void gameOverSound() {
  int melody[] = { 300, 250, 200, 150, 100 };
  for (int i = 0; i < 5; i++) {
    myTone(3, melody[i], 200);
  }
}

void powerUpSound() {
  myTone(3, 700, 100);
  myTone(3, 900, 100);
  myTone(3, 1100, 200);
}

void hitSound() {
  myTone(3, 1000, 50);
  myTone(3, 600, 30);
}

void dashSound() {
  myTone(3, 1500, 20);
  myTone(3, 1800, 20);
  myTone(3, 2100, 30);
}

void bumpSound() {
  myTone(3, 400, 30);
  myTone(3, 300, 20);
}

void countdownSound() {
  for (int i = 5; i > 0; i--) {
    myTone(3, 100 * i + 300, 100);
  }
}

void teleportSound() {
  myTone(3, 400, 80);
  myTone(3, 600, 80);
  myTone(3, 800, 80);
  myTone(3, 1200, 200);
}

void resetSound() {
  myTone(3, 300, 100);
  myTone(3, 600, 100);
  myTone(3, 900, 100);
}

void playSound(char s) {
  PORTB = 0;
  pinMode(3, OUTPUT);
  switch (s) {
    case 0x00:
      fireSound();
      break;
    case 0x01:
      fireInvSound();
      break;
    case 0x02:
      click1Sound();
      break;
    case 0x03:
      coinSound();
      break;
    case 0x04:
      play1upSound();
      break;
    case 0x05:
      fireballSound();
      break;
    case 0x06:
      levelCompleteSound();
      break;
    case 0x07:
      fallSound();
      break;
    case 0x08:
      jumpSound();
      break;
    case 0x09:
      enemySpawnSound();
      break;
    case 0x0A:
      laserSound();
      break;
    case 0x0B:
      secretUnlockedSound();
      break;
    case 0x0C:
      dangerApproachingSound();
      break;
    case 0x0D:
      missileSound();
      break;
    case 0x0E:
      bombSound();
      break;
    case 0x0F:
      winSound();
      break;
    case 0x10:
      gameOverSound();
      break;
    case 0x11:
      powerUpSound();
      break;
    case 0x12:
      hitSound();
      break;
    case 0x13:
      dashSound();
      break;
    case 0x14:
      bumpSound();
      break;
    case 0x15:
      countdownSound();
      break;
    case 0x16:
      teleportSound();
      break;
    case 0x17:
      resetSound();
      break;
  }
  pinMode(3, INPUT);
}

void myTone(byte pin, uint16_t frequency, uint16_t duration)
{
  unsigned long halfPeriod = 1000000L / frequency / 2;
  unsigned long cycles = (unsigned long)duration * 1000UL / (halfPeriod * 2);

  pinMode(pin, OUTPUT);
  for (unsigned long i = 0; i < cycles; i++)
  {
    digitalWrite(pin, HIGH);
    delayMicroseconds(halfPeriod);
    digitalWrite(pin, LOW);
    delayMicroseconds(halfPeriod);
  }
  pinMode(pin, INPUT);
}