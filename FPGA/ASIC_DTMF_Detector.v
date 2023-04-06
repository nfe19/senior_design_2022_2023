module ASIC_DTMF_Detector(input clk, reset_n, scl,
								  inout sda);
								  
	ASICmain u_ASICmain (
		.clk(clk), 
		.reset_n(reset_n), 
		.scl(scl),
		.sda(sda)
	);
	
endmodule
