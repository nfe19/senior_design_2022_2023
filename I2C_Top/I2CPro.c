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
void I2C_write_16(uint8_t, uint8_t, uint16_t);
void I2C_write_8(uint8_t, uint8_t, uint8_t);
int16_t I2C_read_16(uint8_t, uint8_t);

const uint8_t SLAVE_ADDRESS = 0x44;   //define the slave address

//  Main Function
void main(void){

    // Define variables
    volatile uint16_t mId = 0;
    volatile uint32_t lightData = 0;

    // Halt the WatchDog Timer
    WDT_A_hold(WDT_A_BASE);

    // Activate new port configurations and put all GPIO low (LOW POWER)
    GPIO_init();

    initializeADC();

    // Initialize I2C port
    initI2C();

    /* Set Default configuration for OPT3001*/
    I2C_write_16(SLAVE_ADDRESS, CONFIG_REG, DEFAULT_CONFIG_100);

    //obtain manufacturing information, obtain light info, blink LED
    while(1){
        ADC12_B_startConversion(ADC12_B_BASE,
        ADC12_B_MEMORY_0,
        ADC12_B_SINGLECHANNEL);
        //Poll for interrupt on memory buffer 0
        while (!ADC12_B_getInterruptStatus(ADC12_B_BASE,
        0,
        ADC12_B_IFG0));
        __no_operation();
//        mId = I2C_read_16(SLAVE_ADDRESS, 0x7E);  //send the data, expect <start> <address> <regAddress> <ACK> <start> <regAddress> <ACK> <data> <ACK> <data> <ACK> <end>
//        lightData = OPT3001_getLux(0x44);
//        __delay_cycles(100000);    //Toggle PIN to indicate data was sent
//        GPIO_toggleOutputOnPin(GPIO_PORT_P1, GPIO_PIN0);                    //delay
    }

}

void initializeADC(void){

    // Change the ACLK frequency to 10K, check the value
    CS_initClockSignal(CS_ACLK, CS_VLOCLK_SELECT, CS_CLOCK_DIVIDER_1);
    volatile uint32_t freq = CS_getACLK();

    //Initialize the ADC12B Module
        /*
        * Base address of ADC12B Module
        * Use internal ADC12B bit as sample/hold signal to start conversion
        * USE ACLK 10000 Digital Oscillator as clock source
        * Use default clock divider/pre-divider of 1
        * Not use internal channel
        */
        ADC12_B_initParam initParam = {0};
        initParam.sampleHoldSignalSourceSelect = ADC12_B_SAMPLEHOLDSOURCE_SC;
        initParam.clockSourceSelect = ADC12_B_CLOCKSOURCE_ACLK;
        initParam.clockSourceDivider = ADC12_B_CLOCKDIVIDER_1;
        initParam.clockSourcePredivider = ADC12_B_CLOCKPREDIVIDER__1;
        initParam.internalChannelMap = ADC12_B_NOINTCH;

        //initialize ADC with above parameters
        ADC12_B_init(ADC12_B_BASE, &initParam);

        //set the resolution of ADC
        ADC12_B_setResolution(ADC12_B_BASE, ADC12_B_RESOLUTION_8BIT);
        //Enable the ADC12B module
        ADC12_B_enable(ADC12_B_BASE);

        /*
        * Base address of ADC12B Module
        * For memory buffers 0-7 sample/hold for 64 clock cycles
        * For memory buffers 8-15 sample/hold for 4 clock cycles (default)
        * Enable Multiple Sampling
        */
        ADC12_B_setupSamplingTimer(ADC12_B_BASE,
          ADC12_B_CYCLEHOLD_16_CYCLES,
          ADC12_B_CYCLEHOLD_4_CYCLES,
          ADC12_B_MULTIPLESAMPLESENABLE);

        //Configure Memory Buffer
        /*
        * Base address of the ADC12B Module
        * Configure memory buffer 0
        * Map input A1 to memory buffer 0
        * Vref+ = AVcc
        * Vref- = AVss
        * Memory buffer 0 is not the end of a sequence
        */
        //  JoyStickXParam Structure
        ADC12_B_configureMemoryParam input = {0};
        input.memoryBufferControlIndex = ADC12_B_MEMORY_0;
        input.inputSourceSelect = ADC12_B_INPUT_A12;
        input.refVoltageSourceSelect = ADC12_B_VREFPOS_AVCC_VREFNEG_VSS;
        input.endOfSequence = ADC12_B_NOTENDOFSEQUENCE;
        input.windowComparatorSelect = ADC12_B_WINDOW_COMPARATOR_DISABLE;
        input.differentialModeSelect = ADC12_B_DIFFERENTIAL_MODE_DISABLE;
        ADC12_B_configureMemory(ADC12_B_BASE, &input);



        // Clear Interrupt
        ADC12_B_clearInterrupt(ADC12_B_BASE,0,ADC12_B_IFG1);

//        //Enable memory buffer 1 interrupt
//        ADC12_B_enableInterrupt(ADC12_B_BASE,ADC12_B_IE1,0,0);

        GPIO_setAsPeripheralModuleFunctionInputPin(
            GPIO_PORT_P3, GPIO_PIN0, GPIO_TERNARY_MODULE_FUNCTION);

    }


int8_t I2C_read_8(uint8_t slaveAddress, uint8_t regAddress)
{
    volatile int8_t val = 0,temp;

    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, SLAVE_ADDRESS);
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,EUSCI_B_I2C_TRANSMIT_INTERRUPT0 + EUSCI_B_I2C_RECEIVE_INTERRUPT0);


    //Set master to transmit mode, send slave address, send register address wanted to be read, send stop
    /* Set master to transmit mode PL */
    EUSCI_B_I2C_setMode(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_MODE);

    /* Clear any existing interrupt flag PL */
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_INTERRUPT0+EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Wait until ready to write PL */
    while (EUSCI_B_I2C_isBusBusy(EUSCI_B2_BASE));

    /* Initiate start and send register address wanted to be read */
    EUSCI_B_I2C_masterSendMultiByteStart(EUSCI_B2_BASE, regAddress);

    /* Wait for TX to finish */
    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_INTERRUPT0)));

    /* Initiate stop only */
    EUSCI_B_I2C_masterSendMultiByteStop(EUSCI_B2_BASE);


    //set master to recieve mode, send start and receive 16 bit data
    /* Set msster to recieve mode */
    EUSCI_B_I2C_masterReceiveStart(EUSCI_B2_BASE);

    /* Wait for RX buffer to fill */
    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_RECEIVE_INTERRUPT0)));

    //the register information has filled, the recieve byte next goes looks at first 8 bit data, then a stop tells it to look at next 8 bits
    /* Read from I2C RX register*/
    val = EUSCI_B_I2C_masterReceiveMultiByteNext(EUSCI_B2_BASE);
    /* Receive second byte then send STOP condition */
    EUSCI_B_I2C_masterReceiveMultiByteStop(EUSCI_B2_BASE);

    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_RECEIVE_INTERRUPT0)));

    /* Return temperature value */
    return val;


}


int16_t I2C_read_16(uint8_t slaveAddress, uint8_t regAddress)
{
    volatile int16_t val = 0,temp;
    volatile int16_t valScratch = 0;

    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, SLAVE_ADDRESS);
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,EUSCI_B_I2C_TRANSMIT_INTERRUPT0 + EUSCI_B_I2C_RECEIVE_INTERRUPT0);


    //Set master to transmit mode, send slave address, send register address wanted to be read, send stop
    /* Set master to transmit mode PL */
    EUSCI_B_I2C_setMode(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_MODE);

    /* Clear any existing interrupt flag PL */
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_INTERRUPT0+EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Wait until ready to write PL */
    while (EUSCI_B_I2C_isBusBusy(EUSCI_B2_BASE));

    /* Initiate start and send first character */
    EUSCI_B_I2C_masterSendMultiByteStart(EUSCI_B2_BASE, regAddress);

    /* Wait for TX to finish */
    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_INTERRUPT0)));

    /* Initiate stop only */
    EUSCI_B_I2C_masterSendMultiByteStop(EUSCI_B2_BASE);


    //set master to recieve mode, send start and receive 16 bit data
    /* Set msster to recieve mode */
    EUSCI_B_I2C_masterReceiveStart(EUSCI_B2_BASE);

    /* Wait for RX buffer to fill */
    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_RECEIVE_INTERRUPT0)));

    //the register information has filled, the recieve byte next goes looks at first 8 bit data, then a stop tells it to look at next 8 bits
    /* Read from I2C RX register*/
    val = EUSCI_B_I2C_masterReceiveMultiByteNext(EUSCI_B2_BASE);
    /* Receive second byte then send STOP condition */
    EUSCI_B_I2C_masterReceiveMultiByteStop(EUSCI_B2_BASE);

    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_RECEIVE_INTERRUPT0)));

    valScratch = EUSCI_B_I2C_masterReceiveMultiByteNext(EUSCI_B2_BASE);

    /* Shift val to top MSB */
    val = (val << 8);

    /* Read from I2C RX Register and write to LSB of val */
    val |= valScratch;

    /* Return temperature value */
    return (int16_t)val;


}

void I2C_write_8(uint8_t slaveAddress, uint8_t regAddress, uint8_t data)
{
    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, SLAVE_ADDRESS);
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,EUSCI_B_I2C_TRANSMIT_INTERRUPT0 + EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Set master to transmit mode PL */
    EUSCI_B_I2C_setMode(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_MODE);

    /* Clear any existing interrupt flag PL */
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_INTERRUPT0+EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Wait until ready to write PL */
    while (EUSCI_B_I2C_isBusBusy(EUSCI_B2_BASE));

    /* Initiate start, send slave address, send register address */
    EUSCI_B_I2C_masterSendMultiByteStart(EUSCI_B2_BASE, regAddress);

    /* Send the data MSB first */
    EUSCI_B_I2C_masterSendMultiByteFinish(EUSCI_B2_BASE, (unsigned char)(data));

}

void I2C_write_16(uint8_t slaveAddress, uint8_t regAddress, uint16_t data)
{
    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, SLAVE_ADDRESS);
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,EUSCI_B_I2C_TRANSMIT_INTERRUPT0 + EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Set master to transmit mode PL */
    EUSCI_B_I2C_setMode(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_MODE);

    /* Clear any existing interrupt flag PL */
    EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,
        EUSCI_B_I2C_TRANSMIT_INTERRUPT0+EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Wait until ready to write PL */
    while (EUSCI_B_I2C_isBusBusy(EUSCI_B2_BASE));

    /* Initiate start, send slave address, send register address */
    EUSCI_B_I2C_masterSendMultiByteStart(EUSCI_B2_BASE, regAddress);

    /* Send the data MSB first */
    EUSCI_B_I2C_masterSendMultiByteNext(EUSCI_B2_BASE, (unsigned char)(data>>8));

    EUSCI_B_I2C_masterSendMultiByteFinish(EUSCI_B2_BASE, (unsigned char)(data&0xFF));

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
