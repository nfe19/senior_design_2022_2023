/*
 *   HW ASSIGNMENT: GPGM0
 *   EEL-4746 Fall 2021
 *   Najeeb Eeso
 *   Date written: 9/19/21
 *   First EEL-4746 C Program
 */

// Standard Includes

#include "driverlib.h"
#include <stdint.h>
#include <stdio.h>
#include <eusci_b_i2c.h>
// files for BCUART functions
#include <stdbool.h>
#include "HAL_UART_4746.h"
#include <HAL_FR5994_OPT3001.h>

void GPIO_init(void);
void initI2C(void);
//  Main Function
void main(void){

    // Halt the WatchDog Timer
    WDT_A_hold(WDT_A_BASE);

    // Activate new port configurations and put all GPIO low (LOW POWER)
    GPIO_init();

    // Initialize I2C port
    initI2C();

    // Initialize OPT3001 light sensor
    OPT3001_init(0x44);

    volatile uint16_t mId = 0;
    volatile uint32_t lightData = 0;

    //obtain manufacturing information, obtain light info, blink LED
    while(1){
        mId = OPT3001_readManufacturerId(0x44);  //send the data, expect <start> <address> <ACK> <register address> <ACK> <data> <ACK> <end>
        lightData = OPT3001_getLux(0x44);
        __delay_cycles(100000);    //Toggle PIN to indicate data was sent
        GPIO_toggleOutputOnPin(GPIO_PORT_P1, GPIO_PIN0);                    //delay
    }

}

void initI2C( void )
{

    //Set 7.1 and 7.0 as I2C output peripherals
    GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_P7, GPIO_PIN0, GPIO_PRIMARY_MODULE_FUNCTION);
    GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_P7, GPIO_PIN1, GPIO_PRIMARY_MODULE_FUNCTION);


    EUSCI_B_I2C_initMasterParam i2cParameters =
    {
         EUSCI_B_I2C_CLOCKSOURCE_SMCLK,          // SMCLK Clock Source
         10000000,                               // SMCLK = 1.00MHzMHz
         EUSCI_B_I2C_SET_DATA_RATE_400KBPS,      // Desired I2C Clock of 400khz
    };

    //disable I2C, initialize with parameters set above, enable I2C
    EUSCI_B_I2C_disable(EUSCI_B2_BASE);
    EUSCI_B_I2C_initMaster(EUSCI_B2_BASE, &i2cParameters);    //initialize with parameters
    EUSCI_B_I2C_enable(EUSCI_B2_BASE);  //enable i2c

}

/* Initializes GPIO */
void GPIO_init(){
    /* Terminate all GPIO pins to Output LOW to minimize power consumption */
    GPIO_setAsOutputPin(GPIO_PORT_PA, GPIO_PIN_ALL16);
    GPIO_setAsOutputPin(GPIO_PORT_PB, GPIO_PIN_ALL16);
    GPIO_setAsOutputPin(GPIO_PORT_PC, GPIO_PIN_ALL16);
    GPIO_setAsOutputPin(GPIO_PORT_PD, GPIO_PIN_ALL16);
    GPIO_setAsOutputPin(GPIO_PORT_PE, GPIO_PIN_ALL16);
    GPIO_setAsOutputPin(GPIO_PORT_PF, GPIO_PIN_ALL16);
    GPIO_setOutputLowOnPin(GPIO_PORT_PA, GPIO_PIN_ALL16);
    GPIO_setOutputLowOnPin(GPIO_PORT_PB, GPIO_PIN_ALL16);
    GPIO_setOutputLowOnPin(GPIO_PORT_PC, GPIO_PIN_ALL16);
    GPIO_setOutputLowOnPin(GPIO_PORT_PD, GPIO_PIN_ALL16);
    GPIO_setOutputLowOnPin(GPIO_PORT_PE, GPIO_PIN_ALL16);
    GPIO_setOutputLowOnPin(GPIO_PORT_PF, GPIO_PIN_ALL16);

    // Disable the GPIO power-on default high-impedance mode
    // to activate previously configured port settings
    PMM_unlockLPM5();
}
