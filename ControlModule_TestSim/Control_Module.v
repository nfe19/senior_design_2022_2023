module Control_Module(input clk, reset_n, 
							 input [7:0] myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb,
							 output reg [7:0] myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb);
											  
	//FFT stuff
	reg [15:0] i_sample;
	wire [15:0] o_result; 
	wire o_sync;
	
	//Tone detector stuff
	reg i_ce; 
	reg TDenable;
	wire done;
	wire [15:0] Tone;
	
	// Internal modules reset
	reg FFT_rst, TD_rst;
	
	reg CEflag;
	integer clkcount;
	integer samplecount = 0;
	
	reg [3:0] pState;
	
	localparam [3:0] 
		SInitial = 4'd0,
		SEnable = 4'd1,
		SWait = 4'd2,
		SFFTIn = 4'd3,
		SFFTWait = 4'd4,
		SFFTOut = 4'd5,
		SDone = 4'd6;
  
	FFT_Module uFFT(clk, FFT_rst, i_ce, i_sample, o_result, o_sync);
	
	ToneDetector_Module uTD(i_ce, TD_rst, TDenable, o_result, done, Tone);
	
	//write logic to check MSP status register and set CE accordingly, would have to stay low for the next three CC
	//probably would require another flag to check if the CE has already been high within the last three CC
	always @(negedge(clk)) begin //chip enable goes high on negedge, goes back low on negedge
		
		if(CEflag) i_ce <= 1'b1;
		else i_ce <= 1'b0;
		
	end //end always
	
	always @(posedge(clk) or negedge(reset_n)) begin
		if(!reset_n) begin
			myRegASICStatusmsb <= 8'h00;
			myRegASICStatuslsb <= 8'h00;
			myRegResultslsb <= 8'hXX;
			myRegResultsmsb <= 8'hXX;
			FFT_rst <= 1'b1; // FFT reset is active high
			TD_rst <= 1'b0; 
			TDenable <= 1'b0;
			i_sample <= 16'hXXXX;
			CEflag <= 1'b0;
			pState <= SInitial;
		end else begin
			case(pState) 
				SInitial:	begin
				
									myRegASICStatusmsb <= 8'h00;
									myRegASICStatuslsb <= 8'h00;
									myRegResultslsb <= 8'hXX;
									myRegResultsmsb <= 8'hXX;
									FFT_rst <= 1'b1;
									TD_rst <= 1'b0;
									TDenable <= 1'b0;
									i_sample <= 16'hXXXX;
									CEflag <= 1'b0;
									samplecount <= 0;
									clkcount <= 0;
									if(myRegMCUStatuslsb[2]==1'b1) pState <= SEnable; // Enable register (start)
									
								end
								
				SEnable:		begin
				
									FFT_rst <= 1'b0;
									TD_rst <= 1'b1;
									pState <= SWait;
									
								end
							
				SWait:		begin
				
									myRegASICStatuslsb[3] <= 1'b1;
									
									if(myRegMCUStatuslsb[3]==1'b1) pState <= SFFTIn;
									
								end
						
				SFFTIn:		begin
				
									myRegASICStatuslsb[3] <= 1'b1;
									
									if(myRegMCUStatuslsb[0]==1'b1) begin
										i_sample <= {myRegSampleInmsb, myRegSampleInlsb};
										samplecount <= samplecount + 1;
										clkcount <= 0;
										CEflag <= 1'b1;
										pState <= SFFTWait;
									end
									
								end
						
				SFFTWait:	begin
				
									myRegASICStatuslsb[3] <= 1'b0;
									CEflag <= 0;
									
									if(clkcount<2) 
										clkcount <= clkcount + 1;
									else if(myRegMCUStatuslsb[4]==1'b0 && samplecount<128) 
										pState <= SFFTIn;
									else if(samplecount==128) begin
										myRegASICStatuslsb[2] <= 1'b1;
										clkcount <= 0;
										CEflag <= 1'b1;
										pState <= SFFTOut;
									end
									
									// Sample error? Less than 128 samples sent, etc
									
								end
						
				SFFTOut:  	begin
				
									myRegASICStatuslsb[1] <= 1'b1;
									CEflag <= 0;
									
									if(clkcount==0) begin
										clkcount <= clkcount+1;
									end else if(clkcount<2) begin
										clkcount <= clkcount+1;
									end else begin
										clkcount <= 0;
										CEflag <= 1'b1;
									end
									
									if(o_sync) TDenable <= 1'b1;
									
									// Timeout error? osync never goes high
									
									if(done) begin
										myRegASICStatuslsb[0] <= 1'b1;
										myRegASICStatuslsb[1] <= 1'b0;
										{myRegResultsmsb,myRegResultslsb} <= Tone;
										pState <= SDone;
									end
									
								end
							
				SDone: 		begin
				
									if(myRegMCUStatuslsb[1]==1'b1) pState <= SInitial;
									
								end			 
			endcase
		end	
	end
	
endmodule
							