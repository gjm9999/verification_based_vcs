module mem #(
    parameter DATA_WD   = 32              ,
    parameter DEPTH     = 512             ,
    parameter DELAY     = 3               ,
    parameter ADDR_WD   = $clog2(DEPTH)   ,
    parameter ERR_1BIT  = 0               ,
    parameter ERR_2BIT  = 1               ,
    parameter EOF       = 0
)(
    input                       clk                 ,
    input                       rst_n               ,
    input                       i_wr_en             ,
    input                       i_rd_en             ,
    input      [ADDR_WD -1:0]   i_addr              ,
    input      [DATA_WD -1:0]   i_data              ,

    output reg [DATA_WD -1:0]   o_rdata             ,
    output reg                  o_1bit_event        ,
    output reg                  o_2bit_event        ,
    output reg [ADDR_WD -1:0]   o_mem_err_addr_1bit ,
    output reg [ADDR_WD -1:0]   o_mem_err_addr_2bit
);

reg [DATA_WD -1:0] mem [DEPTH -1:0];
reg [DATA_WD -1:0] rdata_ff [DELAY:0];
reg [ADDR_WD -1:0] addr_ff [DELAY:0];
reg rd_en_ff [DELAY:0];

always @(posedge clk)begin
    if(~rst_n)begin
        integer i;
        for(i=0; i<DEPTH-1; i=i+1)begin
            mem[i] <= {DATA_WD{1'b1}};
        end
    end
    else if(i_wr_en)begin
        integer i;
        for(i=0; i<DEPTH-1; i=i+1)begin
            if(i == i_addr)begin
                mem[i] <= i_data;
            end
        end
    end
    else ;
end

always @(*)begin
    rdata_ff[0] = {DATA_WD{1'b1}};;
    if(i_rd_en)begin
        integer i;
        for(i=0; i<DEPTH; i=i+1)begin
            if(i == i_addr)begin
                rdata_ff[0] = mem[i_addr];
            end
        end
    end
end

genvar j;
generate
    for(j=1; j<=DELAY; j=j+1)begin
        always @(posedge clk)begin
            if(~rst_n)begin
                rdata_ff[j] <= {DATA_WD{1'b1}};
            end
            else begin
                rdata_ff[j] <= rdata_ff[j-1];
            end
        end
    end
endgenerate


assign o_rdata = rdata_ff[DELAY];

assign addr_ff[0] = i_addr;
assign o_mem_err_addr_1bit = addr_ff[DELAY];
assign o_mem_err_addr_2bit = addr_ff[DELAY];

genvar k;
generate
    for(k=1; k<=DELAY; k=k+1)begin
        always @(posedge clk)begin
            if(~rst_n)begin
                addr_ff[k] <= 0;
            end
            else begin
                addr_ff[k] <= addr_ff[k-1];
            end
        end
    end
endgenerate

assign rd_en_ff[0] = i_rd_en;
genvar m;
generate
    for(m=1; m<=DELAY; m=m+1)begin
        always @(posedge clk)begin
            if(~rst_n)begin
                rd_en_ff[m] <= 0;
            end
            else begin
                rd_en_ff[m] <= rd_en_ff[m-1];
            end
        end
    end
endgenerate

generate
    if(ERR_2BIT)begin
        always @* begin: ERR_INSERT_2BIT
            o_2bit_event = rd_en_ff[DELAY] & (addr_ff[DELAY][1] ^ rdata_ff[DELAY][1]);
            o_1bit_event = 0;
        end
    end
    else if(ERR_1BIT)begin
        always @* begin: ERR_INSERT_1BIT
            o_2bit_event = 0;
            o_1bit_event = rd_en_ff[DELAY] & (addr_ff[DELAY][0] ^ rdata_ff[DELAY][0]);
        end
    end
    else begin
        always @* begin:NO_ERR_INSERT
            o_2bit_event = 0;
            o_1bit_event = 0;
        end
    end
endgenerate

endmodule
