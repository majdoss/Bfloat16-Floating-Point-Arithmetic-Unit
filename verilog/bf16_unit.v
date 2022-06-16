
module bf16_unit(
	input wire clk,
	input wire reset,
	input wire [15:0] in1,
	input wire [15:0] in2,
	input wire [15:0] in3,
	input wire [4:0] funct5,
	output wire [15:0] result
);

	wire [15:0] s_in1;
	wire [15:0] s_in2;
	wire [15:0] s_in3;

	decoder dec(
		.in1(in1),
		.in2(in2),
		.in3(in3),
		.funct5(funct5),
		.out1(s_in1),
		.out2(s_in2),
		.out3(s_in3) );

	bf16_fmadd_fmsub fmadd_fmsub(
		.clk(clk),
		.reset(reset),
		.in1(s_in1),
		.in2(s_in2),
		.in3(s_in3),
		.funct5(funct5),
		.result(result) );

endmodule
