//////////////////////////////////////////////////////////////////////
////                                                              ////
//// registerInterface.v                                          ////
////                                                              ////
//// This file is part of the i2cSlave opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
//// You will need to modify this file to implement your 
//// interface.
//// Add your control and status bytes/bits to module inputs and outputs,
//// and also to the I2C read and write process blocks  
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
`timescale 1ns / 1ps


module registerInterface (
  clk,
  addr,
  dataIn,
  writeEn,
  dataOut,
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
  myRegResultslsb);
  
input clk;
input [7:0] addr;
input [7:0] dataIn;
input writeEn;
output [7:0] dataOut;
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

reg [7:0] dataOut;
reg [7:0] myRegDevAddresslsb = `I2C_ADDRESS;
reg [7:0] myRegDevAddressmsb = 8'h00;
reg [7:0] myRegManIDlsb = 8'h05; // Change this to define value
reg [7:0] myRegManIDmsb = 8'h06;
reg [7:0] myRegDevIDlsb = 8'h07;
reg [7:0] myRegDevIDmsb = 8'h08; // Up to here
reg [7:0] myRegMCUStatuslsb = 8'h00;
reg [7:0] myRegMCUStatusmsb = 8'h00;
reg [7:0] myRegSampleInlsb = 8'h00;
reg [7:0] myRegSampleInmsb = 8'h00;
wire [7:0] myRegASICStatuslsb;
wire [7:0] myRegASICStatusmsb;
wire [7:0] myRegResultslsb;
wire [7:0] myRegResultsmsb;
reg [7:0] dummyReg = 8'h00; // Dummy Reg for future register expansion

// Initialize Constant Registers

// --- I2C Read
always @(posedge clk) begin
  case (addr)
    8'h00: dataOut <= myRegDevAddressmsb;  
    8'h01: dataOut <= myRegDevAddresslsb;  
    8'h02: dataOut <= myRegManIDmsb;  
    8'h03: dataOut <= myRegManIDlsb;  
    8'h04: dataOut <= myRegDevIDmsb;  
    8'h05: dataOut <= myRegDevIDlsb;  
    8'h06: dataOut <= myRegMCUStatusmsb;  
    8'h07: dataOut <= myRegMCUStatuslsb;  
    8'h08: dataOut <= myRegASICStatusmsb;  
    8'h09: dataOut <= myRegASICStatuslsb;  
    8'h0A: dataOut <= myRegResultsmsb;  
    8'h0B: dataOut <= myRegResultslsb;
    8'h0C: dataOut <= myRegSampleInmsb;  
    8'h0D: dataOut <= myRegSampleInlsb; 	 
    default: dataOut <= dummyReg;
  endcase
end

// --- I2C Write
always @(posedge clk) begin

  if (writeEn == 1'b1) begin
    case (addr)
      8'h06: myRegMCUStatusmsb <= dataIn;  
      8'h07: myRegMCUStatuslsb <= dataIn;
      8'h0C: myRegSampleInmsb <= dataIn;
      8'h0D: myRegSampleInlsb <= dataIn;     
      default: dummyReg <= dataIn;      
    endcase
  end
end

endmodule