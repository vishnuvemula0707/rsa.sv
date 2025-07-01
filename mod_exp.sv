module mod_exp(
    input clk,
    input rst,
    input start,
    input [31:0] base,
    input [31:0] exponent,
    input [31:0] modulus,
    output reg [31:0] result,
    output reg done
);

    reg [31:0] temp;
    reg [31:0] exp;
    reg [31:0] base_reg; // Create a temporary signal to hold the base value
    reg [4:0] bit_idx;

    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
            state <= 0;
            result <= 0;
        end else begin
            case (state)
                0: begin
                    if (start) begin
                        temp <= 1;
                        exp <= exponent;
                        base_reg <= base; // Assign the input base to the temporary signal
                        bit_idx <= 31;
                        state <= 1;
                    end
                end

                1: begin
                    if (exp[bit_idx]) begin
                        temp <= (temp * base_reg) % modulus;
                    end
                    base_reg <= (base_reg * base_reg) % modulus; // Use the temporary signal instead of base
                    if (bit_idx == 0) begin
                        result <= temp;
                        done <= 1;
                        state <= 0;
                    end else begin
                        bit_idx <= bit_idx - 1;
                    end
                end

                default: state <= 0;
            endcase
        end
    end

endmodule
