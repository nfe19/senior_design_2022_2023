module FFT_Module(i_clk,i_reset,i_ce,i_sample,o_result,o_sync);
  
  parameter	IWIDTH = 8;
  parameter OWIDTH = 8;
  input wire i_clk, i_reset, i_ce;
  input wire [(2*IWIDTH-1):0]	i_sample;
  output  [(2*OWIDTH-1):0]	 o_result;
  output  o_sync;
  
  
  FFTmain u_FFTmain (.i_clk(i_clk), 
							.i_reset(i_reset), 
							.i_ce(i_ce), 
							.i_sample(i_sample), 
							.o_result(o_result), 
							.o_sync(o_sync)
							);
  
endmodule