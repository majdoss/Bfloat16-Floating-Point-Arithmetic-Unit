
module decoder(
	input wire [15:0] in1,
	input wire [15:0] in2,
	input wire [15:0] in3,
	input wire [4:0] funct5,
	output reg [15:0] out1,
	output reg [15:0] out2,
	output reg [15:0] out3
);

	always @(*) begin
		case(funct5)
			5'b00000,5'b00001 : begin
			  out1 <= in1;
			  out2 <= 16'b0011111110000000;
			  out3 <= in2;
			end
			5'b00010 : begin
			  out1 <= in1;
			  out2 <= in2;
			  out3 <= 16'b0000000000000000;
			end
			5'b00100,5'b00101 : begin
			  out1 <= in1;
			  out2 <= in2;
			  out3 <= in3;
			end
			default : begin
			  out1 <= 16'b0000000000000000;
			  out2 <= 16'b0000000000000000;
			  out3 <= 16'b0000000000000000;
			end
		endcase
	end

endmodule
