module ToneLUT(clock, reset_n, enable, lowReady, highReady, low_bin, high_bin, done, Tone);

	input clock, reset_n, enable, lowReady, highReady;
	input [5:0] low_bin, high_bin;
	output reg done;
	output reg [15:0] Tone;
	
	reg [2:0] lowFreq, highFreq;
	wire [15:0] keypad [0:3][0:3];
	
	localparam [15:0]
		Tone0 = 16'd0,
		Tone1 = 16'd1,
		Tone2 = 16'd2,
		Tone3 = 16'd3,
		Tone4 = 16'd4,
		Tone5 = 16'd5,
		Tone6 = 16'd6,
		Tone7 = 16'd7,
		Tone8 = 16'd8,
		Tone9 = 16'd9,
		ToneA = 16'd10,
		ToneB = 16'd11,
		ToneC = 16'd12,
		ToneD = 16'd13,
		Tone_x = 16'd14,
		Tone_p = 16'd15,
		NoTone = 16'd16; //Error or no-tone
		
	assign keypad[0][0] = Tone1;
	assign keypad[0][1] = Tone2;
	assign keypad[0][2] = Tone3;
	assign keypad[0][3] = ToneA;
	assign keypad[1][0] = Tone4;
	assign keypad[1][1] = Tone5;
	assign keypad[1][2] = Tone6;
	assign keypad[1][3] = ToneB;
	assign keypad[2][0] = Tone7;
	assign keypad[2][1] = Tone8;
	assign keypad[2][2] = Tone9;
	assign keypad[2][3] = ToneC;
	assign keypad[3][0] = Tone_x;
	assign keypad[3][1] = Tone0;
	assign keypad[3][2] = Tone_p;
	assign keypad[3][3] = ToneD;
	
	always @(low_bin) begin
	
		case(low_bin)
			6'd19: lowFreq = 3'd0;
			6'd21: lowFreq = 3'd1;
			6'd23: lowFreq = 3'd2;
			6'd25: lowFreq = 3'd3;
			default: lowFreq = 3'd4;
		endcase
		
	end
	
	always @(high_bin) begin
	
		case(high_bin)
			6'd32: highFreq = 3'd0;
			6'd35: highFreq = 3'd1;
			6'd39: highFreq = 3'd2;
			6'd43: highFreq = 3'd3;
			default: highFreq = 3'd4;
		endcase
		
	end
	
	always @(posedge(clock) or negedge(reset_n)) begin
	
		if(!reset_n) begin
		
			lowFreq <= 3'bXXX;
			highFreq <= 3'bXXX;
			done <= 1'b0;
			Tone <= 16'hXXXX;
		
		end else begin
		
			if(enable) begin
			
				if(lowReady && highReady) begin
				
					if(lowFreq == 4 || highFreq == 4) Tone <= NoTone;
					else Tone <= keypad[lowFreq][highFreq];
					
					done <= 1'b1;
					
				end 
				
			end
			
		end
		
	end

endmodule
