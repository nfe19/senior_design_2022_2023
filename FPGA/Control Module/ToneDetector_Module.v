module ToneDetector_Module(clock, reset, enable, bins, busy, done, error, Tone);

	input clock, reset, enable;
	input [15:0] bins;
	output busy, done, error;
	output [15:0] Tone;
	
	wire [7:0] bins_real, bins_cplx;
	wire [15:0] bins_mag;
	reg [5:0] low_bin, high_bin, tempLowBin, tempHighBin;
	integer counter = 0, maxLow = 0, maxHigh = 0;
	
	assign bins_real = bins[15:8];
	assign bins_cplx = bins[7:0];
	
	Magnitude u0(clock, reset, enable, bins_real, bins_cplx, bins_mag);
	ToneLUT u1(clock, reset, enable, low_bin, high_bin, busy, done, error, Tone);
	
	always @(posedge(clock) or posedge(reset)) begin
	
		if(reset) begin
		
			tempLowBin <= 0;
			tempHighBin <= 0;
			counter <= 0;
			maxLow <= 0; 
			maxHigh <= 0;
		
		end else begin
		
			if(enable) begin
				
				counter <= counter + 1;
				
				if(counter > 18 && counter < 26) begin
				
					if(bins_mag > maxLow) begin
						
						tempLowBin <= counter;
						maxLow <= bins_mag;
						
					end
				
				end
				else if(counter > 31 && counter < 44) begin
				
					if(bins_mag > maxHigh) begin
						
						tempHighBin <= counter;
						maxHigh <= bins_mag;
						
					end
				
				end
				else if(counter >= 44) begin
				
					low_bin <= tempLowBin;
					high_bin <= tempHighBin;
				
				end
			
			end
		
		end
	
	end
	
endmodule