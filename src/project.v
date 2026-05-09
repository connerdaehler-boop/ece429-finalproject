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
    // GPU-like control mapping (shader uniforms)
    // ============================================================

    wire [1:0] mode   = ui_in[1:0];
    wire       freeze = ui_in[2];
    wire       invert = ui_in[3];

    // ============================================================
    // Pixel output from fragment core
    // ============================================================

    wire [7:0] pixel;

    procedural_graphics_core graphics_core (
        .clk(clk),
        .rst_n(rst_n),

        .mode(mode),
        .freeze(freeze),
        .invert(invert),

        .pixel_out(pixel)
    );

    // ============================================================
    // IO mapping
    // ============================================================

    assign uo_out  = pixel;

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // ============================================================
    // keep signals alive
    // ============================================================

    wire _unused;
    assign _unused = &{ena, uio_in, 1'b0};

endmodule
