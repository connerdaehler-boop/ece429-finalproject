/*
 * Tiny Tapeout Top-Level Wrapper
 *
 * Connects procedural graphics core to Tiny Tapeout IO.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_connerdaehler_boop (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // Control Signals
    // ============================================================

    wire [1:0] mode;
    wire       freeze;
    wire       invert;

    assign mode   = ui_in[1:0];
    assign freeze = ui_in[2];
    assign invert = ui_in[3];

    // ============================================================
    // Graphics Output
    // ============================================================

    wire [7:0] pixel;

    // ============================================================
    // Graphics Core
    // ============================================================

    procedural_graphics_core graphics_core (
        .clk(clk),
        .rst_n(rst_n),

        .mode(mode),
        .freeze(freeze),
        .invert(invert),

        .pixel_out(pixel)
    );

    // ============================================================
    // Tiny Tapeout Outputs
    // ============================================================

    assign uo_out  = pixel;

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // ============================================================
    // Prevent Unused Signal Warnings
    // ============================================================

    wire _unused;
    assign _unused = &{ena, uio_in, 1'b0};

endmodule
