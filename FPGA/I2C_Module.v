//////////////////////////////////////////////////////////////////////
////                                                              ////
//// i2cTop.v           
////                                                              ////
//// This file is part of the i2cSlave opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
//// You will need to modify this file to implement your 
//// interface.
////                                                              ////
//// To Do:                                                       ////
//// 
////                                                              ////
//// Author(s):                                                   ////
//// - Steve Fielding, sfielding@base2designs.com                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 Steve Fielding and OPENCORES.ORG          ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE. See the GNU Lesser General Public License for more  ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from <http://www.opencores.org/lgpl.shtml>                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
`include "I2CModule_defines.v"
module I2C_Module (
  clk,
  rst,
  sda,
  scl,
  myRegDevAddressmsb,
  myRegDevAddresslsb,
  myRegManIDmsb,
  myRegManIDlsb,
  myRegDevIDmsb,
  myRegDevIDlsb,
  myRegMCUStatusmsb,
  myRegMCUStatuslsb,
  myRegSampleInmsb,
  myRegSampleInlsb,
  myRegASICStatusmsb,
  myRegASICStatuslsb,
  myRegResultsmsb,
  myRegResultslsb,
  writeEnOut
);

	input clk;
	input rst;
	inout sda;
	input scl;
	output [7:0] myRegDevAddresslsb;
	output [7:0] myRegDevAddressmsb;
	output [7:0] myRegManIDlsb;
	output [7:0] myRegManIDmsb;
	output [7:0] myRegDevIDlsb;
	output [7:0] myRegDevIDmsb;
	output [7:0] myRegMCUStatuslsb;
	output [7:0] myRegMCUStatusmsb;
	output [7:0] myRegSampleInlsb;
	output [7:0] myRegSampleInmsb;
	input [7:0] myRegASICStatuslsb;
	input [7:0] myRegASICStatusmsb;
	input [7:0] myRegResultslsb;
	input [7:0] myRegResultsmsb;
	output writeEnOut;

	I2Cmain u_I2Cmain (
	  .clk(clk),
	  .rst(rst),
	  .sda(sda),
	  .scl(scl),
	  .myRegDevAddressmsb(myRegDevAddressmsb),
	  .myRegDevAddresslsb(myRegDevAddresslsb),
	  .myRegManIDmsb(myRegManIDmsb),
	  .myRegManIDlsb(myRegManIDlsb),
	  .myRegDevIDmsb(myRegDevIDmsb),
	  .myRegDevIDlsb(myRegDevIDlsb),
	  .myRegMCUStatusmsb(myRegMCUStatusmsb),
	  .myRegMCUStatuslsb(myRegMCUStatuslsb),
	  .myRegSampleInmsb(myRegSampleInmsb),
	  .myRegSampleInlsb(myRegSampleInlsb),
	  .myRegASICStatusmsb(myRegASICStatusmsb),
	  .myRegASICStatuslsb(myRegASICStatuslsb),
	  .myRegResultsmsb(myRegResultsmsb),
	  .myRegResultslsb(myRegResultslsb),
	  .writeEnOut(writeEnOut)
	);

endmodule


 
