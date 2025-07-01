module uart_tx(
    input clk,
    input rst,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);

    parameter CLK_FREQ = 100000000;
    parameter BAUD_RATE = 115200;

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;

    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg [9:0] tx_shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1;
            tx_busy <= 0;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift_reg <= 10'b1111111111;
        end else begin
            if (tx_busy) begin
                if (clk_count == BIT_PERIOD - 1) begin
                    clk_count <= 0;
                    tx <= tx_shift_reg[0];
                    tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                    if (bit_index == 9) begin
                        tx_busy <= 0;
                        bit_index <= 0;
                        tx <= 1;
                    end else begin
                        bit_index <= bit_index + 1;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end else if (tx_start) begin
                tx_busy <= 1;
                tx_shift_reg <= {1'b1, tx_data, 1'b0};
                clk_count <= 0;
                bit_index <= 0;
            end
        end
    end

endmodule

