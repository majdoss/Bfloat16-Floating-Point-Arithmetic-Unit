
module bf16_add_root
# (parameter G = 6)(
    input clk,
    input reset,
    input [G + 15:0] in1,
    input [31:0] exp_1,
    input s_in1,
    input exc_flag_1,
    input err_code_1,
    input [G + 15:0] in2,
    input [31:0] exp_2,
    input s_in2,
    input exc_flag_2,
    input err_code_2,
    output reg [15:0] result
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
    reg signed [G + 15:0] v_alu_in1;
    reg signed [G + 15:0] v_alu_in2; 

    // p3 register
    reg signed [31:0] p3_reg_exp_r;
    reg p3_reg_exc_flag;
    reg p3_reg_err_code;
    reg signed [G + 15:0] p3_reg_alu_r;
    reg p3_reg_s_r;
    reg p3_reg_cancel_flag;  

    // p4 register
    reg p4_reg_exc_flag;
    reg p4_reg_err_code;
    reg signed [31:0] p4_reg_exp_r;
    reg signed [G + 15:0] p4_reg_alu_r;
    reg p4_reg_s_r;
    reg p4_reg_cancel_flag;

    // STAGE 1
    reg signed [G + 15:0] alu_in1;
    reg signed [G + 15:0] alu_in1_shifted;
    reg signed [G + 15:0] alu_in2;
    reg signed [G + 15:0] alu_in2_shifted;
    reg exc_flag;
    reg err_code;
    wire [G - 1:0] guard;  

    // STAGE 2
    reg signed [31:0] exp_r;
	
    // STAGE 3
    reg signed [G + 15:0] alu_r;
    reg s_r;
    reg cancel_flag;
    
    // STAGE 4
    reg signed [G + 15:0] v_alu_r;
    reg signed [31:0] v_exp_r;

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

      if((exp_1 - exp_2) < 0) begin
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
    always @(*) begin : S2
        v_alu_in1 = p1_reg_alu_in1;
        v_alu_in2 = p1_reg_alu_in2;

        if ((p1_reg_exp_2 >= p1_reg_exp_1)) begin
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

        // handle cancellation
        if (alu_r == {guard,16'b0000000000000000}) begin
            cancel_flag = 1;
        end else begin
            cancel_flag = 0;
        end

        // Set result sign bit and express result as a magnitude
        s_r = 0;
        if (alu_r < 0) begin
            s_r = 1;
            alu_r =  -(alu_r);
        end
    end

    // STAGE 4
    always @(*) begin
        // Normalize mantissa and adjust exponent
        v_alu_r = p3_reg_alu_r;
        v_exp_r = p3_reg_exp_r;
        
        
        if (v_alu_r[20] == 1) begin
            v_exp_r = v_exp_r + 6;
            v_alu_r = (v_alu_r) >> 6;
        end else if (v_alu_r[19] == 1) begin
            v_exp_r = v_exp_r + 5;
            v_alu_r = (v_alu_r) >> 5;
        end else if (v_alu_r[18] == 1) begin
            v_exp_r = v_exp_r + 4;
            v_alu_r = (v_alu_r) >> 4;
        end else if (v_alu_r[17] == 1) begin
            v_exp_r = v_exp_r + 3;
            v_alu_r = (v_alu_r) >> 3;
        end else if (v_alu_r[16] == 1) begin
            v_exp_r = v_exp_r + 2;
            v_alu_r = (v_alu_r) >> 2;
        end else if (v_alu_r[15] == 1) begin
            v_exp_r = v_exp_r + 1;
            v_alu_r = (v_alu_r) >> 1;
        end else if (v_alu_r[14] == 1) begin
            v_alu_r = (v_alu_r) << 0;
        end else if (v_alu_r[13] == 1) begin
            v_exp_r = v_exp_r - 1;
            v_alu_r = (v_alu_r) << 1;
        end else if (v_alu_r[12] == 1) begin
            v_exp_r = v_exp_r - 2;
            v_alu_r = (v_alu_r) << 2;
        end else if (v_alu_r[11] == 1) begin
            v_exp_r = v_exp_r - 3;
            v_alu_r = (v_alu_r) << 3;
        end else if (v_alu_r[10] == 1) begin
            v_exp_r = v_exp_r - 4;
            v_alu_r = (v_alu_r) << 4;
        end else if (v_alu_r[9] == 1) begin
            v_exp_r = v_exp_r - 5;
            v_alu_r = (v_alu_r) << 5;
        end else if (v_alu_r[8] == 1) begin
            v_exp_r = v_exp_r - 6;
            v_alu_r = (v_alu_r) << 6;
        end else if (v_alu_r[7] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 7;
        end else if (v_alu_r[6] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 8;
        end else if (v_alu_r[5] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 9;
        end else if (v_alu_r[4] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 10;
        end else if (v_alu_r[3] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 11;
        end else if (v_alu_r[2] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 12;
        end else if (v_alu_r[1] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 13;
        end else if (v_alu_r[0] == 1) begin
            v_exp_r = v_exp_r - 7;
            v_alu_r = (v_alu_r) << 14;
        end
    end

    // STAGE 5
    always @(*) begin: S5
        reg signed [G + 15:0] v_alu_r;
        reg signed [31:0] v_exp_r;

        v_alu_r = p4_reg_alu_r;
        v_exp_r = p4_reg_exp_r;

        // round to the nearest even
        if (v_alu_r[6] == 1) begin
            v_alu_r[13:7] = v_alu_r[13:7] + 1;

            // Adjust exponent
            if(v_alu_r[13:7] == 0) begin
                v_exp_r = v_exp_r + 1;
            end
        end

        // Generate final result in bfloat 16 format
        if (p3_reg_exc_flag == 1) begin
            if (p3_reg_err_code == 1) begin
                result <= {p3_reg_s_r,15'b111111110000001}; // NaN
            end else begin
                result <= {p3_reg_s_r,15'b111111110000000}; // +-inf
            end
        end else if (p3_reg_cancel_flag == 1) begin
            result <= 0;
        end else if ((v_exp_r > 381) && p3_reg_s_r == 0) begin
            result <= 16'b0111111110000000; // overflow, result = +inf
        end else if ((v_exp_r > 381) && p3_reg_s_r == 1) begin
            result <= 16'b1111111110000000; // overflow, result = -inf
        end else if (v_exp_r < 128) begin
            result <= 16'b0000000000000000; // underflow, result = zero
        end else begin
            result[15] <= p3_reg_s_r;
            result[14:7] <= (v_exp_r) - 127;
            result[6:0] <= v_alu_r[13:7];
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
            p3_reg_exp_r <= 0;
            p3_reg_exc_flag <= 1;
            p3_reg_err_code <= 0;
            p3_reg_alu_r <= 0;
            p3_reg_s_r <= 0;
            p3_reg_cancel_flag <= 0;
            // STAGE 4
            p4_reg_exc_flag <= 1;
            p4_reg_err_code <= 0;
            p4_reg_s_r <= 0;
            p4_reg_cancel_flag <= 0;
            p4_reg_alu_r <= 0;
            p4_reg_exp_r <= 0;
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
            p3_reg_exp_r <= p2_reg_exp_r;
            p3_reg_exc_flag <= p2_reg_exc_flag;
            p3_reg_err_code <= p2_reg_err_code;
            p3_reg_alu_r <= alu_r;
            p3_reg_s_r <= s_r;
            p3_reg_cancel_flag <= cancel_flag;
            // STAGE 4
            p4_reg_exc_flag <= p3_reg_exc_flag;
            p4_reg_err_code <= p3_reg_err_code;
            p4_reg_s_r <= p3_reg_s_r;
            p4_reg_cancel_flag <= p3_reg_cancel_flag;
            p4_reg_alu_r <= v_alu_r;
            p4_reg_exp_r <= v_exp_r;
        end
    end


endmodule
