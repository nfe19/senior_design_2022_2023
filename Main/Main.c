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
#include <math.h>

void GPIO_init(void);
void initI2C(void);
void initializeADC(void);
void initializeUART(void);
void I2C_write_16(uint8_t, uint8_t, uint16_t);
void I2C_write_8(uint8_t, uint8_t, uint8_t);
void genCos(uint16_t, uint16_t, uint16_t, double*);
uint8_t double2ADC(double);
uint16_t I2C_read_16(uint8_t, uint8_t);
uint8_t I2C_read_8(uint8_t, uint8_t);
uint8_t testADC(void);


volatile uint16_t ADCCounter = 0;
uint8_t savedSpeakerValues[8];
uint8_t SLAVE_ADDRESS = 0x3c;   //define the slave address


typedef enum {ONE,TWO,THREE,a,FOUR,FIVE,SIX,b,SEVEN,EIGHT,NINE,c,ASTREK,ZERO,POUND,d,NONE} Tones;
Tones tone;

/*I2C Register Map */
    const uint8_t SLAVE_REG = 0x00;             // the slave address of the I2C device
    const uint8_t MANUID_REG = 0x02;            // the manufacturing ID of the I2C device
    const uint8_t DEVICE_ID_REG = 0x04;         // the device ID of the I2C device
    const uint8_t COMMAND_REG = 0x06;           // the command register that the msp writes to
    const uint8_t STATUS_REG = 0x08;            // the status register that the msp reads from
    const uint8_t RESULTS_REG = 0x0A;           // the register containing value of the result given from the FPGA
    const uint8_t IN_SAMPLE_REG = 0x0C;         // the register the input sample gets written to
/* END I2C Register Map */

/*I2C COMMAND_REG Bit Definitions */
    const uint16_t WAIT_FLAG = 0x0001;          //set: tells FPGA to wait, reset: data is sent and FPGA is ready
    const uint16_t VALID_FLAG = 0x0002;         //set: data has been read, reset: data has not been read
/* END COMMAND_REG Bit Definitions */

/*I2C STATUS_REG Bit Definitions */
    const uint16_t OUT_VALID_FLAG = 0x0001;     //set: output is valid, reset: output is invalid
    const uint16_t BUSY_FLAG = 0x0002;          //set: FPGA is busy, reset: FPGA is not busy
    const uint16_t INPUT_MODE_FLAG = 0x0004;    //set: FPGA is in input mode (wants inputs), reset: FPGA in output mode (calculating outputs)
    const uint16_t INPUT_READY_FLAG = 0x0008;   //set: FPGA wants an input, reset: FPGA does not want an input
/* END STATUS_REG Bit Definitions */

//  Main Function
void main(void){

    volatile uint8_t myRegValues[7] = {0, 0, 0, 0, 0, 0, 0, 0};
    // Define variables for light sensor

    // Halt the WatchDog Timer
    WDT_A_hold(WDT_A_BASE);

    // Activate new port configurations and put all GPIO low (LOW POWER), pin 1.3 as ADC input
    GPIO_init();

    // Initialize I2C port
    initI2C();

    // initialize ADC with 10KHz sampling rate at 8 bits per sample, start continious conversions
    initializeADC();

    initializeUART();

    /*main loop: collect 128 samples, send through I2C, wait until valid results are produced, read off the result register*/
    while(1){
        /* obtain 128 samples, store in list, convert the list to 16 bits each (mimics ADC interrupt)*/
        volatile uint8_t speakerValueList[128];
        volatile uint16_t speakerValueList16[128];
        getMicValues128(ONE, speakerValueList); //get 8 bit ADC values (what would come out of the interrupt of mic)
        listConvert8to16(speakerValueList, speakerValueList16); //convert all data to 16 bits with imagionary part set to 0x00
        /* end ADC mimic*/


        /*if the FPGA is in input mode, and is read for an input, send an input through I2C, until FPGA is in output mode*/
        uint16_t reg_value;
        uint8_t data_list_index = 0;

        do{
            reg_value = I2C_read_16(SLAVE_ADDRESS, STATUS_REG);
            if(((reg_value & INPUT_READY_FLAG) > 0)){
                I2C_write_16(SLAVE_ADDRESS, COMMAND_REG, speakerValueList16[data_list_index]);
                data_list_index++;
            }
        } while((reg_value & INPUT_MODE_FLAG) > 0);

        /*end sending of data*/

        /* wait until valid data is produced by the FPGA and read the result*/
        uint16_t finalResult;
        volatile Tones finalTone;
        while(!(I2C_read_16(SLAVE_ADDRESS, STATUS_REG) & OUT_VALID_FLAG));
        finalResult = I2C_read_16(SLAVE_ADDRESS, RESULTS_REG);
        finalTone = toneDecoder(finalResult);   //make sure decoder matches FPGA
        /* end wait */
    }
    /*end main loop*/

    //enable global interrupts
    //__enable_interrupt();

}


/*
    Author: Najeeb Eeso
*/

#pragma vector=ADC12_VECTOR
__interrupt void ADC12_ISR(void)
{
    char buffer[100];
//    volatile uint8_t value = testADC(); //used to functionally test ADC. set breakpoint here to validate output of ADC if testing
//    GPIO_toggleOutputOnPin(GPIO_PORT_P3, GPIO_PIN1);    //used to test the frequency of the ADC by toggling a GPIO pin

    if (ADCCounter < 999)
        savedSpeakerValues[ADCCounter] = ADC12_B_getResults(ADC12_B_BASE, ADC12_B_MEMORY_0);
        sprintf(buffer,"%u ",ADC12_B_getResults(ADC12_B_BASE, ADC12_B_MEMORY_0));
            UART_transmitString(buffer);

        ADCCounter = ADCCounter+1;
    //svolatile uint16_t answer = ADC12_B_getResults(ADC12_B_BASE, ADC12_B_MEMORY_0);


    //clear the ADC interrupt
    ADC12_B_clearInterrupt(ADC12_B_BASE,0,ADC12_B_IFG0);
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description:
*/

void getMicValues128(Tones tone, uint8_t values[128]){
    double speakerAnalogValue;
    uint8_t sample;
    for(sample=0; sample<128; sample++){
        genToneSin(tone,sample,&speakerAnalogValue);
        values[sample] = double2ADC(speakerAnalogValue)-0x7f;
    }
}


/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description:
*/

void listConvert8to16(uint8_t values8[128], uint16_t values16[128]){
    uint8_t sample;
    for(sample=0; sample<128; sample++){
        values16[sample] = (values8[sample] << 8) & (0xFF00);
    }
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description:
*/

Tones toneDecoder(uint16_t result){
    switch(result){
            case 0x0000: return ZERO;
            case 0x0001: return ONE;
            case 0x0002: return TWO;
            case 0x0003: return THREE;
            case 0x0004: return FOUR;
            case 0x0005: return FIVE;
            case 0x0006: return SIX;
            case 0x0007: return SEVEN;
            case 0x0008: return EIGHT;
            case 0x0009: return NINE;
            case 0x000A: return ASTREK;
            case 0x000B: return POUND;
            case 0x000C: return a;
            case 0x000D: return b;
            case 0x000E: return c;
            case 0x000F: return d;
            default: return NONE;
        }
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Used to generate a single cos, simulating the voltage that the ADC would get.
*/

void debugReg(uint8_t myRegValues[7]){
    uint8_t i = 0;
    volatile uint8_t dummy;
    for(; i<8; i++){
        dummy = I2C_read_8(SLAVE_ADDRESS, i);
        myRegValues[i] = dummy;
    }
}

void genCos(uint16_t f, uint16_t fs, uint16_t sample, double* result ){
    double y = 1.65*(cos(2*M_PI*f*sample/fs)+1);
    *result = y;
}

void genSin(uint16_t f, uint16_t fs, uint16_t sample, double* result ){
    double y = 1.65*(sin(2*M_PI*f*sample/fs)+1);
    *result = y;
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Used to generate a combination of two cos, simulating the voltage that the ADC would get.
*/
void genCos2(uint16_t f1, uint16_t f2, uint16_t fs, uint16_t sample, double* result){
    //rowFreqLUT();
    double y = .825*(cos(2*M_PI*f1*sample/fs)+cos(2*M_PI*f2*sample/fs)+2);
    *result = y;
}

void genSin2(uint16_t f1, uint16_t f2, uint16_t fs, uint16_t sample, double* result){
    //rowFreqLUT();
    double y = .825*(sin(2*M_PI*f1*sample/fs)+sin(2*M_PI*f2*sample/fs)+2);
    *result = y;
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: outputs the row frequency of a dual tone.
*/
uint16_t rowFreqLUT(Tones tone){
    switch(tone){
        case ONE:
        case TWO:
        case THREE:
        case a:
            return 697;
        case FOUR:
        case FIVE:
        case SIX:
        case b:
            return 770;
        case SEVEN:
        case EIGHT:
        case NINE:
        case c:
            return 852;
        case ASTREK:
        case ZERO:
        case POUND:
        case d:
            return 941;

    }
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: outputs the col frequency of a dual tone.
*/
uint16_t colFreqLUT(Tones tone){
    switch(tone){
        case ONE:
        case FOUR:
        case SEVEN:
        case ASTREK:
            return 1209;
        case TWO:
        case FIVE:
        case EIGHT:
        case ZERO:
            return 1336;
        case THREE:
        case SIX:
        case NINE:
        case POUND:
            return 1477;
        case a:
        case b:
        case c:
        case d:
            return 1633;

    }
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Used to generate a combination of two cos of a dual tone, simulating the voltage that the ADC would get for each dual tone at the sampling rate.
*/
void genToneCos(Tones tone, uint16_t sample, double* result){
    uint16_t samplingFreq = 5000;
    genCos2(colFreqLUT(tone), rowFreqLUT(tone), samplingFreq, sample, result);
}

void genToneSin(Tones tone, uint16_t sample, double* result){
    uint16_t samplingFreq = 5000;
    genSin2(colFreqLUT(tone), rowFreqLUT(tone), samplingFreq, sample, result);
}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Used to simulate an analog voltage going into an ADC, producing an 8 bit value
*/
uint8_t double2ADC(double value){
    volatile double vDiff = 3.3/255;
    volatile uint8_t result = floor(value/vDiff+.5);
    return result;
}


/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Used to test the functionality of the ADC. Reads memory address 0 and returns it.
*/

uint8_t testADC(void){
    return (uint8_t)(ADC12_B_getResults(ADC12_B_BASE,ADC12_B_MEMORY_0));

}


/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Initializes the ADC to 8 bit per sample with a 10KHz sampling rate and stores outputs in memory buffer 0.
                 The converter takes microphone analog input (A3 or pin P1.3) and converts it to digital output. To calculate
                 sampling frequency, the equation (X/Y)/(S*2+B)=10000 was used. X is the clock frequency to the ADC, Y is the overall divider,
                 S is the sample and hold clock value, and B is the bits per sample. For this, X=5MHz, Y=32, S=4 cycles, B=8 bits/sample.
    Test:
                 To test ADC function, make sure to change inputSourceSelect from ADC12_B_INPUT_A3 to ADC12_B_INPUT_A12. Then uncomment volatile uint8_t value = testADC();
                 Then setup a simple voltage divider, connecting the output to pin P3.0. Measure the voltage with a multimeter. The test measured voltage is 1.418V.
                 After running the testADC function, you should see a value that corresponds to the analog voltage to the pin. For the test measuremnt
                 voltage, the obtained value was decimal 110. To convert this obtained digital value to analog, multiply it by 3.3V (Full Scale Range) and divide by 2^8.
                 For the example, 110*3.3/2^8 = 1.41796V. Make sure __enable_interrupt(); is uncommented.

                 To test ADC frequency, uncomment GPIO_toggleOutputOnPin(GPIO_PORT_P3, GPIO_PIN1); Then connect the Digital Analyser to pin P3.1.
                 Everytime the interrupt happens, the pin is toggled (from high to low, or from low to high). Measure the high to low or low to high time and
                 obtain the ADC frequency.
*/
void initializeADC(void){


    //Initialize the ADC12B Module
        /*
        * Base address of ADC12B Module
        * Use internal ADC12B bit as sample/hold signal to start conversion
        * USE ACLK 5MHz Digital Oscillator as clock source
        * Use default clock divider/pre-divider of 32
        * Not use internal channel
        */
        ADC12_B_initParam initParam = {0};
        initParam.sampleHoldSignalSourceSelect = ADC12_B_SAMPLEHOLDSOURCE_SC;
        initParam.clockSourceSelect = ADC12_B_CLOCKSOURCE_ADC12OSC;
        initParam.clockSourceDivider = ADC12_B_CLOCKDIVIDER_8;
        initParam.clockSourcePredivider = ADC12_B_CLOCKPREDIVIDER__4;
        initParam.internalChannelMap = ADC12_B_NOINTCH;

        //initialize ADC with above parameters
        ADC12_B_init(ADC12_B_BASE, &initParam);

        //set the resolution of ADC to 8 bit
        ADC12_B_setResolution(ADC12_B_BASE, ADC12_B_RESOLUTION_8BIT);

        //Enable the ADC12B module
        ADC12_B_enable(ADC12_B_BASE);

        /*
        * Base address of ADC12B Module
        * For memory buffers 0-7 sample/hold for 4 clock cycles.
        * For memory buffers 8-15 sample/hold for 4 clock cycles (default)
        * Enable Multiple Sampling
        */
        ADC12_B_setupSamplingTimer(ADC12_B_BASE,
          ADC12_B_CYCLEHOLD_4_CYCLES,
          ADC12_B_CYCLEHOLD_4_CYCLES,
          ADC12_B_MULTIPLESAMPLESENABLE);

        //Configure Memory Buffer
        /*
        * Base address of the ADC12B Module
        * Configure memory buffer 0
        * Map input A12 to memory buffer 0
        * Vref+ = AVcc (3.3V)
        * Vref- = AVss (0V)
        * Memory buffer 0 is not the end of a sequence
        */
        // Microphone input
        ADC12_B_configureMemoryParam input = {0};
        input.memoryBufferControlIndex = ADC12_B_MEMORY_0;
        input.inputSourceSelect = ADC12_B_INPUT_A3;
        input.refVoltageSourceSelect = ADC12_B_VREFPOS_AVCC_VREFNEG_VSS;
        input.endOfSequence = ADC12_B_NOTENDOFSEQUENCE;
        input.windowComparatorSelect = ADC12_B_WINDOW_COMPARATOR_DISABLE;
        input.differentialModeSelect = ADC12_B_DIFFERENTIAL_MODE_DISABLE;
        ADC12_B_configureMemory(ADC12_B_BASE, &input);

        // Clear Interrupt
        ADC12_B_clearInterrupt(ADC12_B_BASE,0,ADC12_B_IFG0);

        //Enable memory buffer 0 interrupt
        ADC12_B_enableInterrupt(ADC12_B_BASE,ADC12_B_IE0,0,0);

        // start ADC conversion on repeated mode
        ADC12_B_startConversion(ADC12_B_BASE,ADC12_B_START_AT_ADC12MEM0,ADC12_B_REPEATED_SINGLECHANNEL);

    }


/*
    Author: Najeeb Eeso
    Inputs: slaveAddress: the 8 bit address of the device wanted to be communicated to
            regAddress: the 8 bit register address wanted to be read from
    Outputs: 8 bit register information
    Description: Reads 8 bit data to from a device through I2C. A start bit is sent, then an 8 bit address to select a slave device with write command, then an ack from a device, then
                 the register wanted to be read from, then an ack and a stop. Another Start is sent, with an 8 bit address to select a slave device with a read command. Then the 8 bit
                 content is sent from the slave to the master.
    Test: set a breakpoint at mId = I2C_read_8(0x44, 0x7E);. Connect pin P7.0 (SDA) to DIN 19 on the digital analyser. Connect pin P7.1 (SCL) to DIN 18
                 on the digital analyser. Open the default waveforms workspace I2C.dwf3work. Press single trigger mode and step over the breakpoint to view the waveforms. Ensure
                 that the communication protocol sent: <start> <0x44 Write> <ACK> <0x7E> <ACK> <STOP> <start> <0x44 Write> <ACK> <data> <NACK> <STOP>. The read data should be
                 0x54


*/
uint8_t I2C_read_8(uint8_t slaveAddress, uint8_t regAddress)
{
    volatile int8_t val = 0,temp;

    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, slaveAddress);
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
    val = EUSCI_B_I2C_masterReceiveSingleByte(EUSCI_B2_BASE);

    /* Return temperature value */
    return val;


}


/*
    Author: Najeeb Eeso
    Inputs: slaveAddress: the 8 bit address of the device wanted to be communicated to
            regAddress: the 8 bit register address wanted to be read from
    Outputs: None
    Description: Reads 16 bit data to from a device through I2C. 2 8 bit reads are performed
    Test:

*/
uint16_t I2C_read_16(uint8_t slaveAddress, uint8_t regAddress){
    volatile uint16_t value;
    volatile uint8_t temp;
    value = I2C_read_8(slaveAddress, regAddress);
    temp = I2C_read_8(slaveAddress, regAddress+0x01);
    value = temp | (value<<8);
    return value;
}


/*
    Author: Najeeb Eeso
    Inputs: slaveAddress: the 8 bit address of the device wanted to be communicated to
            regAddress: the 8 bit register address wanted to be read from
    Outputs: None
    Description: Reads 16 bit data to from a device through I2C. A start bit is sent, then an 8 bit address to select a slave device with write command, then an ack from a device, then
                 the register wanted to be read from, then an ack and a stop. Another Start is sent, with an 8 bit address to select a slave device with a read command. Then the 16 bit
                 content is sent from the slave to the master.
    Test:
                 DOES NOT WORK AT 400k SPEED, ONLY 10K
*/
int16_t I2C_read_16_bad(uint8_t slaveAddress, uint8_t regAddress)
{
    volatile int16_t val = 0,temp;
    volatile int16_t valScratch = 0;

    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, slaveAddress);
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

//    /* Wait for RX buffer to fill */
    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
        EUSCI_B_I2C_RECEIVE_INTERRUPT0)));

    //the register information has filled, the recieve byte next goes looks at first 8 bit data, then a stop tells it to look at next 8 bits
    /* Read from I2C RX register*/
    val = EUSCI_B_I2C_masterReceiveMultiByteNext(EUSCI_B2_BASE);
    /* Receive second byte then send STOP condition */

    while(!(EUSCI_B_I2C_getInterruptStatus(EUSCI_B2_BASE,
            EUSCI_B_I2C_RECEIVE_INTERRUPT0)));

    EUSCI_B_I2C_masterReceiveMultiByteStop(EUSCI_B2_BASE);

    valScratch = EUSCI_B_I2C_masterReceiveMultiByteNext(EUSCI_B2_BASE);

    /* Clear any existing interrupt flag PL */
//        EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,
//            EUSCI_B_I2C_TRANSMIT_INTERRUPT0+EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    /* Shift val to top MSB */
    val = (val << 8);

    /* Read from I2C RX Register and write to LSB of val */
    val |= valScratch;

    /* Return temperature value */
    return (int16_t)val;


}

/*
    Author: Najeeb Eeso
    Inputs: slaveAddress: the 8 bit address of the device wanted to be communicated to
            regAddress: the 8 bit register address wanted to be written to
            data: the 8 bit data wanted to be stored in the register address
    Outputs: None
    Description: Writes 16 bit data to a device through I2C. A start bit is sent, then an 8 bit address to select a slave device, then an ack from a device, then
                 the register wanted to be written to, then an ack, then the 16 bit data followed by either an ack/nack and a stop command.
    Test:
                 set a breakpoint at I2C_write_8(SLAVE_ADDRESS, 0x26, 0xA9);. Connect pin P7.0 (SDA) to DIN 19 on the digital analyser. Connect pin P7.1 (SCL) to DIN 18
                 on the digital analyser. Open the default waveforms workspace I2C.dwf3work. Press single trigger mode and step over the breakpoint to view the waveforms. Ensure
                 that the communication protocol sent: <start> <0x44 Write> <ACK> <0x26> <ACK> <0xA9> <ACK> <STOP>
*/
void I2C_write_8(uint8_t slaveAddress, uint8_t regAddress, uint8_t data)
{
    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, slaveAddress);
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

/*
    Author: Najeeb Eeso
    Inputs: slaveAddress: the 8 bit address of the device wanted to be communicated to
            regAddress: the 8 bit register address wanted to be written to
            data: the 16 bit data wanted to be stored in the register address
    Outputs: None
    Description: Writes 16 bit data to a device through I2C. A start bit is sent, then an 8 bit address to select a slave device, then an ack from a device, then
                 the register wanted to be written to, then an ack, then the 16 bit data followed by either an ack/nack and a stop command.
    Test:
                 set a breakpoint at I2C_write_16(SLAVE_ADDRESS, CONFIG_REG, DEFAULT_CONFIG_100); that configures the light detector on the boosterpack. Connect pin
                 P7.0 (SDA) to DIN 19 on the digital analyser. Connect pin P7.1 (SCL) to DIN 18 on the digital analyser. Open the default waveforms workspace
                 I2C.dwf3work. Press single trigger mode and step over the breakpoint to view the waveforms. Ensure that the
                 communication protocol sent: <start> <0x44 Write> <ACK> <0x01> <ACK> <0xC4> <ACK> <0x10> <ACK> <STOP>
*/
void I2C_write_16(uint8_t slaveAddress, uint8_t regAddress, uint16_t data)
{
    /* Specify slave address*/
    EUSCI_B_I2C_setSlaveAddress(EUSCI_B2_BASE, slaveAddress);
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

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description: Initializes the I2C module on pins P7.1 (SCL) and P7.0(SDA) for 400 KHz trannsmission rate
*/
void initI2C( void )
{

    CS_initClockSignal(CS_SMCLK, CS_MODOSC_SELECT, CS_CLOCK_DIVIDER_1);

    //Set 7.1 and 7.0 as I2C output peripherals
    GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_P7, GPIO_PIN0, GPIO_PRIMARY_MODULE_FUNCTION);
    GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_P7, GPIO_PIN1, GPIO_PRIMARY_MODULE_FUNCTION);


    EUSCI_B_I2C_initMasterParam i2cParameters =
    {
         EUSCI_B_I2C_CLOCKSOURCE_SMCLK,          // SMCLK Clock Source
         5000000,                               // SMCLK = 1.00MHzMHz
         EUSCI_B_I2C_SET_DATA_RATE_400KBPS,      // Desired I2C Clock of 400khz
    };

    //disable I2C, initialize with parameters set above, enable I2C
    EUSCI_B_I2C_disable(EUSCI_B2_BASE);
    EUSCI_B_I2C_initMaster(EUSCI_B2_BASE, &i2cParameters);    //initialize with parameters
    EUSCI_B_I2C_enable(EUSCI_B2_BASE);  //enable i2c

}

/*
    Author: Najeeb Eeso
    Inputs: None
    Outputs: None
    Description:
*/
void initializeUART( void )
{

    UART_initGPIO();
    UART_init();

}


/* Initializes GPIO as outputs low*/
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

    GPIO_setAsPeripheralModuleFunctionInputPin(
        GPIO_PORT_P3, GPIO_PIN0, GPIO_TERNARY_MODULE_FUNCTION);

    GPIO_setAsPeripheralModuleFunctionInputPin(
            GPIO_PORT_P1, GPIO_PIN3, GPIO_TERNARY_MODULE_FUNCTION);

    // Disable the GPIO power-on default high-impedance mode
    // to activate previously configured port settings
    PMM_unlockLPM5();
}



//    uint8_t i;
//    volatile int8_t data8;
//    uint8_t readInput4;
//
//    //code used to generate 20 samples of the 1 tone and transmit it to the FPGA
//    //and display values in 7 SEGMENT
//    for(i=0;i<=20; i++){
//
//        genToneSin(ONE, i, &answer);
//        data8 = double2ADC(answer);
//        data8 = data8-0x7f;

//        //        /* Set Default configuration for OPT3001*/
//                while(I2C_read_8(SLAVE_ADDRESS, 0x02) != 0x00);
//                //debugReg(myRegValues);
//                while(!(I2C_read_8(SLAVE_ADDRESS, 0x04)==0x00));
//                I2C_write_8(SLAVE_ADDRESS, 0x01,data8);    //set breakpoint here to test I2C_write_16
//                //debugReg(myRegValues);
//                I2C_write_8(SLAVE_ADDRESS, 0x02,0x01);
//                //debugReg(myRegValues);
//                while(!(I2C_read_8(SLAVE_ADDRESS, 0x04)==0x01));
//                I2C_write_8(SLAVE_ADDRESS, 0x02,0x00);
//                //debugReg(myRegValues);
               //__delay_cycles(1000000);
//    }

      //code used to generate 20 samples of a cos wave and transmit it to the FPGA
      //and display it on the 7 SEGMENT
//    for(i=0;i<=20; i++){
//
//        genCos(1000, 10000, i, &answer);
//        data8 = double2ADC(answer);
//
//        //        /* Set Default configuration for OPT3001*/
//                while(I2C_read_8(SLAVE_ADDRESS, 0x02) != 0x00);
//                //debugReg(myRegValues);
//                while(!(I2C_read_8(SLAVE_ADDRESS, 0x04)==0x00));
//                I2C_write_8(SLAVE_ADDRESS, 0x01,data8);    //set breakpoint here to test I2C_write_16
//                //debugReg(myRegValues);
//                I2C_write_8(SLAVE_ADDRESS, 0x02,0x01);
//                //debugReg(myRegValues);
//                while(!(I2C_read_8(SLAVE_ADDRESS, 0x04)==0x01));
//                I2C_write_8(SLAVE_ADDRESS, 0x02,0x00);
//                //debugReg(myRegValues);
//                __delay_cycles(1000000);
//    }


    //code used to transmit data to the FPGA
//    uint16_t data1 = 0xFF;
//    uint16_t data2 = 0xFF;
//
//    volatile uint16_t data16 = ((data1)<<8) | (data2);
//    volatile uint8_t data8 = 0xFF;
    /*For testing I2C_write_8 only*/
    //I2C_write_8(SLAVE_ADDRESS, 0x26, 0x00);   //uncomment and set breakpoint here to test I2C_write_8

    //OPT3001_init(0x44);
//    volatile uint8_t readInput4;

//    while(1){
//        /* Set Default configuration for OPT3001*/
//        //while(I2C_read_16(SLAVE_ADDRESS, 0x02) != 0x00);
//        debugReg(myRegValues);
//        readInput4 = I2C_read_8(SLAVE_ADDRESS, 0x04);
//        while(!(readInput4==0x00));
//        I2C_write_8(SLAVE_ADDRESS, 0x01,data8);    //set breakpoint here to test I2C_write_16
//        debugReg(myRegValues);
//        I2C_write_8(SLAVE_ADDRESS, 0x02,0x01);
//        debugReg(myRegValues);
//        readInput4 = I2C_read_8(SLAVE_ADDRESS, 0x04);
//        while(!(readInput4==0x01));
//        I2C_write_8(SLAVE_ADDRESS, 0x02,0x00);
//        debugReg(myRegValues);
//        //I2C_write_8(SLAVE_ADDRESS, 0x01,0x01);
//        //EUSCI_B_I2C_clearInterrupt(EUSCI_B2_BASE,
//            //EUSCI_B_I2C_TRANSMIT_INTERRUPT0+EUSCI_B_I2C_RECEIVE_INTERRUPT0);
//        __delay_cycles(10000);
//        //I2C_read_8(0x3c,0x01);
//
//
//    }


    //Standard data packs: 156 samples collected, 156 samples will be given through I2C.
//    while(counter < 156){
//        genTone(ASTREK, counter, &answer);
//        savedSpeakerValues[counter] = double2ADC(answer);
//        counter = counter+1;
//    }




//mId = I2C_read_8(0x44, 0x7E);
//lightData = OPT3001_getLux(0x44);
