module rsa_top(
    input clk,
    input rst,
    input uart_rx,
    output uart_tx
);

    wire [7:0] rx_data;
    wire rx_ready;

    reg [7:0] tx_data;
    reg tx_start;
    wire tx_busy;

    uart_rx uart_rx_inst(
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_ready(rx_ready)
    );

    uart_tx uart_tx_inst(
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );

    reg [31:0] mod_exp_base;
    reg [31:0] public_key;  // (e, n)
    reg [31:0] private_key; // (d, n)
    reg [31:0] modulus; // modulus

    reg [31:0] encrypted_text;
    reg [31:0] decrypted_text;

    reg mod_exp_start_encrypt;
    wire [31:0] mod_exp_result_encrypt;
    wire mod_exp_done_encrypt;

    mod_exp mod_exp_inst_encrypt(
        .clk(clk),
        .rst(rst),
        .start(mod_exp_start_encrypt),
        .base(mod_exp_base),
        .exponent(public_key),
        .modulus(modulus), // modulus
        .result(mod_exp_result_encrypt),
        .done(mod_exp_done_encrypt)
    );

    reg mod_exp_start_decrypt;
    wire [31:0] mod_exp_result_decrypt;
    wire mod_exp_done_decrypt;

    mod_exp mod_exp_inst_decrypt(
        .clk(clk),
        .rst(rst),
        .start(mod_exp_start_decrypt),
        .base(encrypted_text),
        .exponent(private_key),
        .modulus(modulus), // modulus
        .result(mod_exp_result_decrypt),
        .done(mod_exp_done_decrypt)
    );

    reg [7:0] input_buffer [3:0];
    reg [1:0] input_index;
    reg input_ready;

    reg [4:0] state;

    always @(posedge clk) begin
        if (rst) begin
            input_index <= 0;
            input_ready <= 0;
            state <= 0;
            mod_exp_start_encrypt <= 0;
            mod_exp_start_decrypt <= 0;
            tx_start <= 0;
            public_key <= 32'h10001; // e = 65537
            private_key <= 32'h3D; // d = 61
            modulus <= 32'h61; // n = 97
        end else begin
            case (state)
                0: begin
                    if (rx_ready) begin
                        input_buffer[input_index] <= rx_data;
                        input_index <= input_index + 1;
                        if (input_index == 3) begin
                            input_ready <= 1;
                            state <= 1;
                        end
                    end
                end

                1: begin
                    mod_exp_base <= {input_buffer[3], input_buffer[2], input_buffer[1], input_buffer[0]};
                    mod_exp_start_encrypt <= 1;
                    state <= 2;
                end

                2: begin
                    mod_exp_start_encrypt <= 0;
                    if (mod_exp_done_encrypt) begin
                        encrypted_text <= mod_exp_result_encrypt;
                        tx_data <= encrypted_text[7:0];
                        tx_start <= 1;
                        state <= 3;
                    end
                end

                3: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        tx_data <= encrypted_text[15:8];
                        tx_start <= 1;
                        state <= 4;
                    end
                end

                4: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        tx_data <= encrypted_text[23:16];
                        tx_start <= 1;
                        state <= 5;
                    end
                end

                5: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        tx_data <= encrypted_text[31:24];
                        tx_start <= 1;
                        state <= 6;
                    end
                end

                6: begin
                    mod_exp_start_decrypt <= 1;
                    state <= 7;
                end

                7: begin
                    mod_exp_start_decrypt <= 0;
                    if (mod_exp_done_decrypt) begin
                        decrypted_text <= mod_exp_result_decrypt;
                        tx_data <= decrypted_text[7:0];
                        tx_start <= 1;
                        state <= 8;
                    end
                end

                8: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        tx_data <= decrypted_text[15:8];
                        tx_start <= 1;
                        state <= 9;
                    end
                end

                9: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        tx_data <= decrypted_text[23:16];
                        tx_start <= 1;
                        state <= 10;
                    end
                end

                10: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        tx_data <= decrypted_text[31:24];
                        tx_start <= 1;
                        state <= 0;
                    end
                end

                default: state <= 0;
            endcase
        end
    end

endmodule
