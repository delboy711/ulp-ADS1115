/*
 * This file uses the lower level I2C routines
 * to fetch data from an ADS1115 4 channel ADC chip and
 * pass them to the main processor
 */


#include "stack.s"

#define ADS1115_ADDR 0x48   //I2C address


/* registers */
#define ADS1115_CONV_REG 0x00 // Conversion Register
#define ADS1115_CONFIG_REG 0x01 // Configuration Register
#define ADS1115_LO_THRESH_REG 0x02 // Low Threshold Register
#define ADS1115_HI_THRESH_REG 0x03 // High Threshold Register
/*
 *  ADS1115_RANGE_6144  = 0x0000,
    ADS1115_RANGE_4096  = 0x0200,
    ADS1115_RANGE_2048  = 0x0400,
    ADS1115_RANGE_1024  = 0x0600,
    ADS1115_RANGE_0512  = 0x0800,
    ADS1115_RANGE_0256  = 0x0A00
    
    ADS1115_CONTINUOUS = 0x0000, 
    ADS1115_SINGLE     = 0x0100

    ADS1115_8_SPS   = 0x0000,
    ADS1115_16_SPS  = 0x0020,
    ADS1115_32_SPS  = 0x0040,
    ADS1115_64_SPS  = 0x0060,
    ADS1115_128_SPS = 0x0080,
    ADS1115_250_SPS = 0x00A0,
    ADS1115_475_SPS = 0x00C0,
    ADS1115_860_SPS = 0x00E0
    
    ADS1115_COMP_0_1   = 0x0000,
    ADS1115_COMP_0_3   = 0x1000,
    ADS1115_COMP_1_3   = 0x2000,
    ADS1115_COMP_2_3   = 0x3000,
    ADS1115_COMP_0_GND = 0x4000,
    ADS1115_COMP_1_GND = 0x5000,
    ADS1115_COMP_2_GND = 0x6000,
    ADS1115_COMP_3_GND = 0x7000
    
    ADS1115_BUSY          = 0x0000,
    ADS1115_START_ISREADY = 0x8000
 */

//Commands
#define ADS1115_STARTCONVERT_CH0 0xc383    //CH0 Single 128SPS Range 4096
#define ADS1115_STARTCONVERT_CH1 0xd383    //CH1 Single 128SPS Range 4096
#define ADS1115_STARTCONVERT_CH2 0xe383    //CH2 Single 128SPS Range 4096
#define ADS1115_STARTCONVERT_CH3 0xf383    //CH3 Single 128SPS Range 4096


/* other */
#define ADS1115_REG_FACTOR 32768 
/*Because ADS1115 output is Twos complement. This is the range of positive values possible
 * when measuring referenced to GND.  Used when converting to mV
 */

#define ADS1115_REG_RESET_VAL 0x8583
#define SAMPLE_DELAY 8    //8mS sample time


/* Define variables, which go into .bss section (zero-initialized data)
*/
	.bss
  .global VrawCh0, VrawCh1, VrawCh2, VrawCh3, mVCh0, mVCh1, mVCh2, mVCh3 
VrawCh0: .long 0
VrawCh1: .long 0
VrawCh2: .long 0
VrawCh3: .long 0
mVCh0: .long 0
mVCh1: .long 0
mVCh2: .long 0
mVCh3: .long 0

  .global result
result: .long 0  



	/* Code goes into .text section */
	.text

sendCommand:      //Send a command to ADS1115 Command is in r2
  move r1,ADS1115_ADDR
  push r1
  move r1,ADS1115_CONFIG_REG
  push r1 //push the register number
  push r2 //push the command
  psr
  jump write16
  add r3,r3,3 // remove 3 arguments from stack
  move r0,r2 // test for error in r2
  jumpr fail,1,ge
  ret

readConvReg:    //Read the conversion register
  // Read 16 bit result
  push r0   //Save address of channel variable
  move r1,ADS1115_ADDR
  push r1
  move r1,ADS1115_CONV_REG
  push r1
  psr
  jump read16
  add r3,r3,2 // remove call parameters from stack
  move r1,r0 // save result
  move r0,r2 // test for error
  jumpr fail,1,ge
  pop r2      //Recover variable address
  st r1,r2,0  // store result for Channel
  move r2, r1 //Keep adc raw data in r2
  ret


.global readADS1115
readADS1115:          //Fetch ADC Data from all 4 channels

  //*************Channel 0**********

  move r2, ADS1115_STARTCONVERT_CH0
  psr
  jump sendCommand  //Start Conversion on Chan 0

	// Wait 8ms for sensor computation Adjust for Samples per sec
	move r2, SAMPLE_DELAY
	psr
	jump waitMs

  move r0, VrawCh0    //Pass the address of the channel data to the subroutine
  psr
  jump readConvReg    //Read Chan 0 data
  
   //*************Channel 1********** 

  move r2, ADS1115_STARTCONVERT_CH1
  psr
  jump sendCommand  //Start Conversion on Chan 1
  
  // Wait 8ms for sensor computation Adjust for Samples per sec
  move r2, SAMPLE_DELAY
  psr
  jump waitMs 
  
  move r0, VrawCh1    //Pass the address of the channel data to the subroutine
  psr
  jump readConvReg    //Read Chan 1 data

  //*************Channel 2**********

  move r2, ADS1115_STARTCONVERT_CH2
  psr
  jump sendCommand  //Start Conversion on Chan 1
  
  // Wait 8ms for sensor computation Adjust for Samples per sec
  move r2, SAMPLE_DELAY
  psr
  jump waitMs 
  
  move r0, VrawCh2    //Pass the address of the channel data to the subroutine
  psr
  jump readConvReg    //Read Chan 2 data
  
  //*************Channel 3**********

  move r2, ADS1115_STARTCONVERT_CH3
  psr
  jump sendCommand  //Start Conversion on Chan 3
  
  // Wait 8ms for sensor computation Adjust for Samples per sec
  move r2,SAMPLE_DELAY
  psr
  jump waitMs 
  
  move r0, VrawCh3    //Pass the address of the channel data to the subroutine
  psr
  jump readConvReg    //Read Chan 3 data
  
//***************************************

  .global fail  
fail:
	move r1,result
	move r0,0 // 0 signals error
	st r0,r1,0
	ret


// Wait for r2 milliseconds
  .global waitMs
waitMs:
	wait 8000
	sub r2,r2,1
	jump doneWaitMs,eq
	jump waitMs
doneWaitMs:
	ret
