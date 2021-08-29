/*
 * Demo of I2C ULP routines
 * This file contains the entry point of the ULP programme
 * be very careful to ensure the right pins are being manipulated by the 
 * WRITE_RTC_REG commands. It is very easy to get them wrong.
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.s"


/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

prev_temp:	.long 0
//prev_pressure: .long 0
//prev_pressure2: .long 0

	.global	counter
counter: .long 0

	.global stack
stack:
	.skip 100
	.global stackEnd
stackEnd:
	.long 0


	/* Code goes into .text section */
	.text
	.global entry
entry:
	move r3,stackEnd
/*
	// Read the ADS1115 every 4 timer cycles:
	move r1,counter
	ld r0,r1,0
	add r0,r0,1
	st r0,r1,0 // increment counter
	and r0,r0,0x3
	jumpr waitNext,1,ge
*/
	// GPIO2 LED ON
  WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + 12, 1, 1)  //Corresponds to GPIO_2
	psr
	jump readADS1115    //Read ADC channels

	// GPIO2 LED OFF
  WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + 12, 1, 0)  //Corresponds to GPIO_2

	jump wakeUp

  .global wakeUp
wakeUp:
	/* Wake up the SoC, end program */
	wake
	/* Stop the wakeup timer so it does not restart ULP */
	//WRITE_RTC_FIELD(RTC_CNTL_STATE0_REG, RTC_CNTL_ULP_CP_SLP_TIMER_EN, 0)

waitNext:
	halt
