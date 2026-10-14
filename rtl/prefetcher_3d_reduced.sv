`timescale 1ns/1ps

`default_nettype none

module prefetcher_3d_reduced #(
    parameter int X_SIZE = 3,
    parameter int Y_SIZE = 3,
    parameter int Z_SIZE = 3
) (
    input  logic          clk,
    input  logic          reset,
    input  logic [31:0]   address_i,
    output logic [31:0]   address_o,

    input  logic          valid,
    output logic          ready
);

localparam int PLANE_SIZE = X_SIZE * Y_SIZE;
localparam int TOTAL_SIZE = X_SIZE * Y_SIZE * Z_SIZE;

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

state_t state, next_state;

logic [31:0] stored_address;
logic [31:0] active_address;

logic [31:0] row_position;
logic [31:0] plane_position;

logic x_minus_valid;
logic x_plus_valid;
logic y_minus_valid;
logic y_plus_valid;
logic z_minus_valid;
logic z_plus_valid;

always_comb begin

    // Use live input while accepting a request.
    // Use the latched address while processing it.
    if (state == IDLE)
        active_address = address_i;
    else
        active_address = stored_address;

    // Only two modulo operations are required.
    row_position   = active_address % X_SIZE;
    plane_position = active_address % PLANE_SIZE;

    // X boundaries: position within the current row.
    x_minus_valid = (X_SIZE > 1) &&
                    (row_position > 0);

    x_plus_valid  = (X_SIZE > 1) &&
                    (row_position < X_SIZE - 1);

    // Y boundaries: position within the current plane.
    y_minus_valid = (Y_SIZE > 1) &&
                    (plane_position >= X_SIZE);

    y_plus_valid  = (Y_SIZE > 1) &&
                    (plane_position < PLANE_SIZE - X_SIZE);

    // Z boundaries can be determined directly from the address.
    z_minus_valid = (Z_SIZE > 1) &&
                    (active_address >= PLANE_SIZE);

    z_plus_valid  = (Z_SIZE > 1) &&
                    (active_address < TOTAL_SIZE - PLANE_SIZE);

    unique case (state)

        IDLE: begin
            if (valid && address_i < TOTAL_SIZE) begin
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
            end else begin
                next_state = IDLE;
            end

            address_o = 32'b0;
            ready     = 1'b0;
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
            ready     = 1'b1;
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
            ready     = 1'b1;
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
            ready     = 1'b1;
        end

        Y_PLUS: begin
            if (z_minus_valid)
                next_state = Z_MINUS;
            else if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address + X_SIZE;
            ready     = 1'b1;
        end

        Z_MINUS: begin
            if (z_plus_valid)
                next_state = Z_PLUS;
            else
                next_state = IDLE;

            address_o = stored_address - PLANE_SIZE;
            ready     = 1'b1;
        end

        Z_PLUS: begin
            next_state = IDLE;

            address_o = stored_address + PLANE_SIZE;
            ready     = 1'b1;
        end

        default: begin
            next_state = IDLE;
            address_o  = 32'b0;
            ready      = 1'b0;
        end

    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        state          <= IDLE;
        stored_address <= 32'b0;
    end else begin
        if (state == IDLE &&
            valid &&
            address_i < TOTAL_SIZE)
            stored_address <= address_i;

        state <= next_state;
    end
end

endmodule

`default_nettype wire
