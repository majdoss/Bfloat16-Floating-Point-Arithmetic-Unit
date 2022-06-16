

module bf16_unit
# (parameter G = 6) (
    input  clk,
    input  reset,
    input  [15:0] in1,
    input  [15:0] in2,
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
    input  [4:0] funct5,
    output wire [15:0] result
);




    // We have to save the value of funct5 in pipeline registers
    reg [4:0] p1_funct5;
    reg [4:0] p2_funct5;
    reg [4:0] p3_funct5;
    reg [4:0] p4_funct5;
    reg [4:0] p5_funct5;
    reg [4:0] p6_funct5;
    reg [4:0] p7_funct5;
    reg [4:0] p8_funct5;
    reg [4:0] p9_funct5;
    reg [4:0] p10_funct5;
    reg [4:0] p11_funct5;
    reg [4:0] p12_funct5;
    reg [4:0] p13_funct5;
    reg [4:0] p14_funct5;
    reg [4:0] p15_funct5;
    reg [4:0] p16_funct5;
    reg [4:0] p17_funct5;
    reg [15:0] p1_in1;
    reg [15:0] p1_in2;
    reg [15:0] p1_in3;
    reg [15:0] p2_in1;
    reg [15:0] p2_in2;
    reg [15:0] p2_in3;
    reg [15:0] p3_in1;
    reg [15:0] p3_in2;
    reg [15:0] p3_in3;
    reg [15:0] p4_in1;
    reg [15:0] p4_in2;
    reg [15:0] p4_in3;
    reg [15:0] p5_in1;
    reg [15:0] p5_in2;
    reg [15:0] p5_in3;
    reg [15:0] p6_in1;
    reg [15:0] p6_in2;
    reg [15:0] p6_in3;
    reg [15:0] p7_in1;
    reg [15:0] p7_in2;
    reg [15:0] p7_in3; 
    reg [15:0] p8_in1;
    reg [15:0] p8_in2;
    reg [15:0] p8_in3; 
    reg [15:0] p9_in1;
    reg [15:0] p9_in2;
    reg [15:0] p9_in3; 
    reg [15:0] p10_in1;
    reg [15:0] p10_in2;
    reg [15:0] p10_in3; 

    // Connect output of each circuit to multiplexer
    wire [15:0] mux_mult_add_sub;
    wire [15:0] mux_macc;
    wire [15:0] s_in1;
    wire [15:0] s_in2;
    wire [15:0] s_in3;

    bf16_SIMD_MACC bf16_SIMD(
      .clk(clk),
      .reset(reset),
      .in1(in1),
      .in2(in2),
      .in3(in3),
      .in4(in4),
      .in5(in5),
      .in6(in6),
      .in7(in7),
      .in8(in8),
      .in9(in9),
      .in10(in10),
      .in11(in11),
      .in12(in12),
      .in13(in13),
      .in14(in14),
      .in15(in15),
      .in16(in16),
      .in17(in17),
      .in18(in18),
      .result(mux_macc));

    decoder dec(
      .in1(p10_in1),
      .in2(p10_in2),
      .in3(p10_in3),
      .funct5(p10_funct5),
      .out1(s_in1),
      .out2(s_in2),
      .out3(s_in3));

    bf16_fmadd_fmsub fmadd_fmsub(
      .clk(clk),
      .reset(reset),
      .in1(s_in1),
      .in2(s_in2),
      .in3(s_in3),
      .funct5(p10_funct5),
      .result(mux_mult_add_sub));


    mux_funct5 mux(
      .mult_add_sub(mux_mult_add_sub),
      .macc(mux_macc),
      .funct5(p17_funct5),
      .result(result));

    always @(posedge clk) begin
        if (reset == 0) begin
            p1_funct5 <= 0;
            p2_funct5 <= 0;
            p3_funct5 <= 0;
            p4_funct5 <= 0;
            p5_funct5 <= 0;
            p6_funct5 <= 0;
            p7_funct5 <= 0;
            p8_funct5 <= 0;
            p9_funct5 <= 0;
            p10_funct5 <= 0;
            p11_funct5 <= 0;
            p12_funct5 <= 0;
            p13_funct5 <= 0;
            p14_funct5 <= 0;
            p15_funct5 <= 0;
            p16_funct5 <= 0;
            p17_funct5 <= 0;
            p1_in1 <= 0;
            p1_in2 <= 0;
            p1_in3 <= 0;
            p2_in1 <= 0;
            p2_in2 <= 0;
            p2_in3 <= 0;
            p3_in1 <= 0;
            p3_in2 <= 0;
            p3_in3 <= 0;
            p4_in1 <= 0;
            p4_in2 <= 0;
            p4_in3 <= 0;
            p5_in1 <= 0;
            p5_in2 <= 0;
            p5_in3 <= 0;
            p6_in1 <= 0;
            p6_in2 <= 0;
            p6_in3 <= 0;
            p7_in1 <= 0;
            p7_in2 <= 0;
            p7_in3 <= 0;
            p8_in1 <= 0;
            p8_in2 <= 0;
            p8_in3 <= 0;
            p9_in1 <= 0;
            p9_in2 <= 0;
            p9_in3 <= 0;
            p10_in1 <= 0;
            p10_in2 <= 0;
            p10_in3 <= 0;
        end else begin
            p1_funct5 <= funct5;
            p2_funct5 <= p1_funct5;
            p3_funct5 <= p2_funct5;
            p4_funct5 <= p3_funct5;
            p5_funct5 <= p4_funct5;
            p6_funct5 <= p5_funct5;
            p7_funct5 <= p6_funct5;
            p8_funct5 <= p7_funct5;
            p9_funct5 <= p8_funct5;
            p10_funct5 <= p9_funct5;
            p11_funct5 <= p10_funct5;
            p12_funct5 <= p11_funct5;
            p13_funct5 <= p12_funct5;
            p14_funct5 <= p13_funct5;
            p15_funct5 <= p14_funct5;
            p16_funct5 <= p15_funct5;
            p17_funct5 <= p16_funct5;
            p1_in1 <= in1;
            p1_in2 <= in2;
            p1_in3 <= in3;
            p2_in1 <= p1_in1;
            p2_in2 <= p1_in2;
            p2_in3 <= p1_in3;
            p3_in1 <= p2_in1;
            p3_in2 <= p2_in2;
            p3_in3 <= p2_in3;
            p4_in1 <= p3_in1;
            p4_in2 <= p3_in2;
            p4_in3 <= p3_in3;
            p5_in1 <= p4_in1;
            p5_in2 <= p4_in2;
            p5_in3 <= p4_in3;
            p6_in1 <= p5_in1;
            p6_in2 <= p5_in2;
            p6_in3 <= p5_in3;
            p7_in1 <= p6_in1;
            p7_in2 <= p6_in2;
            p7_in3 <= p6_in3;
            p8_in1 <= p7_in1;
            p8_in2 <= p7_in2;
            p8_in3 <= p7_in3;
            p9_in1 <= p8_in1;
            p9_in2 <= p8_in2;
            p9_in3 <= p8_in3;
            p10_in1 <= p9_in1;
            p10_in2 <= p9_in2;
            p10_in3 <= p9_in3;
        end
    end


endmodule
