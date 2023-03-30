//Command/MCU
//LSB:
//0 - FPGA enable - (1 - enabled)
//1 - inputting samples ( 1 - sent)
//2 - Valid data has been read (1 - data is read)
//3 - waiting for result (1 - waiting)
//4 - escape error state (1 - escape, 0 - stay in)
//
//MSB
//0-6 - what sample is ready to be sent (0-127)
//
//
//FPGA
//LSB
//0 - output is valid (1 - valid)
//1 - busy(1 - busy, 0 not busy)
//2 - input mode (1 - inputs mode, 0 - calulating output)
//3-6 pstate of statemachine
//
//MSB
//0-6 what sample fpga is ready for (0-127)
module Control_Module(input clk, scl, reset_n,
inout sda,
output writeEnOut //writeEnOut is an I2c signal
);

	//I2c stuff
	wire [7:0] myRegDevAddresslsb;
	wire [7:0] myRegDevAddressmsb;
	wire [7:0] myRegManIDlsb;
	wire [7:0] myRegManIDmsb;
	wire [7:0] myRegDevIDlsb;
	wire [7:0] myRegDevIDmsb;
	wire [7:0] myRegMCUStatuslsb;
	wire [7:0] myRegMCUStatusmsb;
	wire [7:0] myRegSampleInlsb;
	wire [7:0] myRegSampleInmsb;
	reg [7:0] myRegASICStatuslsb;
	reg [7:0] myRegASICStatusmsb;
	reg [7:0] myRegResultslsb;
	reg [7:0] myRegResultsmsb;

											  
	//FFT stuff
	reg [15:0] i_sample;
	wire [15:0] o_result; 
	wire o_sync;
	
	//Tone detector stuff
	reg i_ce; 
	reg TDenable;
	reg [15:0] bins;
	wire done;
	wire [15:0] Tone;
	
	// Internal modules reset
	reg FFT_rst, TD_rst, I2C_rst;
	
	reg CEflag;
	integer clkcount;
	integer nextsample = 0;
	
	reg [3:0] pState;
	
	localparam [3:0] 
		SInitial = 4'd0,
		SEnable = 4'd1,
		SStart = 4'd2,
		SFFTIn = 4'd3,
		SFFTWait = 4'd4,
		SFFTOut = 4'd5,
		SDone = 4'd6,
		SError = 4'd7;
		
	I2C_Module uI2C(clk,I2C_rst,sda,scl,myRegDevAddressmsb,myRegDevAddresslsb,myRegManIDmsb,myRegManIDlsb,myRegDevIDmsb,myRegDevIDlsb,
		myRegMCUStatusmsb,myRegMCUStatuslsb,myRegSampleInmsb,myRegSampleInlsb,myRegASICStatusmsb,myRegASICStatuslsb,
		myRegResultsmsb,myRegResultslsb,writeEnOut);

  
	FFT_Module uFFT(clk, FFT_rst, i_ce, i_sample, o_result, o_sync);
	
	ToneDetector_Module uTD(i_ce, TD_rst, TDenable, o_result, done, Tone);
	
	
	//Logic to control chip enable properly
	always @(negedge(clk)) begin //chip enable goes high on negedge, goes back low on negedge
		
		if(CEflag) i_ce <= 1'b1;
		else i_ce <= 1'b0;
		
	end //end always
	
	always @(posedge(clk) or negedge(reset_n)) begin
		
		if(!reset_n) begin
			myRegASICStatusmsb <= 8'h00;
			myRegASICStatuslsb <= 8'h00;
			myRegResultslsb <= 8'h00;
			myRegResultsmsb <= 8'h00;
			//I2C_rst <= 1'b0; //active low								//temp comment, this needs to be reset
			I2C_rst <= 1'b1;
			FFT_rst <= 1'b1; // FFT reset is active high
			TD_rst <= 1'b0; 
			TDenable <= 1'b0;
			i_sample <= 16'hXXXX;
			bins <= 16'hXXXX;
			CEflag <= 1'b0;
			pState <= SInitial;
		end else begin
			case(pState) 
				//starting state, reset all modules (except I2c)
				SInitial:	begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									myRegASICStatusmsb <= 8'h00;
									myRegASICStatuslsb <= 8'h00;
									myRegResultslsb <= 8'h00;
									myRegResultsmsb <= 8'h00;
									I2C_rst <= 1'b1; //active low
									FFT_rst <= 1'b1;
									TD_rst <= 1'b0;
									TDenable <= 1'b0;
									i_sample <= 16'hXXXX;
									bins <= 16'hXXXX;
									CEflag <= 1'b0;
									if(myRegMCUStatuslsb[0]==1'b1) pState <= SEnable; // Enable start
								end
				//take things out of reset 				
				SEnable:		begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									//I2C_rst <= 1'b1; //active low
									FFT_rst <= 1'b0;
									TD_rst <= 1'b1;
									pState <= SStart;
								end
				//	initialize variables	
				SStart:		begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									myRegASICStatuslsb[0] <= 1'b0; //output is valid (1 valid)
									myRegASICStatuslsb[1] <= 1'b0; ////busy(1 - busy, 0 not busy)
									myRegASICStatuslsb[2] <= 1'b1; //input mode (1 - inputs mode, 0 calulating output)
									nextsample <= 0;
									clkcount <= 0;
									CEflag <= 1'b0;
									if(myRegMCUStatuslsb[1]==1'b1) pState <= SFFTIn; //if fpga is enabled
								end
				
				//input sample from mcu into fft
				SFFTIn:		begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									if(myRegMCUStatusmsb[6:0]==nextsample) begin //make sure fpga and MCU are on same sample, else wait
										i_sample <= {myRegSampleInmsb, myRegSampleInlsb};
										clkcount <= 0;
										CEflag <= 1'b1;
										pState <= SFFTWait;
										
									//error state handling
									end else if (myRegMCUStatusmsb[6:0]>myRegASICStatusmsb[6:0]) begin //mcu sample number should never be greater than what the asic is on
										pState <= SError;
									end else if (0 < myRegASICStatusmsb[6:0]) begin
										if (myRegMCUStatusmsb[6:0]< (myRegASICStatusmsb[6:0] - 1)) begin //mcu sample number should never be more than 1 behind the asic 
											pState <= SError;
										end
									end
								end
				
				//wait for mcu to send next sample
				SFFTWait:	begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									CEflag <= 0;
									if(clkcount<4) begin
										clkcount <= clkcount + 1;
										if(clkcount==3) begin //fpga is ready for next sample
											nextsample<=nextsample+1;
											myRegASICStatusmsb[6:0] <= nextsample+1;
										end
									end else if(myRegMCUStatusmsb[6:0]==(nextsample) && nextsample<128) begin //mcu has sent next sample
										pState <= SFFTIn;
									end else if(nextsample==128) begin //all samples have been sent
										nextsample <= 0;
										clkcount <= 0;
										CEflag <= 1'b1;
										pState <= SFFTOut;
										
									//error state handling
									end else if (myRegMCUStatusmsb[6:0]>myRegASICStatusmsb[6:0]) begin //mcu sample number should never be greater than what the asic is on
										pState <= SError;
									end else if (0 < myRegASICStatusmsb[6:0]) begin
										if (myRegMCUStatusmsb[6:0]< (myRegASICStatusmsb[6:0] - 1)) begin //mcu sample number should never be more than 1 behind the asic 
											pState <= SError;
										end
									end
								end
				
				//wait for fft to finish processing data, when done, set output accordingly and move to next state		
				SFFTOut:  	begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									CEflag <= 0;
									myRegASICStatuslsb[1] <= 1'b1; //busy(1 - busy, 0 not busy)
									myRegASICStatuslsb[2] <= 1'b0; //input mode (1 - inputs mode, 0 calulating output)
									
									//handle chip enable properly
									if(clkcount==0) begin
										clkcount <= clkcount+1;
									end else if(clkcount<4) begin
										clkcount <= clkcount+1;
									end else begin
										clkcount <= 0;
										CEflag <= 1'b1;
									end
									
									if(o_sync) TDenable <= 1'b1; // if osync goes high, enable tone detector
									
									if(done) begin //done comes from tonedetector, wait for tone detector to be done
										{myRegResultsmsb,myRegResultslsb} <= Tone;
										myRegASICStatuslsb[0] <= 1'b1; //output is valid (1 valid)
										myRegASICStatuslsb[1] <= 1'b0; //busy(1 - busy, 0 not busy)
										pState <= SDone;
									end
								end
				
				//wait for mcu to read result
				SDone: 		begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									if(myRegMCUStatuslsb[2]==1'b1) pState <= SInitial; //wait for mcu to read result 
								end
				//error, mcu and fpga out of sync			
				SError: 		begin
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									if(myRegMCUStatuslsb[4]==1'b1) pState <= SInitial; //escape error state if flag is set properly
								end
			endcase
		end	
	end
	
endmodule
							