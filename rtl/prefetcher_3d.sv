`timescale 1ns/1ps

`default_nettype none

module prefetcher_3d #(
    parameter int X_SIZE = 3,
    parameter int Y_SIZE = 3,
    parameter int Z_SIZE = 3
) (
    input   logic           clk,
    input   logic           reset,
    input   logic   [31:0]  address_i,  // input address
    output  logic   [31:0]  address_o,  // output address(es)

    input   logic           valid,      // 1 if the input address is valid, else 0
    output  logic           ready       // 1 if the output address is valid, else 0
);

// Bits for coordinates, edge case of dimension = 1 accounted for
localparam int X_BITS = (X_SIZE <= 1) ? 1 : $clog2(X_SIZE);
localparam int Y_BITS = (Y_SIZE <= 1) ? 1 : $clog2(Y_SIZE);
localparam int Z_BITS = (Z_SIZE <= 1) ? 1 : $clog2(Z_SIZE);

// States
typedef enum logic [2:0] {
    IDLE,
    X_MINUS,
    X_PLUS,
    Y_MINUS,
    Y_PLUS,
    Z_MINUS,
    Z_PLUS
} state_t;

// Latched input address
logic [31:0] stored_address;

// Address coordinates
logic [X_BITS-1:0] x;
logic [Y_BITS-1:0] y;
logic [Z_BITS-1:0] z;

// Neighbors validity
logic x_minus_valid, x_plus_valid, y_minus_valid, y_plus_valid, z_minus_valid, z_plus_valid;

state_t state, next_state;

always_comb begin
    // Get coordinates
    if (state == IDLE) begin
        x = X_BITS'(address_i % X_SIZE);
        y = Y_BITS'(address_i / X_SIZE % Y_SIZE);
        z = Z_BITS'(address_i / (X_SIZE * Y_SIZE));
    end else begin
        x = X_BITS'(stored_address % X_SIZE);
        y = Y_BITS'(stored_address / X_SIZE % Y_SIZE);
        z = Z_BITS'(stored_address / (X_SIZE * Y_SIZE));
    end

    // Get validity
    x_minus_valid = X_SIZE > 1 && x > 0;
    x_plus_valid = X_SIZE > 1 && x < X_BITS'(X_SIZE - 1);
    y_minus_valid = Y_SIZE > 1 && y > 0;
    y_plus_valid = Y_SIZE > 1 && y < Y_BITS'(Y_SIZE - 1);
    z_minus_valid = Z_SIZE > 1 && z > 0;
    z_plus_valid = Z_SIZE > 1 && z < Z_BITS'(Z_SIZE - 1);

    // Find next state
    unique case (state)
        IDLE: begin
            // Added check for address_i in range
            if (valid && address_i < X_SIZE * Y_SIZE * Z_SIZE) begin
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

            address_o = stored_address - X_SIZE;
            ready = 1'b1;
        end

        Y_PLUS: begin
            if (z_minus_valid)
                next_state = Z_MINUS;
            else if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address + X_SIZE;
            ready = 1'b1;
        end

        Z_MINUS: begin
            if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address - X_SIZE * Y_SIZE;
            ready = 1'b1;
        end

        Z_PLUS: begin
            next_state = IDLE;

            address_o = stored_address + X_SIZE * Y_SIZE;
            ready = 1'b1;
        end

        default: begin
            next_state = IDLE;
            ready = 1'b0;
            address_o = 32'b0;
        end
    endcase


end

// Assign defaults and next state, latch input address
always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        stored_address <= 32'b0;
    end else begin
        // Added check for address_i in range
        if (state == IDLE && valid && address_i < X_SIZE * Y_SIZE * Z_SIZE)
            stored_address <= address_i;
        state <= next_state;
    end
end

endmodule

`default_nettype wire
