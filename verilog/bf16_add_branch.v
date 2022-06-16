
module bf16_add_branch
# (parameter G = 6) (
    input clk,
    input reset,
    // in1 parameters
    input [G + 15:0] in1,
    input [31:0] exp_1,
    input s_in1,
    input exc_flag_1,
    input err_code_1,
    // in2 parameters
    input [G + 15:0] in2,
    input [31:0] exp_2,
    input s_in2,
    input exc_flag_2,
    input err_code_2,
    // result parameters
    output reg [G + 15:0] out_alu_r,
    output reg [31:0] out_exp_r,
    output reg out_s_r,
    output reg out_exc_flag,
    output reg out_err_code
);

    // p1 register
    reg signed [G + 15:0] p1_reg_alu_in2;
    reg signed [G + 15:0] p1_reg_alu_in2_shifted;
    reg signed [G + 15:0] p1_reg_alu_in1;
    reg signed [G + 15:0] p1_reg_alu_in1_shifted;
    reg signed [31:0] p1_reg_exp_1;
    reg signed [31:0] p1_reg_exp_2;
    reg p1_reg_s_in2;
    reg p1_reg_s_in1;
    reg p1_reg_exc_flag;
    reg p1_reg_err_code;  

    // p2 register
    reg signed [31:0] p2_reg_exp_r;
    reg p2_reg_exc_flag;
    reg p2_reg_err_code;
    reg signed [G + 15:0] p2_reg_alu_in1;
    reg signed [G + 15:0] p2_reg_alu_in2;

    // STAGE 2
    reg signed [G + 15:0] v_alu_in1;
    reg signed [G + 15:0] v_alu_in2;
    reg signed [G + 15:0] alu_r;
    reg s_r;
    reg signed [31:0] exp_r;

    // STAGE 1
    reg signed [G + 15:0] alu_in1;
    reg signed [G + 15:0] alu_in1_shifted;
    reg signed [G + 15:0] alu_in2;
    reg signed [G + 15:0] alu_in2_shifted;
    reg exc_flag;
    reg err_code;
    wire [G - 1:0] guard;  

    assign guard = 0;
  
    // STAGE 1
    always @(*) begin
        // check exception
        if (exc_flag_1 == 1 || exc_flag_2 == 1) begin
            exc_flag <= 1;
            err_code <= err_code_1 | err_code_2;
        end else begin
            exc_flag <= 0;
            err_code <= 0;
        end
    end

    always @(*) begin: S1
        reg signed [31:0] exp_s1;
        reg signed [31:0] exp_s2;
        // these are used to store the "shift value" in case we need to shift mantissas for allignment

        if ((exp_1 - exp_2) < 0) begin
           exp_s1 =  -(exp_1 - exp_2);
        end else begin
           exp_s1 = exp_1 - exp_2;
        end
        if ((exp_2 - exp_1) < 0) begin
            exp_s2 =  -(exp_2 - exp_1);
        end else begin
            exp_s2 = exp_2 - exp_1;
        end

        // Prepare operands
        alu_in1 <= in1;
        // Used for Mantissa allignment in case needed
        alu_in1_shifted <= (in1) >>> exp_s2;

        alu_in2 <= in2;
        alu_in2_shifted <= (in2) >>> exp_s1;
    end

    // STAGE 2
    always @(*) begin: S2

        v_alu_in1 = p1_reg_alu_in1;
        v_alu_in2 = p1_reg_alu_in2;

        if (p1_reg_exp_2 >= p1_reg_exp_1) begin
            // Mantissa allignment
            v_alu_in1 = p1_reg_alu_in1_shifted;
            // Choose correct exponent as result
            exp_r <= p1_reg_exp_2;
        end else begin
            v_alu_in2 = p1_reg_alu_in2_shifted;
            exp_r <= p1_reg_exp_1;
        end

        // Express both operands in two's complement 
        if (p1_reg_s_in1 == 1) begin
            v_alu_in1 =  -(v_alu_in1);
        end else begin
            v_alu_in1 = v_alu_in1;
        end

        if (p1_reg_s_in2 == 1) begin
            v_alu_in2 =  -(v_alu_in2);
        end else begin
            v_alu_in2 = v_alu_in2;
        end
    end

    // STAGE 3
    always @(*) begin: S3
        // result sign
        reg signed [31:0] v_exp;
        v_exp = p2_reg_exp_r;

        alu_r = p2_reg_alu_in2 + p2_reg_alu_in1;

        // Set result sign bit and express result as a magnitude
        s_r = 0;
        if (alu_r < 0) begin
            s_r = 1;
            alu_r =  -(alu_r);
        end
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            // STAGE 1
            p1_reg_alu_in2 <= 0;
            p1_reg_alu_in2_shifted <= 0;
            p1_reg_alu_in1 <= 0;
            p1_reg_alu_in1_shifted <= 0;
            p1_reg_exp_1 <= 0;
            p1_reg_exp_2 <= 0;
            p1_reg_s_in2 <= 0;
            p1_reg_s_in1 <= 0;
            p1_reg_exc_flag <= 1;
            p1_reg_err_code <= 0;
            // STAGE 2
            p2_reg_exp_r <= 0;
            p2_reg_exc_flag <= 1;
            p2_reg_err_code <= 0;
            p2_reg_alu_in1 <= 0;
            p2_reg_alu_in2 <= 0;
            // STAGE 3
            out_exp_r <= 0;
            out_exc_flag <= 1;
            out_err_code <= 0;
            out_alu_r <= 0;
            out_s_r <= 0;
        end else begin
            // STAGE 1
            p1_reg_alu_in2 <= alu_in2;
            p1_reg_alu_in2_shifted <= alu_in2_shifted;
            p1_reg_alu_in1 <= alu_in1;
            p1_reg_alu_in1_shifted <= alu_in1_shifted;
            p1_reg_exp_1 <= exp_1;
            p1_reg_exp_2 <= exp_2;
            p1_reg_s_in2 <= s_in2;
            p1_reg_s_in1 <= s_in1;
            p1_reg_exc_flag <= exc_flag;
            p1_reg_err_code <= err_code;
            // STAGE 2
            p2_reg_exp_r <= exp_r;
            p2_reg_exc_flag <= p1_reg_exc_flag;
            p2_reg_err_code <= p1_reg_err_code;
            p2_reg_alu_in1 <= v_alu_in1;
            p2_reg_alu_in2 <= v_alu_in2;
            // STAGE 3
            out_exp_r <= p2_reg_exp_r;
            out_exc_flag <= p2_reg_exc_flag;
            out_err_code <= p2_reg_err_code;
            out_alu_r <= alu_r;
            out_s_r <= s_r;
        end
    end

endmodule
