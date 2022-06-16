
module bf16_SIMD_MACC
# (parameter G = 6) (
    input clk,
    input reset,
    input [15:0] in1,
    input [15:0] in2,
    input  [15:0] in3,
    input  [15:0] in4,
    input  [15:0] in5,
    input  [15:0] in6,
    input  [15:0] in7,
    input  [15:0] in8,
    input  [15:0] in9,
    input  [15:0] in10,
    input  [15:0] in11,
    input  [15:0] in12,
    input  [15:0] in13,
    input  [15:0] in14,
    input  [15:0] in15,
    input  [15:0] in16,
    input  [15:0] in17,
    input  [15:0] in18,
    output wire [15:0] result
);

    wire [G + 15:0] m1_alu_m;
    wire [31:0] m1_exp_m;
    wire m1_s_m;
    wire m1_exc_flag;
    wire m1_err_code;
    wire [G + 15:0] m2_alu_m;
    wire [31:0] m2_exp_m;
    wire m2_s_m;
    wire m2_exc_flag;
    wire m2_err_code;
    wire [G + 15:0] m3_alu_m;
    wire [31:0] m3_exp_m;
    wire m3_s_m;
    wire m3_exc_flag;
    wire m3_err_code;
    wire [G + 15:0] m4_alu_m;
    wire [31:0] m4_exp_m;
    wire m4_s_m;
    wire m4_exc_flag;
    wire m4_err_code;
    wire [G + 15:0] m5_alu_m;
    wire [31:0] m5_exp_m;
    wire m5_s_m;
    wire m5_exc_flag;
    wire m5_err_code;
    wire [G + 15:0] m6_alu_m;
    wire [31:0] m6_exp_m;
    wire m6_s_m;
    wire m6_exc_flag;
    wire m6_err_code;
    wire [G + 15:0] m7_alu_m;
    wire [31:0] m7_exp_m;
    wire m7_s_m;
    wire m7_exc_flag;
    wire m7_err_code;
    wire [G + 15:0] m8_alu_m;
    wire [31:0] m8_exp_m;
    wire m8_s_m;
    wire m8_exc_flag;
    wire m8_err_code;
    wire [G + 15:0] m9_alu_m;
    wire [31:0] m9_exp_m;
    wire m9_s_m;
    wire m9_exc_flag;
    wire m9_err_code;
    wire [G + 15:0] a1_alu_r;
    wire [31:0] a1_exp_r;
    wire a1_s_r;
    wire a1_exc_flag;
    wire a1_err_code;
    wire [G + 15:0] a2_alu_r;
    wire [31:0] a2_exp_r;
    wire a2_s_r;
    wire a2_exc_flag;
    wire a2_err_code;
    wire [G + 15:0] a3_alu_r;
    wire [31:0] a3_exp_r;
    wire a3_s_r;
    wire a3_exc_flag;
    wire a3_err_code;
    wire [G + 15:0] a4_alu_r;
    wire [31:0] a4_exp_r;
    wire a4_s_r;
    wire a4_exc_flag;
    wire a4_err_code;
    wire [G + 15:0] a5_alu_r;
    wire [31:0] a5_exp_r;
    wire a5_s_r;
    wire a5_exc_flag;
    wire a5_err_code;
    wire [G + 15:0] a6_alu_r;
    wire [31:0] a6_exp_r;
    wire a6_s_r;
    wire a6_exc_flag;
    wire a6_err_code;
    wire [G + 15:0] a7_alu_r;
    wire [31:0] a7_exp_r;
    wire a7_s_r;
    wire a7_exc_flag;
    wire a7_err_code;
	
    reg [15:0] p1_in17;
    reg [15:0] p1_in18;
    reg [15:0] p2_in17;
    reg [15:0] p2_in18;
    reg [15:0] p3_in17;
    reg [15:0] p3_in18;
    reg [15:0] p4_in17;
    reg [15:0] p4_in18;
    reg [15:0] p5_in17;
    reg [15:0] p5_in18;
    reg [15:0] p6_in17;
    reg [15:0] p6_in18;
    reg [15:0] p7_in17;
    reg [15:0] p7_in18;
    reg [15:0] p8_in17;
    reg [15:0] p8_in18;
    reg [15:0] p9_in17;
    reg [15:0] p9_in18;
    reg [15:0] p10_in17;
    reg [15:0] p10_in18;
	
    wire [15:0] in17_m;
    wire [15:0] in18_m;
	
    always @ (posedge clk) begin
        if (reset == 0) begin
            p1_in17 <= 0;
            p1_in18 <= 0;
            p2_in17 <= 0;
            p2_in18 <= 0;
            p3_in17 <= 0;
            p3_in18 <= 0;
            p4_in17 <= 0;
            p4_in18 <= 0;
            p5_in17 <= 0;
            p5_in18 <= 0;
            p6_in17 <= 0;
            p6_in18 <= 0;
            p7_in17 <= 0;
            p7_in18 <= 0;
            p8_in17 <= 0;
            p8_in18 <= 0;
            p9_in17 <= 0;
            p9_in18 <= 0;
            p10_in17 <= 0;
            p10_in18 <= 0;
        end else begin
            p1_in17 <= in17;
            p1_in18 <= in18;
            p2_in17 <= p1_in17;
            p2_in18 <= p1_in18;
            p3_in17 <= p2_in17;
            p3_in18 <= p2_in18;
            p4_in17 <= p3_in17;
            p4_in18 <= p3_in18;
            p5_in17 <= p4_in17;
            p5_in18 <= p4_in18;
            p6_in17 <= p5_in17;
            p6_in18 <= p5_in18;
            p7_in17 <= p6_in17;
            p7_in18 <= p6_in18;
            p8_in17 <= p7_in17;
            p8_in18 <= p7_in18;
            p9_in17 <= p8_in17;
            p9_in18 <= p8_in18;
            p10_in17 <= p9_in17;
            p10_in18 <= p9_in18;
        end
    end
	
    assign in17_m = p10_in17;
    assign in18_m = p10_in18;

    bf16_mult_leaf MULT1(
        .clk(clk),
        .reset(reset),
        .in1(in1),
        .in2(in2),
        .out_alu_m(m1_alu_m),
        .out_exp_m(m1_exp_m),
        .out_s_m(m1_s_m),
        .out_exc_flag(m1_exc_flag),
        .out_err_code(m1_err_code));

    bf16_mult_leaf MULT2(
        .clk(clk),
        .reset(reset),
        .in1(in3),
        .in2(in4),
        .out_alu_m(m2_alu_m),
        .out_exp_m(m2_exp_m),
        .out_s_m(m2_s_m),
        .out_exc_flag(m2_exc_flag),
        .out_err_code(m2_err_code));

    bf16_mult_leaf MULT3(
        .clk(clk),
        .reset(reset),
        .in1(in5),
        .in2(in6),
        .out_alu_m(m3_alu_m),
        .out_exp_m(m3_exp_m),
        .out_s_m(m3_s_m),
        .out_exc_flag(m3_exc_flag),
        .out_err_code(m3_err_code));

    bf16_mult_leaf MULT4(
        .clk(clk),
        .reset(reset),
        .in1(in7),
        .in2(in8),
        .out_alu_m(m4_alu_m),
        .out_exp_m(m4_exp_m),
        .out_s_m(m4_s_m),
        .out_exc_flag(m4_exc_flag),
        .out_err_code(m4_err_code));

    bf16_mult_leaf MULT5(
        .clk(clk),
        .reset(reset),
        .in1(in9),
        .in2(in10),
        .out_alu_m(m5_alu_m),
        .out_exp_m(m5_exp_m),
        .out_s_m(m5_s_m),
        .out_exc_flag(m5_exc_flag),
        .out_err_code(m5_err_code));

    bf16_mult_leaf MULT6(
        .clk(clk),
        .reset(reset),
        .in1(in11),
        .in2(in12),
        .out_alu_m(m6_alu_m),
        .out_exp_m(m6_exp_m),
        .out_s_m(m6_s_m),
        .out_exc_flag(m6_exc_flag),
        .out_err_code(m6_err_code));

    bf16_mult_leaf MULT7(
        .clk(clk),
        .reset(reset),
        .in1(in13),
        .in2(in14),
        .out_alu_m(m7_alu_m),
        .out_exp_m(m7_exp_m),
        .out_s_m(m7_s_m),
        .out_exc_flag(m7_exc_flag),
        .out_err_code(m7_err_code));

    bf16_mult_leaf MULT8(
        .clk(clk),
        .reset(reset),
        .in1(in15),
        .in2(in16),
        .out_alu_m(m8_alu_m),
        .out_exp_m(m8_exp_m),
        .out_s_m(m8_s_m),
        .out_exc_flag(m8_exc_flag),
        .out_err_code(m8_err_code));
      
    bf16_mult_leaf MULT9(
        .clk(clk),
        .reset(reset),
        .in1(in17_m),
        .in2(in18_m),
        .out_alu_m(m9_alu_m),
        .out_exp_m(m9_exp_m),
        .out_s_m(m9_s_m),
        .out_exc_flag(m9_exc_flag),
        .out_err_code(m9_err_code));

    bf16_add_branch ADD1(
        .clk(clk),
        .reset(reset),
        .in1(m1_alu_m),
        .exp_1(m1_exp_m),
        .s_in1(m1_s_m),
        .exc_flag_1(m1_exc_flag),
        .err_code_1(m1_err_code),
        .in2(m2_alu_m),
        .exp_2(m2_exp_m),
        .s_in2(m2_s_m),
        .exc_flag_2(m2_exc_flag),
        .err_code_2(m2_err_code),
        .out_alu_r(a1_alu_r),
        .out_exp_r(a1_exp_r),
        .out_s_r(a1_s_r),
        .out_exc_flag(a1_exc_flag),
        .out_err_code(a1_err_code));

    bf16_add_branch ADD2(
        .clk(clk),
        .reset(reset),
        .in1(m3_alu_m),
        .exp_1(m3_exp_m),
        .s_in1(m3_s_m),
        .exc_flag_1(m3_exc_flag),
        .err_code_1(m3_err_code),
        .in2(m4_alu_m),
        .exp_2(m4_exp_m),
        .s_in2(m4_s_m),
        .exc_flag_2(m4_exc_flag),
        .err_code_2(m4_err_code),
        .out_alu_r(a2_alu_r),
        .out_exp_r(a2_exp_r),
        .out_s_r(a2_s_r),
        .out_exc_flag(a2_exc_flag),
        .out_err_code(a2_err_code));

    bf16_add_branch ADD3(
        .clk(clk),
        .reset(reset),
        .in1(m5_alu_m),
        .exp_1(m5_exp_m),
        .s_in1(m5_s_m),
        .exc_flag_1(m5_exc_flag),
        .err_code_1(m5_err_code),
        .in2(m6_alu_m),
        .exp_2(m6_exp_m),
        .s_in2(m6_s_m),
        .exc_flag_2(m6_exc_flag),
        .err_code_2(m6_err_code),
        .out_alu_r(a3_alu_r),
        .out_exp_r(a3_exp_r),
        .out_s_r(a3_s_r),
        .out_exc_flag(a3_exc_flag),
        .out_err_code(a3_err_code));

    bf16_add_branch ADD4(
        .clk(clk),
        .reset(reset),
        .in1(m7_alu_m),
        .exp_1(m7_exp_m),
        .s_in1(m7_s_m),
        .exc_flag_1(m7_exc_flag),
        .err_code_1(m7_err_code),
        .in2(m8_alu_m),
        .exp_2(m8_exp_m),
        .s_in2(m8_s_m),
        .exc_flag_2(m8_exc_flag),
        .err_code_2(m8_err_code),
        .out_alu_r(a4_alu_r),
        .out_exp_r(a4_exp_r),
        .out_s_r(a4_s_r),
        .out_exc_flag(a4_exc_flag),
        .out_err_code(a4_err_code));

    bf16_add_branch ADD5(
        .clk(clk),
        .reset(reset),
        .in1(a1_alu_r),
        .exp_1(a1_exp_r),
        .s_in1(a1_s_r),
        .exc_flag_1(a1_exc_flag),
        .err_code_1(a1_err_code),
        .in2(a2_alu_r),
        .exp_2(a2_exp_r),
        .s_in2(a2_s_r),
        .exc_flag_2(a2_exc_flag),
        .err_code_2(a2_err_code),
        .out_alu_r(a5_alu_r),
        .out_exp_r(a5_exp_r),
        .out_s_r(a5_s_r),
        .out_exc_flag(a5_exc_flag),
        .out_err_code(a5_err_code));

    bf16_add_branch ADD6(
        .clk(clk),
        .reset(reset),
        .in1(a3_alu_r),
        .exp_1(a3_exp_r),
        .s_in1(a3_s_r),
        .exc_flag_1(a3_exc_flag),
        .err_code_1(a3_err_code),
        .in2(a4_alu_r),
        .exp_2(a4_exp_r),
        .s_in2(a4_s_r),
        .exc_flag_2(a4_exc_flag),
        .err_code_2(a4_err_code),
        .out_alu_r(a6_alu_r),
        .out_exp_r(a6_exp_r),
        .out_s_r(a6_s_r),
        .out_exc_flag(a6_exc_flag),
        .out_err_code(a6_err_code));
      
    bf16_add_branch ADD7(
        .clk(clk),
        .reset(reset),
        .in1(a5_alu_r),
        .exp_1(a5_exp_r),
        .s_in1(a5_s_r),
        .exc_flag_1(a5_exc_flag),
        .err_code_1(a5_err_code),
        .in2(a6_alu_r),
        .exp_2(a6_exp_r),
        .s_in2(a6_s_r),
        .exc_flag_2(a6_exc_flag),
        .err_code_2(a6_err_code),
        .out_alu_r(a7_alu_r),
        .out_exp_r(a7_exp_r),
        .out_s_r(a7_s_r),
        .out_exc_flag(a7_exc_flag),
        .out_err_code(a7_err_code));
      
    bf16_add_root ROOT(
        .clk(clk),
        .reset(reset),
        .in1(a7_alu_r),
        .exp_1(a7_exp_r),
        .s_in1(a7_s_r),
        .exc_flag_1(a7_exc_flag),
        .err_code_1(a7_err_code),
        .in2(m9_alu_m),
        .exp_2(m9_exp_m),
        .s_in2(m9_s_m),
        .exc_flag_2(m9_exc_flag),
        .err_code_2(m9_err_code),
        .result(result));

endmodule
