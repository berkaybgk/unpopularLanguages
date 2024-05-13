`timescale 1ns / 1ns
module testbench_32bit_mod3();

wire [1:0] s;
wire f;
reg [63:0] x;
reg e;
reg clk;

wire [7:0] i;

reg [63:0] values [3:0];

integer k;

source_32bit_mod3 variable_name(s, f, i, x, e, clk);

initial begin
    $dumpfile("TimingDiagram_32bit_mod3.vcd");
    $dumpvars(0, s, f, i, x, e, clk);
	
	values[0] = 117;
	values[1] = 425117;
	values[2] = 827425117;
	values[3] = 4294967295;
	
	for (k = 0; k < 4; k ++) begin
		e = 0;
		#40;
		x = values[k];
		e = 1;
		#400;
		$write("\n", s);
	end

    $finish;
end

always begin
	$write("%d", s);
	clk = 1;
	#15;
	clk = 0;
	#15;
end

endmodule