
/*!
 * @file DFRobot_DHT11.h
 * @brief DHT11 is used to read the temperature and humidity of the current environment. 
 *
 * @copyright   Copyright (c) 2010 DFRobot Co.Ltd (http://www.dfrobot.com)
 * @license     The MIT License (MIT)
 * @author [Wuxiao](xiao.wu@dfrobot.com)
 * @version  V1.0
 * @date  2018-09-14
 * @url https://github.com/DFRobot/DFRobot_DHT11
 */
#ifndef DFROBOT_DHT11_h
#define DFROBOT_DHT11_h

#if defined(ARDUINO) && (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

class DFRobot_DHT11{
public:
  /**
   * @fn read
   * @brief Read DHT11 data
   * @param pin: Connect the IO port of the DHT11 data port.
   * @return NONE    
   */
  void read(int pin);
  int humidity;
  int temperature;
};
#endif
