`timescale 1ns / 1ns
module operator(s, a, b, c, op);

input wire [1:0]a, b, c, op;
output reg [1:0]s;

parameter 	Op0 = 2'b00,
			Op1 = 2'b01,
			Op2 = 2'b10,
			Op3 = 2'b11;

always @ (a, b, c, op) begin

	if (op == Op0) begin
		s = ~((a & b) & c);
	end
	else if (op == Op1) begin
		s = ((a & b) & c);
	end
	else if (op == Op2) begin
		s = ~((a | b) | c);
	end
	else begin // else if (op == Op3) begin
		s = ((a | b) | c);
	end

end

endmodule


module comparator(y, s, d);

    input wire [1:0]s, d;
    output wire [0:0]y;

    //input wire [0:0] a = s[1];
    //input wire [0:0] b = s[0];
    //input wire [0:0] c = d[1];
    //input wire [0:0] d = d[0];

    wire [0:0] or1;
    wire [0:0] or2;
    wire [0:0] notd1;
    
    not(notd1,d[1]);
    nor(or2, d[1], d[0]);
    and(or1, s[0], notd1);

    or (y, s[1], or1, or2);

endmodule