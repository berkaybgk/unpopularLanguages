`timescale 1ns/1ns
module testbench();
wire [0:0] y;
wire [2:0] cs;
wire [2:0] ns;
reg x;
reg rst;
reg clk;
parameter inputseq = 64'b0001010100100100110110011100011000110010000111001100110100111011;
integer i;

source s(y, cs, ns, x, rst, clk);

initial begin
    $dumpfile("TimingDiagram_Moore.vcd");
    $dumpvars(0, y, cs, ns, x, rst, clk);
    
    rst = 1;
    //x = 0;
    #20;
    rst = 0;
    
    for (i=63; i>=0; i--) begin
        x = inputseq[i];
        #20;
	$write("%d", y);
    end
    
    $finish;
end

always begin	
	clk = 1;
	#10;
	clk = 0;
	#10;
end

endmodule