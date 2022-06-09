`ifndef PKT_IF_SV
`define PKT_IF_SV
`timescale 1ns/1ps
interface pkt_if #(
    parameter ADDR_WD = 7,
    parameter DATA_WD = 32
)(input clk, rst_n);
		
	logic [DATA_WD -1:0] data;
	logic [ADDR_WD -1:0] addr;
	logic		         vld;
	
	clocking drv @(posedge clk);
		//default input #1ps output #1ps;
		output 	data, addr;
		output	vld;
	endclocking : drv
	modport pkt_drv (clocking drv);
	
	clocking mon @(posedge clk);
		//default input #1ps;
		default input #1ps output #1ps;
		input 	data, addr;
		input	vld;
	endclocking : mon
	modport pkt_mon (clocking mon);
	
endinterface

//typedef virtual pkt_if.drv vdrv;
//typedef virtual pkt_if.mon vmon;

`endif
