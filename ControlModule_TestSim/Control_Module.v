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
	reg [15:0] bins;
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
			myRegResultslsb <= 8'h00;
			myRegResultsmsb <= 8'h00;
			FFT_rst <= 1'b1; // FFT reset is active high
			TD_rst <= 1'b0; 
			TDenable <= 1'b0;
			i_sample <= 16'h0000;
			bins <= 16'h0000;
			CEflag <= 1'b0;
			pState <= SInitial;
		end else begin
			case(pState) 
				SInitial:	begin
									myRegASICStatusmsb <= 8'h00;
									myRegASICStatuslsb <= 8'h00;
									myRegResultslsb <= 8'h00;
									myRegResultsmsb <= 8'h00;
									FFT_rst <= 1'b1;
									TD_rst <= 1'b0;
									TDenable <= 1'b0;
									i_sample <= 16'h0000;
									bins <= 16'h0000;
									CEflag <= 1'b0;
									if(myRegMCUStatuslsb[2]==1'b1) pState <= SEnable; // Enable register (start)
								end
								
				SEnable:		begin
									FFT_rst <= 1'b0;
									TD_rst <= 1'b1;
									pState <= SWait;
								end
							
				SWait:		begin
									myRegASICStatuslsb[0] <= 1'b0;
									myRegASICStatuslsb[1] <= 1'b0;
									myRegASICStatuslsb[2] <= 1'b1;
									myRegASICStatuslsb[3] <= 1'b1;
									samplecount <= 0;
									clkcount <= 0;
									CEflag <= 1'b0;
									if(myRegMCUStatuslsb[0]==1'b1) pState <= SFFTIn;
								end
						
				SFFTIn:		begin
									//myRegASICStatuslsb[3] <= 1'b1;
									i_sample <= {myRegSampleInmsb, myRegSampleInlsb};
									samplecount <= samplecount + 1;
									clkcount <= 0;
									CEflag <= 1'b1;
									pState <= SFFTWait;
								end
						
				SFFTWait:	begin
									myRegASICStatuslsb[3] <= 1'b0;
									CEflag <= 0;
									if(clkcount<4) begin
										clkcount <= clkcount + 1;
									end else if(myRegMCUStatuslsb[0]==1'b1 && samplecount<128) begin 
										pState <= SFFTIn;
										myRegASICStatuslsb[3] <= 1'b1;//added
									end else if(samplecount==128) begin
										samplecount <= 0;
										pState <= SFFTOut;
									end
								end
						
				SFFTOut:  	begin
									myRegASICStatuslsb[1] <= 1'b1;
									myRegASICStatuslsb[2] <= 1'b0;
									//myRegASICStatuslsb[3] <= 1'b0;
									if(clkcount==0) begin
										CEflag <= 1'b1;
									end else if(clkcount<4) begin
										CEflag <= 1'b0;
									end else begin
										clkcount <= 0;
										CEflag <= 1'b1;
									end
									clkcount <= clkcount + 1;
									
									if(o_sync) TDenable <= 1'b1;
									
									if(done) begin
										{myRegResultsmsb,myRegResultslsb} <= Tone;
										myRegASICStatuslsb[0] <= 1'b1;
										myRegASICStatuslsb[1] <= 1'b0;
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
							