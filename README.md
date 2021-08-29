# ulp-ADS1115
Example sketch for ESP32 ULP co-processor to read ADS1115 over I2C

This sketch for ESP32 demonstrates how the ULP (ultra low power) co-processor of the ESP32 can be used to read ADC data from an ADS1115 over I2C while the ESP32 core is sleeping. It is based heavily on work by  tomtor https://github.com/tomtor/ulp-i2c  adapted for ADS1115 and for Arduino IDE.

This sketch uses 'bitbanging' to control the I2C interface. This is necessary because although the ULP instruction set includes commands to read and write to I2C, it can only read/write 8 bits.  ADS1115 uses 16 bit registers and so we must control the I2C interface the hard way.

In this example sketch the ESP32 will load and start the ULP programme and then enter 'light sleep' mode in which the core clocks are stopped.
The ULP programme will read each of the 4 ADC channels of an ADS1115 and save their data in memory shared with the ESP32 and then waken the ESP32 core and then halt. The ESP32 will then display the data and the cycle starts again.

Note: If no ADS1115 is present, or incorrectly configured, the ULP process will just hang and the ESP32 will not wake.


## Requirements
* <strong>ulptool</strong>  https://github.com/duff2013/ulptool  ulptool is the magic glue that integrates the ULP assembler into the Arduino IDE. It must be installed before the IDE can compile the sketch.  At the time of writing there were some bugs relating to Python 3 in this repository, so I used the fork at https://github.com/angyongen/ulptool  which resolved them.  Test ulptool with the examples provided with it, but do not expect to be able to comple the i2c-bitbang example.

## Resources
* Learn about ULP and ulptool from the guy with the Swiss accent https://youtu.be/-QIcUTBB7Ww
* Documentation at Espressif https://docs.espressif.com/projects/esp-idf/en/v4.1.2/api-guides/ulp.html#
* If you have an I2C device which uses 8 bit registers then check out https://github.com/wardjm/esp32-ulp-i2c It is an awful lot easier than bitbanging.

## Troubleshooting
* Most problems running the code arise from the ULP processor hanging because of a misconfiguration of the I2C address or SDA and SCL assignments. The biggest problem is that the ESP Core and ULP processors use different GPIO numbering for the same pins. Refer to the table at https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html There are configuration parameters in both the Core and ULP programmes that need to be set.
