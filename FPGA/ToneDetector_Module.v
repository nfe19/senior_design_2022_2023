module ToneDetector_Module(input clk, reset_n, enable, 
									input [15:0] dataIn, 
									output done, 
									output [15:0] Tone);
	
	wire [15:0] bins_mag;
	wire [7:0] bins_real, bins_cplx;
	wire lowReady, highReady;
	wire [5:0] low_bin, high_bin;
	
	DetectorLogic u_DetectorLogic (
		.clk(clk), 
		.reset_n(reset_n), 
		.enable(enable), 
		.dataIn(dataIn), 
		.bins_mag(bins_mag), 
		.bins_real(bins_real), 
		.bins_cplx(bins_cplx), 
		.lowReady(lowReady), 
		.highReady(highReady), 
		.low_bin(low_bin), 
		.high_bin(high_bin)
	);
	
	Magnitude u_Magnitude (
		.clk(clk), 
		.reset_n(reset_n), 
		.enable(enable), 
		.addr_real(bins_real), 
		.addr_cplx(bins_cplx), 
		.mag(bins_mag)
	);
	
	ToneLUT u_ToneLUT (
		.clk(clk), 
		.reset_n(reset_n), 
		.enable(enable), 
		.lowReady(lowReady), 
		.highReady(highReady), 
		.low_bin(low_bin), 
		.high_bin(high_bin), 
		.done(done), 
		.Tone(Tone)
	);
	
endmodule
