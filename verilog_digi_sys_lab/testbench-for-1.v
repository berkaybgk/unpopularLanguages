`timescale 1ns / 1ns
module testbench();

reg [1:0] aa, bb, ope, cc;
wire [1:0] ss;
wire yy;

parameter size = 4;
integer i, j, k, l;

operator variable_name(ss, aa, bb, ope);

initial begin
    $dumpfile("TimingDiagram.vcd");
    $dumpvars(0, ss, aa, bb, ope);
	
	for (i = 0; i < size; i ++) begin
		ope = i;
		for (j = 0; j < size; j ++) begin
			aa = j;
			for (k = 0; k < size; k ++) begin
				bb = k;
				for (l = 0; l < size; l ++) begin
					cc = l;
					#2;	
					end				
			end
		end
	end
	
    $finish;
end

endmodule