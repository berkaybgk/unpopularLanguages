`timescale 1ns / 1ns
module testbench();

reg [1:0] ss, dd;
wire yy;

parameter size = 3;
integer i, j;

comparator variable_name(yy, ss, dd);

initial begin
    $dumpfile("TimingDiagram2.vcd");
    $dumpvars(0, yy, ss, dd);
	
	for (i = 0; i < size; i ++) begin
		ss = i;
		for (j = 0; j < size; j ++) begin
			dd = j;
			#2;	
		end
	end
	
    $finish;
end

endmodule