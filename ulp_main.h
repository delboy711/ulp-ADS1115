#include "Arduino.h"
/* These are variables common between the ULP and main cores
 *  
 */
extern uint32_t ulp_entry;
extern uint32_t ulp_result;

// Raw data from the ADC
extern uint32_t ulp_VrawCh0;
extern uint32_t ulp_VrawCh1;
extern uint32_t ulp_VrawCh2;
extern uint32_t ulp_VrawCh3;
