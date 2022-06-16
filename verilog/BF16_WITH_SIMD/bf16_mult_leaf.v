
(* use_dsp = "yes" *) module bf16_mult_leaf
# (parameter G = 6) (
    input clk,
    input reset,
    input [15:0] in1, // in bf16 format
    input [15:0] in2, // in bf16 format
    output wire [G + 15:0] out_alu_m, // mult result
    output reg [31:0] out_exp_m, // mult result exponent
    output reg out_s_m, // mult result sign 
    output reg out_exc_flag, // exception flag
    output reg out_err_code // indicates if NaN or Infinity
);


    // p1 register
    reg [31:0] p1_reg_exp_m;
    reg [7:0] p1_reg_alu_in1;
    reg [7:0] p1_reg_alu_in2;
    reg p1_reg_s_m;
    reg p1_reg_exc_flag;
    reg p1_reg_err_code;
      
    // STAGE 1
    reg [31:0] exp_1;
    reg [31:0] exp_2;
    reg [7:0] alu_in1;
    reg [7:0] alu_in2;
    reg s_m;  // multiplication result sign
    reg exc_flag;
    reg err_code;
    wire [G-1:0] guard;
    reg [15:0] s_alu_m;
    
    // Replace VERILOG equivalent
    //attribute use_dsp of s_alu_m: signal is "yes";

    assign guard = 0;
  
    // STAGE 1
    always @(*) begin
        if ((in1[14:7] == 0) || (in2[14:7] == 0)) begin
            // handle zeros and denorms
            // Denormalized numbers are flushed to zero
            exp_1 <= 0;
            exp_2 <= 0;
            alu_in1 <= 0;
            alu_in2 <= 0;
            s_m <= 0;
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
            s_m <= in1[15] ^ in2[15];
        end
    end

  // STAGE 1
  always @(*) begin 
      // Handle exceptions: NaN and infinity
      exc_flag = 1;
      err_code = 0;
      // handle NaN and infinity
      if ((exp_1 == 255) || (exp_2 == 255)) begin
          if (in1[6:0] != 0 && exp_1 == 255 || in2[6:0] != 0 && exp_2 == 255) begin
              err_code = 1;
          end else begin
              err_code = 0;
          end
      end else begin
          // no exception
          exc_flag = 0;
      end
  end

  always @(posedge clk) begin
      if (reset == 0) begin
          // p1 register
          p1_reg_exp_m <= 0;
          p1_reg_alu_in1 <= 0;
          p1_reg_alu_in2 <= 0;
          p1_reg_s_m <= 0;
          p1_reg_exc_flag <= 1;
          p1_reg_err_code <= 0;
          // p2 register
          s_alu_m <= 0;
          out_exp_m <= 0;
          out_s_m <= 0;
          out_err_code <= 0;
          out_exc_flag <= 1;
      end else begin
          // STAGE 1
          p1_reg_exp_m <= exp_1 + exp_2; // prepare multiplication result exponent
          p1_reg_alu_in1 <= alu_in1;
          p1_reg_alu_in2 <= alu_in2;
          p1_reg_s_m <= s_m;
          p1_reg_exc_flag <= exc_flag;
          p1_reg_err_code <= err_code;
          // STAGE 2
          s_alu_m <= p1_reg_alu_in1 * p1_reg_alu_in2;
          // multiply operands
          out_exp_m <= p1_reg_exp_m;
          out_s_m <= p1_reg_s_m;
          out_err_code <= p1_reg_err_code;
          out_exc_flag <= p1_reg_exc_flag;
      end
  end

  assign out_alu_m = {guard, s_alu_m};

endmodule
