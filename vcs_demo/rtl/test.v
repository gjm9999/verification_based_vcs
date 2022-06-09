module dffr#(
	parameter WIDTH = 1
)(
	input clk,
	input rst_n,
	input  [WIDTH -1:0]in,
	output [WIDTH -1:0]out
);
reg [WIDTH -1:0]out;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n) out <= 0;
	else       out <= in;
end
endmodule

module dffre#(
	parameter WIDTH = 1
)(
	input 				clk,
	input 				rst_n,
	input  [WIDTH -1:0]	d,
	input				en,
	output [WIDTH -1:0]	q
);
reg [WIDTH -1:0]q;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)  q <= {WIDTH{1'b0}};
	else if(en) q <= d;
end
endmodule

module dffse#(
	parameter WIDTH = 1,
	parameter SET   = {WIDTH{1'b1}}
)(
	input 				clk,
	input 				rst_n,
	input  [WIDTH -1:0]	d,
	input				en,
	output [WIDTH -1:0]	q
);
reg [WIDTH -1:0]q;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)  q <= SET;
	else if(en) q <= d;
end
endmodule

module triffic_light
    (
		input rst_n, //异位复位信号，低电平有效
        input clk, //时钟信号
        input pass_request,
		output wire[7:0]clock,
        output wire red,
		output wire yellow,
		output wire green
    );

wire 		 cnt_en;
wire         cnt_rerun_en;
wire [8 -1:0]cnt_d;
wire [8 -1:0]cnt_rerun_d;
wire [8 -1:0]cnt_q;

wire bypass = green & pass_request & (cnt_q>=10);
assign cnt_rerun_en = (cnt_q == 8'b0) | (green & bypass);
assign cnt_rerun_d  =  {8{red}}    & 8'd59 //red -> green
				     | {8{yellow}} & 8'd9  //yello -> red
				     | {8{green & !bypass}}  & 8'd4  //green -> yellow
				     | {8{bypass}} & 8'd9; //green -> green
assign cnt_d = cnt_rerun_en ? cnt_rerun_d : cnt_q - 8'd1;
assign clock = cnt_q;
dffse #(.WIDTH(8), .SET(8'd59)) u_cnt(
	.clk  (clk),
	.rst_n(rst_n),
	.d	  (cnt_d),
	.en   (1'b1),
	.q	  (cnt_q)
);

wire green_en;
wire green_d;
assign green_en = (red | green) & (cnt_q == 8'b0);
assign green_d  = ~green;
dffse #(.WIDTH(1), .SET(1'b1)) u_green(
	.clk  (clk),
	.rst_n(rst_n),
	.d	  (green_d),
	.en   (green_en),
	.q	  (green)
);

wire red_en;
wire red_d;
assign red_en = (red | yellow) & (cnt_q == 8'b0);
assign red_d  = ~red;
dffse #(.WIDTH(1), .SET(1'b0)) u_red(
	.clk  (clk),
	.rst_n(rst_n),
	.d	  (red_d),
	.en   (red_en),
	.q	  (red)
);

wire yellow_en;
wire yellow_d;
assign yellow_en = (green | yellow) & (cnt_q == 8'b0);
assign yellow_d  = ~yellow;
dffse #(.WIDTH(1), .SET(1'b0)) u_yellow(
	.clk  (clk),
	.rst_n(rst_n),
	.d	  (yellow_d),
	.en   (yellow_en),
	.q	  (yellow)
);

endmodule

























module sync_cell #(
	parameter SYNC_CYC = 2
)(
	input  clk,
	input  rst_n,
	input  in,
	output out
);
wire [SYNC_CYC :0]in_dff;
assign in_dff[0] = in;
assign out = in_dff[SYNC_CYC];

genvar i;
generate
    for(i=1; i<=SYNC_CYC; i=i+1)begin: inst_rtl
        dffr u_dffr[i](clk, rst_n, in_dff[i-1], in_dff[i]);
    end
endgenerate
endmodule

module mux(
	input 				clk_a	, 
	input 				clk_b	,   
	input 				arstn	,
	input				brstn   ,
	input		[3:0]	data_in	,
	input               data_en ,

	output reg  [3:0] 	dataout
);


wire data_en_sync;
wire data_en_sync_ff;
wire data_en_sync_ch;
sync_cell u_sync(clk_b, brstn, data_en, data_en_sync);
dffr u_data_en_sync_ff(clk_b, brstn, data_en_sync, data_en_sync_ff);

assign data_en_sync_ch = (data_en_sync == 1) && (data_en_sync_ff == 0);

always @(posedge clk_b or negedge brstn)begin
	if(~brstn)  			 dataout <= 0;
	else if(data_en_sync_ch) dataout <= data_in;
end

endmodule









module signal_generator(
	input clk,
	input rst_n,
	input [1:0] wave_choise,
	output reg [4:0]wave
	);

reg wave_choise_stg1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n) wave_choise_stg1 <= 1'b0;
	else       wave_choise_stg1 <= wave_choise;
end

wire square_en_stg0 = (wave_choise == 2'd0);
wire tooth_en_stg0  = (wave_choise == 2'd1);
wire triang_en_stg0 = (wave_choise == 2'd2);
wire square_en_stg1 = (wave_choise_stg1 == 2'd0);
wire tooth_en_stg1  = (wave_choise_stg1 == 2'd1);
wire triang_en_stg1 = (wave_choise_stg1 == 2'd2);

//square
reg [3:0]square_cnt;
wire square_in_en  = square_en_stg0 && (~square_en_stg1);
wire square_ctn_en = square_en_stg0 && square_en_stg1;
wire square_h_en   = (square_cnt >= 4'd8);

wire[4:0]wave_square_d = ({5{square_h_en}}  & 5'd31) |
					      ({5{~square_h_en}} & 5'd0) ;

always @(posedge clk or negedge rst_n)begin
	if(~rst_n) square_cnt <= 4'b0;
	else begin
		if(square_in_en)begin
			square_cnt <= 4'b0;
		end
		else if(square_ctn_en)begin
			square_cnt <= square_cnt + 4'd1;
		end
    end
end

//tooth
wire tooth_in_en  = tooth_en_stg0 && (~tooth_en_stg1);
wire tooth_ctn_en = tooth_en_stg0 && tooth_en_stg1;

wire [4:0]wave_tooth_d = tooth_in_en ? 5'd0 :
						 (tooth_ctn_en & (wave == 5'd31)) ? 5'd0 :
						 tooth_ctn_en ? wave + 5'd1 : wave;

//triang
reg triang_right_en;
wire triang_in_en  = triang_en_stg0 && (~triang_en_stg1);
wire triang_ctn_en = triang_en_stg0 && triang_en_stg1;
wire [4:0]wave_triang_d = triang_right_en ? wave - 5'd1 : wave + 5'd1;

always @(posedge clk or negedge rst_n)begin
	if(~rst_n) triang_right_en <= 1'b0;
	else begin
		if(tooth_en_stg0)begin
			triang_right_en <= 1'b1;
		end
		else if(square_en_stg0 & wave_square_d==5'd0)begin
			triang_right_en <= 1'b0;
		end
		else if(square_en_stg0 & wave_square_d!=5'd0)begin
			triang_right_en <= 1'b1;
		end
		else if(triang_en_stg0 && (wave_triang_d == 5'd0 || wave_triang_d == 5'd31))begin
			triang_right_en <= ~triang_right_en;
		end
	end
end

//gen wave
always @(posedge clk or negedge rst_n)begin
	if(~rst_n) wave <= 1'b0;
	else begin
		if(square_en_stg0)begin
			wave <= wave_square_d;
		end
		else if(tooth_en_stg0)begin
			wave <= wave_tooth_d;
		end
		else if(triang_en_stg0)begin
			wave <= wave_triang_d;
		end
	end
end

endmodule

`timescale 1ns/1ns
/**********************************RAM************************************/
module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8)(
	 input wclk
	,input wenc
	,input [$clog2(DEPTH)-1:0] waddr  //深度对2取对数，得到地址的位宽。
	,input [WIDTH-1:0] wdata      	//数据写入
	,input rclk
	,input renc
	,input [$clog2(DEPTH)-1:0] raddr  //深度对2取对数，得到地址的位宽。
	,output reg [WIDTH-1:0] rdata 		//数据输出
);

reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

always @(posedge wclk) begin
	if(wenc)
		RAM_MEM[waddr] <= wdata;
end 

always @(posedge rclk) begin
	if(renc)
		rdata <= RAM_MEM[raddr];
end 

endmodule  

/**********************************SFIFO************************************/
module sfifo#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					clk		, 
	input 					rst_n	,
	input 					winc	,
	input 			 		rinc	,
	input 		[WIDTH-1:0]	wdata	,

	output 				wfull	,
	output 				rempty	,
	output wire [WIDTH-1:0]	rdata
);

localparam DP_WD = $clog2(DEPTH);

reg  [DP_WD   :0]waddr;
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
assign wenc = winc & (!wfull);
assign waddr_d_h = (waddr[DP_WD-1:0] == DEPTH-1) ? ~waddr[DP_WD] : waddr[DP_WD];
assign waddr_d_l = (waddr[DP_WD-1:0] == DEPTH-1) ? 0 : waddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    waddr <= 0;
	else if(wenc) waddr <= {waddr_d_h, waddr_d_l};
end

reg  [DP_WD   :0]raddr;
wire             renc;
wire             raddr_d_h;
wire [DP_WD -1:0]raddr_d_l;
assign renc = rinc & (!rempty);
assign raddr_d_h = (raddr[DP_WD-1:0] == DEPTH-1) ? ~raddr[DP_WD] : raddr[DP_WD];
assign raddr_d_l = (raddr[DP_WD-1:0] == DEPTH-1) ? 0 : raddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    raddr <= 0;
	else if(renc) raddr <= {raddr_d_h, raddr_d_l};
end

wire [DP_WD :0]fifo_cnt = (waddr[DP_WD] == raddr[DP_WD]) ? waddr[DP_WD-1:0] - raddr[DP_WD-1:0]:
				          (waddr[DP_WD-1:0] + DEPTH - raddr[DP_WD-1:0]);
wire [DP_WD :0]fifo_cnt_d = (waddr_d_h == raddr_d_h) ? waddr_d_l[DP_WD-1:0] - raddr_d_l[DP_WD-1:0]:
				            (waddr_d_l[DP_WD-1:0] + DEPTH - raddr_d_l[DP_WD-1:0]);

wire rempty = (fifo_cnt == 0);
//always @(posedge clk or negedge rst_n)begin
//	if(~rst_n)    rempty <= 0;
//	else if(renc)         rempty <= rempty_d;
//end

wire wfull = (fifo_cnt == DEPTH);
//always @(posedge clk or negedge rst_n)begin	if(~rst_n)    wfull <= 0;
//	if(~rst_n)    wfull <= 0;
//	else if(wenc)         wfull <= wfull_d;
//end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH))
u_ram (
	.wclk	(clk),
	.wenc	(wenc),
	.waddr	(waddr),
	.wdata	(wdata),
	.rclk	(clk),
	.renc	(renc),
	.raddr	(raddr),
	.rdata	(rdata)
);

endmodule
