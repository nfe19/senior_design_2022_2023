`timescale 1ns/1ns
module Control_ModuleTB;

	reg clk, reset_n;
	reg [7:0] myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb;
	wire [7:0] myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb;
	
	parameter WIDTH = 16;
	parameter DEPTH = 128;
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	integer index = 0;
	
	parameter NoTone = 16;
	reg [15:0] toneDetected;
	integer toneCount = 0, audioIndex = 0, prevTone = NoTone;
	string Audio [0:19] = '{"Tone5.hex", "Tone5.hex", "Tone5.hex", "NoTone.hex", "NoTone.hex",
									"Tone4.hex", "Tone4.hex", "NoTone.hex", "NoTone.hex", "NoTone.hex",
									"Tone3.hex", "Tone3.hex", "Tone3.hex", "Tone3.hex", "NoTone.hex",
									"Tone2.hex", "NoTone.hex", "NoTone.hex", "NoTone.hex", "Tone1.hex"};
	
	parameter PASS = 5;
	reg [0:PASS-1][15:0] Password;
	
	Control_Module u0(clk, reset_n, myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb, 
						   myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb);
							
	always begin
		#20 clk <= ~clk;
	end
	
	initial begin
		
		clk = 1'b0;
		reset_n = 1'b0;
		myRegMCUStatuslsb = 8'h00;
		myRegMCUStatusmsb = 8'h00;
		myRegSampleInmsb = 8'h00;
		myRegSampleInlsb = 8'h00;
		
		#25 reset_n = 1'b1;
		
		while(toneCount != PASS) begin

			myRegMCUStatuslsb = 8'h00;
			myRegMCUStatusmsb = 8'h00;
			myRegSampleInmsb = 8'h00;
			myRegSampleInlsb = 8'h00;
			myRegMCUStatuslsb[2] = 1'b1;
			//toneDetected = 0;
			#2500;
			
			$readmemh(Audio[audioIndex], mem, 0, DEPTH-1);
			#1563; // Delay approx amount of time necessary to acquire 128 samples
			
			myRegMCUStatuslsb[3] = 1'b1;
			#2500;
			
			while(myRegASICStatuslsb[0] != 1'b1) begin
			
				while(myRegASICStatuslsb[2] != 1'b1) begin
			
					if(myRegASICStatuslsb[3] == 1'b1) begin
						
						{myRegSampleInmsb, myRegSampleInlsb} = mem[index];
						myRegMCUStatuslsb[0] = 1'b1;
						myRegMCUStatuslsb[4] = 1'b1;
						index = index + 1;
						#2500;
					
					end
					
					myRegMCUStatuslsb[0] = 1'b0;
					myRegMCUStatuslsb[4] = 1'b0;
					#2500;
			
				end
				
				while(myRegASICStatuslsb[1] == 1'b1) begin
				
					// Sample more audio
					#2500;
				
				end
				
				//#2500;
			
			end
			
			#20 toneDetected = {myRegResultsmsb, myRegResultslsb};
			#2500;
			
			myRegMCUStatuslsb[1] = 1'b1;
			myRegMCUStatuslsb[2] = 1'b0;
			myRegMCUStatuslsb[3] = 1'b0;
			#2500;
			
			audioIndex = audioIndex + 1;
			
			if(toneDetected != NoTone && toneDetected != prevTone) begin
			
				Password[toneCount] = toneDetected;
				toneCount = toneCount + 1;
				
			end
			
			prevTone = toneDetected;
			
			index = 0;
		
			#2500;
			
		end
		
		if(Password[0]==5 && Password[1]==4 && 
			Password[2]==3 && Password[3]==2 && Password[4]==1) begin
		
			$display("Welcome!");
			
		end else begin
		
			$display("Incorrect Password");
			$display("Press button to try again");
			
		end
		
		#250000;
		
		$stop;
		
	end
	
endmodule
