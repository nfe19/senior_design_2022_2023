module Control_Module(input clk, reset_n, 
							 input [7:0] myRegDevAddresslsb, myRegDevAddressmsb, myRegManIDlsb, myRegManIDmsb, myRegMCUStatuslsb, myRegMCUStatusmsb, myRegSampleInlsb, myRegSampleInmsb, 
							 output [7:0] myRegASICStatuslsb, myRegASICStatusmsb, myRegResultslsb, myRegResultsmsb,
							 input [15:0] o_result, 
							 input o_sync, 
							 output [15:0] i_sample,
							 input done, 
							 input [15:0] Tone, 
							 output i_ce, TDenable,
							 output FFT_rst, TD_rst, I2C_rst);
											  
	ControlLogicFSM u_ControlLogicFSM (.clk(clk), 
												  .reset_n(reset_n), 
												  .myRegDevAddresslsb(myRegDevAddresslsb), 
												  .myRegDevAddressmsb(myRegDevAddressmsb), 
												  .myRegManIDlsb(myRegManIDlsb), 
												  .myRegManIDmsb(myRegManIDmsb), 
												  .myRegMCUStatuslsb(myRegMCUStatuslsb), 
												  .myRegMCUStatusmsb(myRegMCUStatusmsb), 
												  .myRegSampleInlsb(myRegSampleInlsb), 
												  .myRegSampleInmsb(myRegSampleInmsb), 
												  .myRegASICStatuslsb(myRegASICStatuslsb), 
												  .myRegASICStatusmsb(myRegASICStatusmsb), 
												  .myRegResultslsb(myRegResultslsb), 
												  .myRegResultsmsb(myRegResultsmsb),
												  .o_result(o_result), 
												  .o_sync(o_sync), 
												  .i_sample(i_sample),
												  .done(done), 
												  .Tone(Tone), 
												  .i_ce(i_ce), 
												  .TDenable(TDenable),
												  .FFT_rst(FFT_rst), 
												  .TD_rst(TD_rst), 
												  .I2C_rst(I2C_rst)
												  );
	
endmodule
							