
module mux_funct5(
	input [15:0] mult_add_sub,
	input [15:0] macc,
	//input [15:0] conv,
	input [4:0] funct5,
	output reg [15:0] result
);

  	always @(*) begin
		case(funct5)
			5'b00000,5'b00001,5'b00010,5'b00101,5'b00100 : result <= mult_add_sub;
			//5'b00011 : result <= conv;
			5'b00111 : result <= macc;
			default : result <= {16{1'b0}};
		endcase
  	end

endmodule
