/* ULP I2C bit bang ADS1115 Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/
/********************************************************
 * This sketch is an example of using the ESP ULP (Ultra Low Power) Co Processor to read data
 * from an ADS1115 4 channel ADC chip using I2C 'bitbanging'
 * Although the ULP processor has instructions to read directly from I2C using hardware, it only
 * supports 8 bit I2C data. ADS1115 like many other chips uses 16 bit data and so must be bitbanged.
 * 
 * This sketch borrows heavily from work by tomtor https://github.com/tomtor/ulp-i2c  I have
 * 'Arduinofied' his work and adapted it to control ADS1115
 * To adapt to other chips it is necessary to read the specs carefully
 */
#include <Arduino.h>
#include <esp_sleep.h>
#include <driver/rtc_io.h>
#include <esp32/ulp.h>
#include <ulptool.h>
#include "ulp_main.h"

#define ADS1115_REG_FACTOR 32768

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

/************************************
 * Refer to https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html
 * to see how GPIO and RTC_GPIO pins relate to each other
 */
 //These pins must also be defined in the I2c.s file
const gpio_num_t gpio_led = GPIO_NUM_2;  //This corresponds to RTC_GPIO12
const gpio_num_t gpio_scl = GPIO_NUM_15;  //This corresponds to RTC_GPIO13
const gpio_num_t gpio_sda = GPIO_NUM_13;  //This corresponds to RTC_GPIO14

uint16_t voltageRange = 4096;  //Range setting of ADS1115. Set in ULP programme in ADS1115_STARTCONVERT_CH0x

static void init_ulp_program()
{
    rtc_gpio_init(gpio_led);
    rtc_gpio_set_direction(gpio_led, RTC_GPIO_MODE_OUTPUT_ONLY);

    rtc_gpio_init(gpio_scl);
    rtc_gpio_set_direction(gpio_scl, RTC_GPIO_MODE_INPUT_ONLY);
    rtc_gpio_init(gpio_sda);
    rtc_gpio_set_direction(gpio_sda, RTC_GPIO_MODE_INPUT_ONLY);

    esp_err_t err = ulptool_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    /* Set ULP wake up period to T = 1000ms
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    //REG_SET_FIELD(SENS_ULP_CP_SLEEP_CYC0_REG, SENS_SLEEP_CYCLES_S0, 150000);
    ulp_set_wakeup_period(0, 1000 * 1000);
}



static void start_ulp_program()
{
  /* Start the program */
  esp_err_t err = ulp_run((&ulp_entry - RTC_SLOW_MEM) / sizeof(uint32_t));
  ESP_ERROR_CHECK(err);
}


void setup() {
  Serial.begin(115200);
  delay(100);

  init_ulp_program();
}

void loop() {
/* Now start the ULP program.
 *  It will read the ADC chip over I2C, wake this programme, and then terminate itself
 */
  Serial.println("Starting ULP");
  start_ulp_program();

/* Raw data from the ULP is passed to the main programme through variables
 *  prefixed ulp_ and declared in the file ulp_main.h
 *  ULP variables are always 32bits but the upper 16 bits contain random data(!) so it is
 *  necessary to cast the data as a 16 bit number.
 *  ADS1115 provides its data as a signed 16 bit word scaled to the voltage range selected
 *  To convert to Volts see below
 */
    
    //Convert from raw data to Volts
    float VCh0 = ((int16_t)ulp_VrawCh0 * 1.0 / ADS1115_REG_FACTOR) * voltageRange/1000.0;
    Serial.print("Chan 0 - Volts: "); Serial.println( VCh0);
    float VCh1 = ((int16_t)ulp_VrawCh1 * 1.0 / ADS1115_REG_FACTOR) * voltageRange/1000.0;
    Serial.print("Chan 1 - Volts: "); Serial.println( VCh1);
    float VCh2 = ((int16_t)ulp_VrawCh2 * 1.0 / ADS1115_REG_FACTOR) * voltageRange/1000.0;
    Serial.print("Chan 2 - Volts: "); Serial.println( VCh2);
    float VCh3 = ((int16_t)ulp_VrawCh3 * 1.0 / ADS1115_REG_FACTOR) * voltageRange/1000.0;
    Serial.print("Chan 3 - Volts: "); Serial.println( VCh3);
    delay(200);


/* Now go to light sleep waiting to be woken by the ULP 
  In light sleep cpu clocks will stop, but will resume upon waking
*/
  ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );
  esp_light_sleep_start();  //Snooze



/* And we are back! */
  esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
  if (cause != ESP_SLEEP_WAKEUP_ULP) {
    Serial.println("Not ULP wakeup");
  } else {
    Serial.println("Light sleep wakeup");      
  }
  delay(200);
}
