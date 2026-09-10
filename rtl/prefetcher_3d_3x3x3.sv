`timescale 1ns/1ps

`default_nettype none

module prefetcher_3d_3x3x3 (
    input   logic           clk,
    input   logic           reset,
    input   logic   [31:0]  address_i,  // input address
    output  logic   [31:0]  address_o,  // output address(es)

    input   logic           valid,      // 1 if the input address is valid, else 0
    output  logic           ready       // 1 if the output address is valid, else 0
);

typedef enum logic [2:0] {
    IDLE,
    X_MINUS,
    X_PLUS,
    Y_MINUS,
    Y_PLUS,
    Z_MINUS,
    Z_PLUS
} state_t;

logic [31:0] stored_address;

logic [1:0] x, y, z;

logic x_minus_valid, x_plus_valid, y_minus_valid, y_plus_valid, z_minus_valid, z_plus_valid;

state_t state, next_state;

always_comb begin
    if (state == IDLE) begin
        x = 2'(address_i % 3);
        y = 2'(address_i / 3 % 3);
        z = 2'(address_i / 9);
    end else begin
        x = 2'(stored_address % 3);
        y = 2'(stored_address / 3 % 3);
        z = 2'(stored_address / 9);
    end

    x_minus_valid = x > 0;
    x_plus_valid = x < 2;
    y_minus_valid = y > 0;
    y_plus_valid = y < 2;
    z_minus_valid = z > 0;
    z_plus_valid = z < 2;

    unique case (state)
        IDLE: begin
            if (valid) begin
                if (x_minus_valid)
                    next_state = X_MINUS;
                else if (x_plus_valid)
                    next_state = X_PLUS;
                else if (y_minus_valid)
                    next_state = Y_MINUS;
                else if (y_plus_valid)
                    next_state = Y_PLUS;
                else if (z_minus_valid)
                    next_state = Z_MINUS;
                else if (z_plus_valid)
                    next_state = Z_PLUS;
                else
                    next_state = IDLE;
            end else
                next_state = IDLE;

            ready = 1'b0;
            address_o = 32'b0;
        end

        X_MINUS: begin
            if (x_plus_valid)
                next_state = X_PLUS;
            else if (y_minus_valid)
                next_state = Y_MINUS;
            else if (y_plus_valid)
                next_state = Y_PLUS;
            else if (z_minus_valid)
                next_state = Z_MINUS;
            else if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address - 1;
            ready = 1'b1;
        end

        X_PLUS: begin
            if (y_minus_valid)
                next_state = Y_MINUS;
            else if (y_plus_valid)
                next_state = Y_PLUS;
            else if (z_minus_valid)
                next_state = Z_MINUS;
            else if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address + 1;
            ready = 1'b1;
        end

        Y_MINUS: begin
            if (y_plus_valid)
                next_state = Y_PLUS;
            else if (z_minus_valid)
                next_state = Z_MINUS;
            else if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address - 3;
            ready = 1'b1;
        end

        Y_PLUS: begin
            if (z_minus_valid)
                next_state = Z_MINUS;
            else if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address + 3;
            ready = 1'b1;
        end

        Z_MINUS: begin
            if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address - 9;
            ready = 1'b1;
        end

        Z_PLUS: begin
            next_state = IDLE;

            address_o = stored_address + 9;
            ready = 1'b1;
        end

        default: begin
            next_state = IDLE;
            ready = 1'b0;
            address_o = 32'b0;
        end
    endcase


end

always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        stored_address <= 32'b0;
    end else begin
        if (state == IDLE && valid)
            stored_address <= address_i;
        state <= next_state;
    end
end

endmodule

`default_nettype wire
