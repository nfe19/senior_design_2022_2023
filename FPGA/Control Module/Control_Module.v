module Control_Module(
	input clk, scl,
	inout sda,
	output writeEnOut);//writeEnOut is an I2c signal
	
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
	wire I2Crst;
	
	//Tone detector stuff
	reg i_ce=0; 
	reg TDenable;
	reg [15:0] bins;
	wire busy, done, error;
	wire [15:0] Tone;
	
	
	//FFT stuff
	reg [15:0] i_sample;
	reg rst=1;
	wire [15:0] o_result; 
	wire o_sync;
	
	
	reg [3:0] pState;
	
	reg CEflag;
	integer clkcount;
	integer samplecount=0;
	
	localparam [3:0] 
		SInitial = 4'd0,
		SWait = 4'd1,
		SFFTIn = 4'd2,
		SFFTWait = 4'd3,
		SFFTOut = 4'd4,
		SDone = 4'd5;
	
	I2C_Module uI2C(clk,I2Crst,sda,scl,myRegDevAddressmsb,myRegDevAddresslsb,myRegManIDmsb,myRegManIDlsb,myRegDevIDmsb,myRegDevIDlsb,
						 myRegMCUStatusmsb,myRegMCUStatuslsb,myRegSampleInmsb,myRegSampleInlsb,myRegASICStatusmsb,myRegASICStatuslsb,
						 myRegResultsmsb,myRegResultslsb,writeEnOut);
  
	FFT_Module uFFT(clk, rst, i_ce,i_sample, o_result, o_sync);
	
	ToneDetector_Module uTD(i_ce, rst, TDenable, o_result, busy, done, error, Tone);
	
	assign I2Crst = 1;
	
	//write logic to check MSP status register and set CE accordingly, would have to stay low for the next three CC
	//probably would require another flag to check if the CE has already been high within the last three CC
	always @(negedge(clk)) begin //chip enable goes high on negedge, goes back low on negedge
		if(CEflag) begin
			i_ce <= 1;
		end else begin
			i_ce <= 0;
		end
	end //end always
	
	always @(posedge(clk) or posedge(rst)) begin
		if(rst) begin
			pState <= SInitial;
		end else begin
			case(pState) 
				SInitial:	begin
									myRegASICStatusmsb<= 8'h00;
									myRegASICStatuslsb<= 8'h00;
									TDenable <= 1'b0;
									i_sample <= 16'h0000;
									pState <= SWait;
								end
							
				SWait:		begin
									rst<=0;
									myRegASICStatuslsb[0]<= 1'b0;
									myRegASICStatuslsb[1]<= 1'b0;
									myRegASICStatuslsb[2]<= 1'b1;
									myRegASICStatuslsb[3]<= 1'b1;
									if(myRegMCUStatuslsb[0]==0) pState <= SFFTIn;
									samplecount=0;
									clkcount=0;
									CEflag=0;
								end
						
				SFFTIn:		begin
									i_sample <= {myRegSampleInmsb, myRegSampleInlsb};
									samplecount <= samplecount +1;
									CEflag <= 1;
									pState <= SFFTWait;
									clkcount <=0;
									myRegASICStatuslsb[3]<= 1'b1;
								end
						
				SFFTWait:	begin
									myRegASICStatuslsb[3]<= 1'b0;
									CEflag <= 0;
									if(clkcount<4) begin
										clkcount <=clkcount +1;
									end else if(myRegMCUStatuslsb[0]==0&&samplecount<128) begin //change to check status to see if new sample is in reg
										pState <= SFFTIn;
									end else if(samplecount==128) begin
										pState <= SFFTOut;
										samplecount=0;
									end
									
								end
						
				SFFTOut:  	begin
									myRegASICStatuslsb[1]<= 1'b1;
									myRegASICStatuslsb[2]<= 1'b0;
									myRegASICStatuslsb[3]<= 1'b0;
									if(clkcount==0) begin
										CEflag  <=1;
									end else if(clkcount<4) begin
										CEflag<=0;
									end else begin
										clkcount <= 0;
										CEflag  <=1;
									end
									clkcount <= clkcount+1;
									
									if(o_sync==1) begin
										pState<=SFFTOut;
										TDenable<=1;
									end
									
									if(done==1) begin
										pState<=SDone;
										{myRegResultsmsb,myRegResultslsb}<=Tone;
										myRegASICStatuslsb[0]<= 1'b1;
										myRegASICStatuslsb[1]<= 1'b0;
									end
								end
							
				SDone: 		begin
									if(myRegMCUStatuslsb[0]==1'b1) begin
										pState <= SWait;
										rst<=1;
									end
								end			 
			endcase
		end	
	end
	
endmodule
							