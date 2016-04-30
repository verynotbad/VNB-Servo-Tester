/**********************************************
 * Servo Tester
 * Copyright (c) 2016 Very Not Bad Prototypes
 * All Rights Reserved
 * 
 * http://www.verynotbad.tech
 * 
 * This code is a Servo Tester using an
 * Arduino Microcontroller and an Adafruit
 * LCD Shield.
 * 
 * Tests the following for hobby servos: 
 *    - PWM Min/Max
 *    - Feedback Values
 *    - Angles
 *    
 * Revision 01 - Initial Version
************************************************/

#include <Wire.h>
#include <Servo.h>
#include <Adafruit_MCP23017.h>
#include <Adafruit_RGBLCDShield.h>



// These #defines make it easy to set the backlight color
#define RED 0x1
#define YELLOW 0x3
#define GREEN 0x2
#define TEAL 0x6
#define BLUE 0x4
#define VIOLET 0x5
#define WHITE 0x7

#define MODE_ANGLE        0
#define MODE_PWM_MIN      1 
#define MODE_PWM_MAX      2
#define MODE_FEEDBACK     3
#define MODE_PULLUP       4

#define COLOR_INTRO       GREEN
#define COLOR_ATTACHED    RED
#define COLOR_DETACHED    WHITE
#define COLOR_ERROR       YELLOW

#define INTRO_LINE1       "VNB Servo Tester"
#define INTRO_LINE2       "v1.0"
#define INTRO_DURATION    2500

#define TITLE_ANGLE       "Angle (0-180):"
#define TITLE_PWM_MIN     "Min PWM (uSec):"
#define TITLE_PWM_MAX     "Max PWM (uSec):"
#define TITLE_FEEDBACK    "Servo Feedback:"
#define TITLE_PULLUP      "Pullup Resistor:"
#define LINE2_ENABLED     "Enabled"
#define LINE2_DISABLED    "Disabled"
#define EMPTY_LINE        "                " // 16 spaces



#define FEEDBACK_VALUE_THRESHOLD  1
#define FEEDBACK_TIME_THRESHOLD   1000
#define FEEDBACK_DISCON_THRESHOLD 1010
#define MAX_FEEDBACK              1023


#define ANGLE_INCREMENT           5
#define PWM_INCREMENT             50

#define PWM_MIN                   PWM_INCREMENT
#define PWM_MAX                   5000

#define ANGLE_MIN                 0
#define ANGLE_MAX                 180

#define ERROR_DURATION            1000

#define SERVO_PIN_DATA            5
#define SERVO_PIN_FEEDBACK        A0



// The shield uses the I2C SCL and SDA pins. On classic Arduinos
// this is Analog 4 and 5 so you can't use those for analogRead() anymore
// However, you can connect other I2C sensors to the I2C bus and share
// the I2C bus.
Adafruit_RGBLCDShield lcd = Adafruit_RGBLCDShield();

// Declare a Servo, but don't attach it until the user chooses to
Servo servo;
int   pwmMin            = 1000;
int   pwmMax            = 2000;
int   angle             = (ANGLE_MIN + ANGLE_MAX)/2;
int   feedback          = -1000;
int   lastFeedbackTime  = 0;
bool  pullupEnabled     = true;

// Set the initial mode
uint8_t mode = MODE_ANGLE;

/* -------------------------------------------
 *  Setup
 *     - Initialize LCD
 *     - Initialize Servo Pins
 * ------------------------------------------- */
void setup() 
{

  // Setup the LCD's number of columns and rows: 
  lcd.begin(16, 2);

  // Print Intro Message to LCD
  lcd.print(INTRO_LINE1);
  lcd.setCursor(0,1);
  lcd.print(INTRO_LINE2);
  lcd.setBacklight(COLOR_INTRO);

  // Hold Intro Message for a short duration
  delay(INTRO_DURATION);

  // Setup Pin Modes
  pinMode(SERVO_PIN_DATA, OUTPUT);
  pinMode(SERVO_PIN_FEEDBACK, INPUT);
  if (pullupEnabled)
    digitalWrite(SERVO_PIN_FEEDBACK, HIGH); // Enabled internal pullup resistor

  // Setup ANGLE Mode
  lcd.setBacklight(COLOR_DETACHED);
  changeToModeAngle(); 

  
}



/* ----------------------------------------------------
 *  Loop
 *     - Read Button State
 *     - If Select pressed, toggle attach/detach
 *     - If left/right pressed, change mode
 *     - Execute Mode-specific behavior
 * --------------------------------------------------- */
void loop() 
{

  uint8_t buttons = lcd.readButtons();

  if (buttons & BUTTON_SELECT)
  {
    toggleAttachment();
 
    // Clear all button presses
    buttons = 0;    
  }

  
  if (buttons & (BUTTON_LEFT | BUTTON_RIGHT))
  {
    changeMode(buttons);   

    // Clear all button presses
    buttons = 0;

    delay(300);
  }

  

  if (mode == MODE_ANGLE)
  {
    runModeAngle(buttons);
  }

  else if (mode == MODE_FEEDBACK)
  {
    runModeFeedback();
  }
  
  else if (mode == MODE_PWM_MIN)
  {
    runModePwmMin(buttons);
  }
  
  else if (mode == MODE_PWM_MAX)
  {
    runModePwmMax(buttons);
  }

  else if (mode == MODE_PULLUP)
  {
    runModePullup(buttons);
  }

}


void toggleAttachment()
{
   if (servo.attached())
    {
      servo.detach();
      lcd.setBacklight(COLOR_DETACHED);
    }
    else 
    {
      servo.attach(SERVO_PIN_DATA, pwmMin, pwmMax);
      servo.write(angle);
      lcd.setBacklight(COLOR_ATTACHED);
    }

    delay(500);
}



void flashErrorBacklight()
{
   lcd.setBacklight(COLOR_ERROR);
   delay(ERROR_DURATION);
  
   if (servo.attached())
    {
      lcd.setBacklight(COLOR_ATTACHED);
    }
    else 
    {
      lcd.setBacklight(COLOR_DETACHED);
    }
  
}


/*
 * Change Mode (upon left/right button press):
 * Mode change logic is as follows:
 *        - If Mode == ANGLE:
 *           - LEFT: Do nothing
 *           - RIGHT: Change to FEEDBACK
 *        - If Mode == FEEDBACK
 *           - LEFT: Change to ANGLE
 *           - RIGHT: Change to PWM_MIN
 *        - If Mode == PWM_MIN:
 *           - LEFT: Change to Feedback
 *           - RIGHT: Change to PWM_MAX
 *        - If Mode == PWM_MAX:
 *           - LEFT: Change to PWM_MIN
 *           - RIGHT: Change to PULLUP
 *        - If Mode == PULLUP
 *           - LEFT: Change to PWM_MAX
 *           - RIGHT: Do Nothing
 */
void changeMode(uint8_t buttons)
{
  
  // --
  // -- Current Mode: ANGLE
  // --
  if (mode == MODE_ANGLE)
  {
  
    if (buttons & BUTTON_LEFT) 
    {
      // -- Do Nothing    
    }
    
    // -- Change to: Feedback
    if (buttons & BUTTON_RIGHT) 
    {
      changeToModeFeedback();    
    }

  }

  // --
  // -- Current Mode: FEEDBACK
  // --
  else if (mode == MODE_FEEDBACK)
  {
    if (buttons & BUTTON_LEFT) 
    {
      changeToModeAngle();    
      feedback = -1000;     // Force a refresh if we come back to this mode
    }

    if (buttons & BUTTON_RIGHT) 
    {
      changeToModePwmMin();    
      feedback = -1000;    // Force a refresh if we come back to this mode
    }

  }

  // --
  // -- Current Mode: PWM_MIN
  // --
  else if (mode == MODE_PWM_MIN)
  {
    if (buttons & BUTTON_LEFT) 
    {
      changeToModeFeedback();    
    }

    if (buttons & BUTTON_RIGHT) 
    {
      changeToModePwmMax();    

    }


  }

  // --
  // -- Current Mode: PWM_MAX
  // --
  else if (mode == MODE_PWM_MAX)
  {
    if (buttons & BUTTON_LEFT) 
    {
      changeToModePwmMin();    
    }

    if (buttons & BUTTON_RIGHT) 
    {
      changeToModePullup();    

    }



  }

  
  // --
  // -- Current Mode: PULLUP
  // --
  else if (mode == MODE_PULLUP)
  {
    if (buttons & BUTTON_LEFT) 
    {
      changeToModePwmMax();    
    }

    if (buttons & BUTTON_RIGHT) 
    {
      // -- Do Nothing   

    }



  }


}

void changeToModeAngle()
{
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print(TITLE_ANGLE);
      mode = MODE_ANGLE;

      lcd.setCursor(0,1);
      lcd.print(EMPTY_LINE);
      lcd.setCursor(0,1);
      lcd.print(angle);

}

void changeToModeFeedback()
{
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print(TITLE_FEEDBACK);
      mode = MODE_FEEDBACK;

      lcd.setCursor(0,1);
      lcd.print(EMPTY_LINE);
}

void changeToModePwmMin()
{
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print(TITLE_PWM_MIN);
      mode = MODE_PWM_MIN;

      lcd.setCursor(0,1);
      lcd.print(EMPTY_LINE);
      lcd.setCursor(0,1);
      lcd.print(pwmMin);

}

void changeToModePwmMax()
{
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print(TITLE_PWM_MAX);
      mode = MODE_PWM_MAX;

      lcd.setCursor(0,1);
      lcd.print(EMPTY_LINE);
      lcd.setCursor(0,1);
      lcd.print(pwmMax);

}


void changeToModePullup()
{
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print(TITLE_PULLUP);
      mode = MODE_PULLUP;

    lcd.setCursor(0,1);
    lcd.print(EMPTY_LINE);
    lcd.setCursor(0,1);
    if (pullupEnabled)
    {
      lcd.print(LINE2_ENABLED);
    }
    else 
    {
      lcd.print(LINE2_DISABLED);
    }

}

// --------------------------------------------------------------

void runModeAngle(uint8_t buttons)
{

  int increment = 0;
  
  if (buttons & BUTTON_UP)
  {
    increment = ANGLE_INCREMENT;
  }

  else if (buttons & BUTTON_DOWN)
  {
    increment = ANGLE_INCREMENT * -1;
  }


  if (increment != 0)
  {
    angle += increment;

    if (angle < ANGLE_MIN)
    {
      angle = ANGLE_MIN;
      flashErrorBacklight();
    }

    if (angle > ANGLE_MAX)
    {
      angle = ANGLE_MAX;
      flashErrorBacklight();
    }

    lcd.setCursor(0,1);
    lcd.print(EMPTY_LINE);
    lcd.setCursor(0,1);
    lcd.print(angle);

    if (servo.attached())
    {
      servo.write(angle);
    }
  }

  delay(100);
}


void runModeFeedback()
{
  int time = millis();
  int deltaT = time - lastFeedbackTime;

  int sensorValue = analogRead(SERVO_PIN_FEEDBACK);
  int deltaV      = abs(sensorValue - feedback);

  float pctValue  = (float)sensorValue / 1024.0;
  //int   pctInt    = (int)(pctValue * 100);

  bool updateLCD = (deltaV > FEEDBACK_VALUE_THRESHOLD) || 
                   ((deltaT > FEEDBACK_TIME_THRESHOLD) && (deltaV != 0));

  if ((sensorValue > FEEDBACK_DISCON_THRESHOLD))
  {
    if (feedback != MAX_FEEDBACK)
    {
      lcd.setCursor(0,1);
      lcd.print(EMPTY_LINE);
    
      lcd.setCursor(0,1);
      lcd.print("Disconnected");
  
      feedback = MAX_FEEDBACK;
    }

    delay(100);
    updateLCD = false;
  }

  
  
  if (updateLCD)
  {
    lcd.setCursor(0,1);
    lcd.print(EMPTY_LINE);
  
    lcd.setCursor(0,1);
    lcd.print(sensorValue);

    
    lcd.setCursor(12,1);
    lcd.print(pctValue);

    feedback = sensorValue;
    lastFeedbackTime = time;

    delay(100);
  }

}

void runModePwmMin(uint8_t buttons)
{

  int increment = 0;

  if (!servo.attached())
  {
    if (buttons & BUTTON_UP)
    {
      increment = PWM_INCREMENT;
    }
    
    else if (buttons & BUTTON_DOWN)
    {
      increment = PWM_INCREMENT * -1;
    }
  }

  else if (buttons & (BUTTON_UP | BUTTON_DOWN))
  {
    lcd.setCursor(7,1);
    lcd.print("LOCKED");
    delay(ERROR_DURATION);
    lcd.setCursor(7,1);
    lcd.print("      ");
    
  }



  if (increment != 0)
  {
    pwmMin += increment;

    if (pwmMin < PWM_MIN)
    {
      pwmMin = PWM_MIN;
      flashErrorBacklight();
    }

    if (pwmMin >= pwmMax)
    {
      pwmMin = pwmMax - PWM_INCREMENT;
      flashErrorBacklight();
    }

    lcd.setCursor(0,1);
    lcd.print(EMPTY_LINE);
    lcd.setCursor(0,1);
    lcd.print(pwmMin);

  }

  delay(100);
}

void runModePwmMax(uint8_t buttons)
{

  int increment = 0;

  if (!servo.attached())
  {
    if (buttons & BUTTON_UP)
    {
      increment = PWM_INCREMENT;
    }
    
    else if (buttons & BUTTON_DOWN)
    {
      increment = PWM_INCREMENT * -1;
    }
  }

  else if (buttons & (BUTTON_UP | BUTTON_DOWN))
  {
    lcd.setCursor(7,1);
    lcd.print("LOCKED");
    delay(ERROR_DURATION);
    lcd.setCursor(7,1);
    lcd.print("      ");
  }


  if (increment != 0)
  {
    pwmMax += increment;

    if (pwmMax <= pwmMin)
    {
      pwmMax = pwmMin + PWM_INCREMENT;
      flashErrorBacklight();
    }

    if (pwmMax > PWM_MAX)
    {
      pwmMax = PWM_MAX;
      flashErrorBacklight();
    }

    lcd.setCursor(0,1);
    lcd.print(EMPTY_LINE);
    lcd.setCursor(0,1);
    lcd.print(pwmMax);

  }

  delay(100);
}

void runModePullup(uint8_t buttons)
{


  if (buttons & (BUTTON_UP | BUTTON_DOWN))
  {
    pullupEnabled = !pullupEnabled;

    if (pullupEnabled)
    {
      digitalWrite(SERVO_PIN_FEEDBACK, HIGH);
    }
    else 
    {
      digitalWrite(SERVO_PIN_FEEDBACK, LOW);
    }


    lcd.setCursor(0,1);
    lcd.print(EMPTY_LINE);
    lcd.setCursor(0,1);
    if (pullupEnabled)
    {
      lcd.print(LINE2_ENABLED);
    }
    else 
    {
      lcd.print(LINE2_DISABLED);
    }

    
  }


 
  

  delay(100);
}





