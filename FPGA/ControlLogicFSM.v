module ControlLogicFSM(clk, reset_n, 
							  myRegDevAddresslsb, myRegDevAddressmsb, myRegManIDlsb, myRegManIDmsb, myRegDevIDlsb, myRegDevIDmsb, myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb, 
							  myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb,
							  o_result, o_sync, i_sample,
							  done, Tone, i_ce, TDenable,
							  FFT_rst, TD_rst, I2C_rst);
											  
	//ASIC external signals
	input clk, reset_n;
	
	//I2c stuff
	input [7:0] myRegDevAddresslsb;
	input [7:0] myRegDevAddressmsb;
	input [7:0] myRegManIDlsb;
	input [7:0] myRegManIDmsb;
	input [7:0] myRegDevIDlsb;
	input [7:0] myRegDevIDmsb;
	input [7:0] myRegMCUStatuslsb;
	input [7:0] myRegMCUStatusmsb;
	input [7:0] myRegSampleInlsb;
	input [7:0] myRegSampleInmsb;
	output reg [7:0] myRegASICStatuslsb;
	output reg [7:0] myRegASICStatusmsb;
	output reg [7:0] myRegResultslsb;
	output reg [7:0] myRegResultsmsb;

	//FFT stuff
	input [15:0] o_result; 
	input o_sync;
	output reg [15:0] i_sample;
	
	//Tone detector stuff
	input done;
	input [15:0] Tone;
	output reg i_ce; 
	output reg TDenable;

	// Internal modules reset
	output reg FFT_rst, TD_rst, I2C_rst;
	
	reg CEflag;
	integer clkcount;
	integer nextsample = 0;
	
	//starts in initial
	reg [3:0] pState = 1;
	
	localparam [3:0] 
		SRInitial = 4'd0,
		SInitial = 4'd1,
		SEnable = 4'd2,
		SStart = 4'd3,
		SFFTIn = 4'd4,
		SFFTWait = 4'd5,
		SFFTOut = 4'd6,
		SDone = 4'd7,
		SError = 4'd8;

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
			I2C_rst <= 1'b0; //active low								//temp comment, this needs to be reset
			FFT_rst <= 1'b1; // FFT reset is active high
			TD_rst <= 1'b0; 
			TDenable <= 1'b0;
			i_sample <= 16'hXXXX;
			CEflag <= 1'b0;
			pState <= SRInitial;
			
		end else begin
		
			case(pState) 
			
				//After coming out of reset, wait for MCu to reset its registers
				SRInitial: 	begin
				
									if((myRegMCUStatuslsb == 0) && (myRegMCUStatusmsb == 0)) pState <= SInitial;
									
									I2C_rst <= 1'b1;
									
								end
				//starting state, reset all modules
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
									CEflag <= 1'b0;
									
									if(myRegMCUStatuslsb[0] == 1'b1) pState <= SEnable; // Enable start
									
								end
				//take things out of reset 				
				SEnable:		begin
				
									myRegASICStatuslsb[6:3] <= pState; //used for debug
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
									
									if(myRegMCUStatuslsb[1] == 1'b1) pState <= SFFTIn; //if fpga is enabled
									
								end
				
				//input sample from mcu into fft
				SFFTIn:		begin
				
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									
									if(myRegMCUStatusmsb[6:0] == nextsample) begin //make sure fpga and MCU are on same sample, else wait
									
										i_sample <= {myRegSampleInmsb, myRegSampleInlsb};
										clkcount <= 0;
										CEflag <= 1'b1;
										pState <= SFFTWait;
										
									//error state handling
									end else if (myRegMCUStatusmsb[6:0] > myRegASICStatusmsb[6:0]) begin //mcu sample number should never be greater than what the asic is on
										
										pState <= SError;
									
									end else if (myRegASICStatusmsb[6:0] > 0) begin
										
										if (myRegMCUStatusmsb[6:0] < (myRegASICStatusmsb[6:0] - 1)) pState <= SError; //mcu sample number should never be more than 1 behind the asic 
										
									end
									
								end
				
				//wait for mcu to send next sample
				SFFTWait:	begin
				
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									CEflag <= 0;
									
									if(clkcount < 3) begin
									
										clkcount <= clkcount + 1;
										
										if(clkcount==2) begin //fpga is ready for next sample
											nextsample <= nextsample + 1;
											myRegASICStatusmsb[6:0] <= nextsample + 1;
										end
										
									end else if((myRegMCUStatusmsb[6:0] == nextsample) && (nextsample < 128)) begin //mcu has sent next sample
										
										pState <= SFFTIn;
										
									end else if(nextsample == 128) begin //all samples have been sent
										
										nextsample <= 0;
										clkcount <= 0;
										CEflag <= 1'b1;
										pState <= SFFTOut;
										
									//error state handling
									end else if (myRegMCUStatusmsb[6:0] > myRegASICStatusmsb[6:0]) begin //mcu sample number should never be greater than what the asic is on
										
										pState <= SError;
										
									end else if (myRegASICStatusmsb[6:0] > 0) begin
										
										if (myRegMCUStatusmsb[6:0] < (myRegASICStatusmsb[6:0] - 1)) pState <= SError; //mcu sample number should never be more than 1 behind the asic 
										
									end
									
								end
				
				//wait for fft to finish processing data, when done, set output accordingly and move to next state		
				SFFTOut:  	begin
				
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									CEflag <= 0;
									myRegASICStatuslsb[1] <= 1'b1; //busy(1 - busy, 0 not busy)
									myRegASICStatuslsb[2] <= 1'b0; //input mode (1 - inputs mode, 0 calulating output)
									
									//handle chip enable properly
									if(clkcount == 0) clkcount <= clkcount+1;
									else if(clkcount < 3) clkcount <= clkcount+1;
									else begin
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
									
									if(myRegMCUStatuslsb[2] == 1'b1) pState <= SInitial; //wait for mcu to read result 
									
								end
				//error, mcu and fpga out of sync			
				SError: 		begin
				
									myRegASICStatuslsb[6:3] <= pState; //used for debug
									
									if(myRegMCUStatuslsb[4] == 1'b1) pState <= SInitial; //escape error state if flag is set properly
									
								end
								
			endcase
			
		end	
		
	end
	
endmodule
							