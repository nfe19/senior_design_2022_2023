module ToneLUT(clock, reset, enable, low_bin, high_bin, busy, done, error, Tone);

	input clock, reset, enable;
	input [5:0] low_bin, high_bin;
	output reg busy, done, error;
	output reg [15:0] Tone;
	
	integer lowFreq, highFreq;
	reg [15:0] keypad [0:3][0:3];
	reg lowReady = 0, highReady = 0;
	
	localparam [3:0]
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
		NoTone = 16'hFFFF; //Error or no-tone
		
	initial begin
	
		keypad = '{'{Tone1,Tone2,Tone3,ToneA}, 
					  '{Tone4,Tone5,Tone6,ToneB}, 
					  '{Tone7,Tone8,Tone9,ToneC}, 
					  '{Tone_x,Tone0,Tone_p,ToneD}};
		
	end
	
	always @(low_bin) begin
	
		case(low_bin)
			6'd19: lowFreq = 0;
			6'd21: lowFreq = 1;
			6'd23: lowFreq = 2;
			6'd25: lowFreq = 3;
			default: lowFreq = 4;
		endcase
		
		lowReady = 1;
		
	end
	
	always @(high_bin) begin
	
		case(high_bin)
			6'd32: highFreq = 0;
			6'd35: highFreq = 1;
			6'd39: highFreq = 2;
			6'd43: highFreq = 3;
			default: highFreq = 4;
		endcase
		
		highReady = 1;
		
	end
	
	always @(posedge(clock) or posedge(reset)) begin
	
		if(reset) begin
		
			busy <= 0;
			done <= 0;
			error <= 0;
		
		end else begin
		
			if(enable) begin
			
				if(lowReady && highReady) begin
				
					if(lowFreq == 4 || highFreq == 4) begin
					
						error <= 1;
						Tone <= NoTone;
						
					end else Tone <= keypad[lowFreq][highFreq];
					
					busy <= 0;
					done <= 1;
					
				end else busy <= 1;
				
			end
			
		end
		
	end

endmodule