`define DELAY(N, clk) begin \
	repeat(N) @(posedge clk);\
	#1ps;\
end

module testbench();

	timeunit 1ns;
	timeprecision 1ps;

    string tc_name;
    int tc_seed;
    bit clk, rst_n;
    
    initial $timeformat(-9,3,"ns",6);
    
    initial begin
        if(!$value$plusargs("tc_name=%s", tc_name)) $error("no tc_name!");
        else $display("tc name = %0s", tc_name);
        if(!$value$plusargs("ntb_random_seed=%0d", tc_seed)) $error("no tc_seed");
        else $display("tc seed = %0d", tc_seed);
    end
	
    initial forever #5ns clk = ~clk;
	initial begin
		`DELAY(30, clk);
		rst_n = 1'b1;
	end

    initial begin
        #100000ns $finish;
    end

    logic [1:0]wave_choise;
    initial begin
		`DELAY(50, clk);
        wave_choise = 2'd0;
        `DELAY(50, clk);
        wave_choise = 2'd2;
        `DELAY(100, clk);
        wave_choise = 2'd1;
        `DELAY(100, clk);
        wave_choise = 2'd2;
        `DELAY(55, clk);
        wave_choise = 2'd1;
        `DELAY(130, clk);
        wave_choise = 2'd0;
        `DELAY(200, clk);
        wave_choise = 2'd1;
    end

endmodule
