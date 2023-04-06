module DetectorLogic(input clk, reset_n, enable, 
							input [15:0] dataIn, bins_mag, 
							output [7:0] bins_real, bins_cplx, 
							output reg lowReady, highReady, 
							output reg [5:0] low_bin, high_bin);
	
	
	reg [5:0] tempLowBin, tempHighBin, counter = 6'h00;
	integer maxLow = 0, maxHigh = 0;
	
	`define magThreshold 300
	
	assign bins_real = dataIn[15:8];
	assign bins_cplx = dataIn[7:0];
	
	always @(posedge(clk) or negedge(reset_n)) begin
	
		if(!reset_n) begin
		
			low_bin <= 6'hXX;
			high_bin <= 6'hXX;
			lowReady = 1'b0;
			highReady = 1'b0;
			tempLowBin <= 6'h00;
			tempHighBin <= 6'h00;
			counter <= 6'h00;
			maxLow <= 0; 
			maxHigh <= 0;
		
		end else begin
		
			if(enable) begin
				
				counter <= counter + 6'd1;
				
				if(counter > 18 && counter < 26) begin
				
					if((bins_mag > maxLow) && (bins_mag > `magThreshold)) begin
						
						tempLowBin <= counter;
						maxLow <= bins_mag;
						
					end
				
				end
				else if(counter > 31 && counter < 44) begin
				
					if((bins_mag > maxHigh) && (bins_mag > `magThreshold)) begin
						
						tempHighBin <= counter;
						maxHigh <= bins_mag;
						
					end
				
				end
				else if(counter >= 44) begin
				
					low_bin <= tempLowBin;
					high_bin <= tempHighBin;
					lowReady = 1'b1;
					highReady = 1'b1;
				
				end
			
			end
		
		end
	
	end
	
endmodule
