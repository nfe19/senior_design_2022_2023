`timescale 1ns/1ns
module Control_ModuleTB;

	reg clk, reset_n;
	reg [7:0] myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb;
	wire [7:0] myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb;
	
	parameter WIDTH = 16;
	parameter DEPTH = 128;
	parameter DEPTH_LOG = $clog2(DEPTH);
	//reg [DEPTH_LOG-1:0] index = 0;
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	integer index;
	
	Control_Module u0(clk, reset_n, myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb, 
						   myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb);
							
	always begin
		#20 clk <= ~clk;
	end
	
	initial begin
		
		$readmemh("Tone5.hex", mem, 0, DEPTH-1);
		
		clk <= 1'b0;
		reset_n <= 1'b0;
		myRegMCUStatuslsb <= 8'h00;
		myRegMCUStatusmsb <= 8'h00;
		myRegSampleInmsb <= 8'h00;
		myRegSampleInlsb <= 8'h00;
		
		#25 reset_n <= 1'b1;
		
		#5
		myRegMCUStatuslsb[2] <= 1'b1;
		
		if(myRegASICStatuslsb[2] == 1'b1 && myRegASICStatuslsb[3] == 1'b1) begin
			for(index=0; index<128; index=index+1) begin
				{myRegSampleInmsb, myRegSampleInlsb} <= mem[index];
				myRegMCUStatuslsb[2] <= 1'b0;
				while(myRegASICStatuslsb[3] == 1'b1);
				while(myRegASICStatuslsb[3] == 1'b0);
				
			end
		end
		
	end
