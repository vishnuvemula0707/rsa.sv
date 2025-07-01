module uart_rx(
    input clk,
    input rst,
    input rx,
    output reg [7:0] data_out,
    output reg data_ready
);

    parameter CLK_FREQ = 100000000;
    parameter BAUD_RATE = 115200;

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT = BIT_PERIOD / 2;

    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg receiving;

    reg [7:0] rx_shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_count <= 0;
            bit_index <= 0;
            receiving <= 0;
            data_ready <= 0;
            data_out <= 0;
        end else begin
            data_ready <= 0;

            if (!receiving) begin
                if (rx == 0) begin
                    receiving <= 1;
                    clk_count <= HALF_BIT;
                    bit_index <= 0;
                end
            end else begin
                if (clk_count == BIT_PERIOD - 1) begin
                    clk_count <= 0;
                    bit_index <= bit_index + 1;

                    if (bit_index < 8) begin
                        rx_shift_reg <= {rx, rx_shift_reg[7:1]};
                    end else if (bit_index == 8) begin
                        data_out <= rx_shift_reg;
                        data_ready <= 1;
                        receiving <= 0;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end
        end
    end

endmodule


