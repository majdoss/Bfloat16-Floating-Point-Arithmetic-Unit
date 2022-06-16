
module bf16_fmadd_fmsub(
    input wire clk,
    input wire reset,
    input wire [15:0] in1,
    input wire [15:0] in2,
    input wire [15:0] in3,
    input wire [4:0] funct5,
    output reg [15:0] result
);

    // pipeline registers
    // used to propagate information used at later stages

    // p1 register
    reg [15:0] p1_reg_in3;
    reg [4:0] p1_reg_funct5;
    reg [31:0] p1_reg_exp_rm;
    reg [7:0] p1_reg_alu_in1;
    reg [7:0] p1_reg_alu_in2;
    reg p1_reg_s_rm;
	
    // STAGE 1
    reg exc_flag;
    reg [15:0] exc_res;
    reg [31:0] exp_1;  // exponent 1
    reg [31:0] exp_2;  // exponent 2
    reg [7:0] alu_in1;  // operand 1
    reg [7:0] alu_in2;  // operand 2
    reg s_rm;  // multiplication result sign
    reg [15:0] p1_reg_exc_res;
    reg p1_reg_exc_flag; 
	
    // p2 register
    reg [15:0] p2_reg_alu_rm;
    reg [31:0] p2_reg_exp_rm;
    reg p2_reg_s_rm;
    reg [15:0] p2_reg_exc_res;
    reg [15:0] p2_reg_in3;
    reg [4:0] p2_reg_funct5;
    reg p2_reg_exc_flag;
	  
    // p3 register
    reg signed [17:0] p3_reg_alu_m;
    reg signed [17:0] p3_reg_alu_m_shifted;
    reg signed [17:0] p3_reg_alu_in3;
    reg signed [17:0] p3_reg_alu_in3_shifted;
    reg signed [31:0] p3_reg_exp_3;
    reg signed [31:0] p3_reg_exp_m;
    reg p3_reg_s_m;
    reg p3_reg_s_in3;
    reg [15:0] p3_reg_exc_res;
    reg p3_reg_exc_flag;
    reg [4:0] p3_reg_funct5;
	
    // STAGE 3
    // these are used to store the "shift value" in case we need to shift mantissas for allignment
    reg signed [31:0] exp_s1;
    reg signed [31:0] exp_s2;
    reg signed [9:0] exp_rm_signed;

    reg signed [31:0] exp_m;  // multiplication result exponent (used for first input to add/sub)
    reg signed [31:0] exp_3;  // exponent 3 (used for second input to add/sub)
    reg signed [31:0] exp_r;  // final result exponent
    reg signed [17:0] alu_m;  // operand 1 (generated from multiplication result)
    reg signed [17:0] alu_in3;  // operand 2
    reg signed [17:0] alu_m_shifted;  // shifted operand 1 (used if necessary)
    reg signed [17:0] alu_in3_shifted;  // shifted operand 2 (used if necessary)
    reg s_m;  // multiplication sign
    reg s_in3;  // input 3 sign
	
    // p4 register
    reg [15:0] p4_reg_exc_res;
    reg p4_reg_exc_flag;
    reg [4:0] p4_reg_funct5;
    reg signed [31:0] p4_reg_exp_r;  
    
    // STAGE 4
    reg signed [17:0] v_alu_m;
    reg signed [17:0] v_alu_in3;
    reg signed [17:0] p4_reg_alu_m;
    reg signed [17:0] p4_reg_alu_in3;
	
    // p5 register
    reg signed [31:0] p5_reg_exp_r;
    reg [15:0] p5_reg_exc_res;
    reg p5_reg_exc_flag;
	
    // STAGE 5
    reg signed [17:0] alu_r;
    reg s_r; // result sign
    reg cancel_flag; // cancellation flag
    reg p5_reg_s_r;
    reg p5_reg_cancel_flag;
    reg [17:0] p5_reg_alu_r;
    
    // p6 register
    reg p6_reg_exc_flag;
    reg p6_reg_s_r;
    reg p6_reg_cancel_flag;
    reg [15:0] p6_reg_exc_res;
	
    // STAGE 6
    reg [17:0] p5_alu_r;
    reg [31:0] p5_exp_r;
    reg [17:0] p6_reg_alu_r;
    reg [31:0] p6_reg_exp_r;
	
    // STAGE 7
    reg [17:0] p6_alu_r;
    reg [31:0] p6_exp_r;

    // pipeline registers
    always @ (posedge clk) begin
        if (reset == 0) begin
            // p1 register
            p1_reg_exp_rm <= 0;
            p1_reg_in3 <= 0;
            p1_reg_funct5 <= 0;
            p1_reg_alu_in1 <= 0;
            p1_reg_alu_in2 <= 0;
            p1_reg_s_rm <= 0;
            p1_reg_exc_flag <= 1;
            p1_reg_exc_res <= 0;
            // p2 register
            p2_reg_alu_rm <= 0;
            p2_reg_exp_rm <= 0;
            p2_reg_s_rm <= 0;
            p2_reg_exc_res <= 0;
            p2_reg_in3 <= 0;
            p2_reg_funct5 <= 0;
            p2_reg_exc_flag <= 1;
            // p3 register
            p3_reg_alu_m <= 0;
            p3_reg_alu_m_shifted <= 0;
            p3_reg_alu_in3 <= 0;
            p3_reg_alu_in3_shifted <= 0;
            p3_reg_exp_3 <= 0;
            p3_reg_exp_m <= 0;
            p3_reg_s_m <= 0;
            p3_reg_s_in3 <= 0;
            p3_reg_exc_res <= 0;
            p3_reg_exc_flag <= 1;
            p3_reg_funct5 <= 0;
            // p4 register
            p4_reg_funct5 <= 0;
            p4_reg_exp_r <= 0;
            p4_reg_exc_res <= 0;
            p4_reg_exc_flag <= 1;
            p4_reg_alu_m <= 0;
            p4_reg_alu_in3 <= 0;
            // p5 register
            p5_reg_exp_r <= 0;
            p5_reg_exc_res <= 0;
            p5_reg_exc_flag <= 1'b1;
            p5_reg_alu_r <= 0;
            p5_reg_s_r <= 0;
            p5_reg_cancel_flag <= 0;
            // p6 register
            p6_reg_exc_flag <= 1;
            p6_reg_s_r <= 0;
            p6_reg_cancel_flag <= 0;
            p6_reg_exc_res <= 0;
            p6_reg_alu_r <= 0;
            p6_reg_exp_r <= 0;
        end else begin
            // STAGE 1
            p1_reg_exp_rm <= (exp_1 + exp_2) - 127; // compute multiplication result exponent
            p1_reg_in3 <= in3;
            p1_reg_funct5 <= funct5;
            p1_reg_alu_in1 <= alu_in1;
            p1_reg_alu_in2 <= alu_in2;
            p1_reg_s_rm <= s_rm;
            p1_reg_exc_flag <= 1;
            p1_reg_exc_res <= 0;
            p1_reg_exc_flag <= exc_flag;
            p1_reg_exc_res <= exc_res;
            // STAGE 2
            p2_reg_alu_rm <= p1_reg_alu_in1 * p1_reg_alu_in2; // multiply operands
            p2_reg_exp_rm <= p1_reg_exp_rm;
            p2_reg_s_rm <= p1_reg_s_rm;
            p2_reg_exc_res <= p1_reg_exc_res;
            p2_reg_in3 <= p1_reg_in3;
            p2_reg_funct5 <= p1_reg_funct5;
            p2_reg_exc_flag <= p1_reg_exc_flag;
            // STAGE 3
            p3_reg_alu_m <= alu_m;
            p3_reg_alu_m_shifted <= alu_m_shifted;
            p3_reg_alu_in3 <= alu_in3;
            p3_reg_alu_in3_shifted <= alu_in3_shifted;
            p3_reg_exp_3 <= exp_3;
            p3_reg_exp_m <= exp_m;
            p3_reg_s_m <= s_m;
            p3_reg_s_in3 <= s_in3;
            p3_reg_exc_res <= p2_reg_exc_res;
            p3_reg_exc_flag <= p2_reg_exc_flag;
            p3_reg_funct5 <= p2_reg_funct5;
            // STAGE 4
            p4_reg_funct5 <= p3_reg_funct5;
            p4_reg_exp_r <= exp_r;
            p4_reg_exc_res <= p3_reg_exc_res;
            p4_reg_exc_flag <= p3_reg_exc_flag;
            p4_reg_alu_m <= v_alu_m;
            p4_reg_alu_in3 <= v_alu_in3;
            // STAGE 5
            p5_reg_exp_r <= p4_reg_exp_r;
            p5_reg_exc_res <= p4_reg_exc_res;
            p5_reg_exc_flag <= p4_reg_exc_flag;
            p5_reg_alu_r <= alu_r;
            p5_reg_s_r <= s_r;
            p5_reg_cancel_flag <= cancel_flag;
            // STAGE 6
            p6_reg_exc_flag <= p5_reg_exc_flag;
            p6_reg_s_r <= p5_reg_s_r;
            p6_reg_cancel_flag <= p5_reg_cancel_flag;
            p6_reg_exc_res <= p5_reg_exc_res;
            p6_reg_alu_r <= p5_alu_r;
            p6_reg_exp_r <= p5_exp_r;
        end
    end

    // STAGE 1
    always @(*) begin
        if ((in1[14:7] == 0) || (in2[14:7] == 0)) begin
            // handle zeros and denorms
            // Denormalized numbers are flushed to zero
            exp_1 <= 0;
            exp_2 <= 127;
            alu_in1 <= 0;
            alu_in2 <= 0;
            s_rm <= 0;
        end else begin
            // Prepare exponents
            // We do not need to work with actual exponent.
            // We use bias notation to save on calculations.
            exp_1 <= in1[14:7];
            exp_2 <= in2[14:7];
            // Prepare operands
            alu_in1 <= {1'b1,in1[6:0]};
            alu_in2 <= {1'b1,in2[6:0]};
            // adjust multiplication result sign
            s_rm <= in1[15] ^ in2[15];
        end
    end

    // STAGE 1
    always @(*) begin
        // Handle exceptions: NaN and infinity
        exc_flag = 1;
        // handle NaN and infinity
        if ((exp_1 == 255) || (exp_2 == 255) || (in3[14:7] == 8'b11111111)) begin
            if ((in1[6:0] != 0) && (exp_1 == 255)) begin
                exc_res = in1;
            end else if ((in2[6:0] != 0) && (exp_2 == 255)) begin
                exc_res = in2;
            end else if ((in3[6:0] != 0) && (in3[14:7] == 8'b11111111)) begin
                exc_res = in3;
            end else begin
                if (exp_1 == 255) begin
                    exc_res = in1;
                end else if (exp_2 == 255) begin
                    exc_res = in2;
                end else begin
                    exc_res = in3;
                end
            end
        end else begin
            // no exception
            exc_flag = 0;
        end
    end

    // STAGE 3
    always @(*) begin
        // Prepare exponents
        exp_3 <= p2_reg_in3[14:7];
        exp_m <= p2_reg_exp_rm;
        exp_rm_signed = p2_reg_exp_rm;
        exp_s1 = ({2'b00,p2_reg_in3[14:7]}) - exp_rm_signed;
        exp_s2 = exp_rm_signed - ({2'b00,p2_reg_in3[14:7]});

        if (p2_reg_in3[14:7] == 0) begin
            // handle zeros and denorms
            // Denormalized numbers are flushed to zero
            alu_in3 <= 0;
            alu_in3_shifted <= 0;
            s_in3 <= 0;
        end else begin
            // normal case
            // Prepare operands
            alu_in3 <= {4'b0001,p2_reg_in3[6:0],7'b0000000};
            // Used for Mantissa allignment in case needed
            alu_in3_shifted <= ({4'b0001,p2_reg_in3[6:0],7'b0000000}) >>> exp_s2;
            // Prepare operands signs
            s_in3 <= p2_reg_in3[15];
        end
        if (p2_reg_alu_rm[14:7] == 0) begin
            alu_m <= 0;
            alu_m_shifted <= 0;
            s_m <= 0;
        end else begin
            alu_m <= {2'b00,p2_reg_alu_rm};
            alu_m_shifted <= ({2'b00,p2_reg_alu_rm}) >>> exp_s1;
            s_m <= p2_reg_s_rm;
        end
    end

    // STAGE 4
    always @(*) begin
        v_alu_m = p3_reg_alu_m;
        v_alu_in3 = p3_reg_alu_in3;

        if (p3_reg_exp_m >= p3_reg_exp_3) begin
            // Mantissa allignment
            v_alu_in3 = p3_reg_alu_in3_shifted;
            // Choose correct exponent as result
            exp_r <= p3_reg_exp_m;
        end else begin
            v_alu_m = p3_reg_alu_m_shifted;
            exp_r <= p3_reg_exp_3;
        end

        // Express both operands in two's complement 
        if (p3_reg_s_m == 1) begin
            v_alu_m =  -(v_alu_m);
        end else begin
            v_alu_m = v_alu_m;
        end

        if (p3_reg_s_in3 == 1) begin
            v_alu_in3 =  -(v_alu_in3);
        end else begin
            v_alu_in3 = v_alu_in3;
        end
    end

    // STAGE 5
    always @(*) begin

        case (p4_reg_funct5)
            5'b00100, 5'b00000, 5'b00010 : begin
                // for performing fused multiply add or regular add
                alu_r = p4_reg_alu_m + p4_reg_alu_in3;
            end
            5'b00101,5'b00001 : begin
                // for performing fused multiply sub or regular sub
                alu_r = p4_reg_alu_m - p4_reg_alu_in3;
            end
            default : begin
              alu_r = 0;
            end
        endcase

        // handle cancellation
        if (alu_r == 0) begin
           cancel_flag = 1;
        end else begin
           cancel_flag = 0;
        end

        // Set result sign bit and express result as a magnitude
        s_r = 0;
        if (alu_r < 0) begin
            s_r = 1;
            alu_r = -(alu_r);
        end
    end

    // STAGE 6
    always @(p5_reg_alu_r, p5_reg_exp_r, clk, reset) begin

        p5_alu_r = p5_reg_alu_r;
        p5_exp_r = p5_reg_exp_r;

        if (p5_alu_r[16] == 1) begin
            p5_exp_r = p5_exp_r + 2;
            p5_alu_r = p5_alu_r >> 2;
        end else if (p5_alu_r[15] == 1) begin
            p5_exp_r = p5_exp_r + 1;
            p5_alu_r = p5_alu_r >> 1;
        end else if (p5_alu_r[14] == 1) begin
           p5_alu_r = p5_alu_r << 0;
        end else if (p5_alu_r[13] == 1) begin
            p5_exp_r = p5_exp_r - 1;
            p5_alu_r = p5_alu_r << 1;
        end else if (p5_alu_r[12] == 1) begin
            p5_exp_r = p5_exp_r - 2;
            p5_alu_r = p5_alu_r << 2;
        end else if (p5_alu_r[11] == 1) begin
            p5_exp_r = p5_exp_r - 3;
            p5_alu_r = p5_alu_r << 3;
        end else if (p5_alu_r[10] == 1) begin
            p5_exp_r = p5_exp_r - 4;
            p5_alu_r = p5_alu_r << 4;
        end else if (p5_alu_r[9] == 1) begin
            p5_exp_r = p5_exp_r - 5;
            p5_alu_r = p5_alu_r << 5;
        end else if (p5_alu_r[8] == 1) begin
            p5_exp_r = p5_exp_r - 6;
            p5_alu_r = p5_alu_r << 6;
        end else if (p5_alu_r[7] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 7;
        end else if (p5_alu_r[6] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 8;
        end else if (p5_alu_r[5] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 9;
        end else if (p5_alu_r[4] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 10;
        end else if (p5_alu_r[3] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 11;
        end else if (p5_alu_r[2] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 12;
        end else if (p5_alu_r[1] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 13;
        end else if (p5_alu_r[0] == 1) begin
            p5_exp_r = p5_exp_r - 7;
            p5_alu_r = p5_alu_r << 14;
        end
    end

    // STAGE 7
    always @(*) begin

        p6_alu_r = p6_reg_alu_r;
        p6_exp_r = p6_reg_exp_r;

        // round to the nearest even
        if (p6_alu_r[6] == 1) begin
            p6_alu_r[13:7] = (p6_alu_r[13:7]) + 1;
            // Adjust exponent
            if (p6_alu_r[13:7] == 0) begin
                p6_exp_r = p6_exp_r + 1;
            end
        end

        // Generate final result in bfloat 16 format
        if (p6_reg_exc_flag == 1) begin
           result <= p6_reg_exc_res;
        end else if (p6_reg_cancel_flag == 1) begin
           result <= 0;
        end else if ((p6_exp_r >= 255) && (p6_reg_s_r == 0)) begin
           result <= 16'b0111111110000000; // overflow, result = +inf
        end else if ((p6_exp_r >= 255) && (p6_reg_s_r == 1)) begin
           result <= 16'b1111111110000000; // overflow, result = -inf
        end else if (p6_exp_r <= 0) begin
            result <= 16'b0000000000000000; // underflow, result = zero
        end else begin
            result[15] <= p6_reg_s_r;
            result[14:7] <= p6_exp_r;
            result[6:0] <= p6_alu_r[13:7];
        end
    end

endmodule
