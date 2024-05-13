`timescale 1ns / 1ns

module source_64bit_mod3(s, f, i, x, e, clk);

output reg [1:0] s;
output reg f;
input wire [63:0] x;
input wire e;
input wire clk;

// Intermediate register (does not have to be output or input)
output reg [7:0] i;

always@(posedge clk) begin
	// Do not process until the unit is enabled
	if(e == 0) begin
		i = 0;
		f = 0;
	end
	else begin
		// Clear previous result
		if (i == 0) begin
			s = 0;
		end

		// Set flag bit ready
		if (i == 64) begin
			f = 1;
		end
		// Do the computation
		else begin
			// Main computation unit is here with delay
			#15;
			s = ((x[i + 1] << 1) + x[i] + (s[1] << 1) + s[0]) % 3;
			// Increment index variable
			i = i + 2;
		end
	end
end

endmodule