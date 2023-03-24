module Magnitude(clock, reset_n, enable, addr_real, addr_cplx, mag);

	parameter WIDTH = 16;
	parameter DEPTH = 256;
	parameter DEPTH_LOG = $clog2(DEPTH);
	
	input clock, reset_n, enable;
	input [DEPTH_LOG-1:0] addr_real, addr_cplx;
	output [WIDTH-1:0] mag;
	
	reg [WIDTH-1:0] rom [0:DEPTH-1];
	reg [15:0] data_real, data_cplx;
	
	initial begin
		$readmemh("MagLUT.hex", rom, 0, DEPTH-1);
	end
	
	assign mag = data_real + data_cplx;
	
	always @(posedge(clock) or negedge(reset_n)) begin
	
		if(!reset_n) begin
			
			data_real <= 0;
			data_cplx <= 0;
			
		end else begin
			
			if(enable) begin
			
				data_real <= rom[addr_real];
				data_cplx <= rom[addr_cplx];
				
			end
			
		end
	
	end
	
endmodule
