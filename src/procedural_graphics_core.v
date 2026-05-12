`default_nettype none

module procedural_graphics_core (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] in_pixel,
    input  wire       in_valid,

    input  wire [1:0] mode,
    input  wire       freeze,
    input  wire       invert,

    output reg  [7:0] pixel_out
);

    // ============================================================
    // SCAN POSITION
    // ============================================================

    reg [7:0] x, y;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x <= 0;
            y <= 0;
        end else if (in_valid && !freeze) begin
            if (x == 8'hFF) begin
                x <= 0;
                y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end

    // ============================================================
    // SHADER VARIABLES
    // ============================================================

    reg signed [15:0] dx;
    reg signed [15:0] dy;
    reg signed [31:0] dist2;
    reg signed [15:0] light;
    reg signed [15:0] tmp;

    reg signed [8:0] lx;
    reg signed [8:0] ly;

    always @(*) begin

        tmp = 0;
        pixel_out = 0;

        // default light center
        lx = 9'sd128;
        ly = 9'sd128;

        case (mode)

            // ====================================================
            // MODE 0: TOP LIGHT
            // ====================================================
            2'b00: begin
                lx = 9'sd128;
                ly = 9'sd0;
            end

            // ====================================================
            // MODE 1: BOTTOM-RIGHT LIGHT
            // ====================================================
            2'b01: begin
                lx = 9'sd220;
                ly = 9'sd220;
            end

            // ====================================================
            // MODE 2: EXTREME PIN LIGHT (FIXED)
            // ====================================================
            2'b10: begin
                lx = 9'sd128;
                ly = 9'sd128;
            end

            // ====================================================
            // MODE 3: UNCHANGED (your working mode)
            // ====================================================
            2'b11: begin
                lx = 9'sd128;
                ly = 9'sd128;
            end

        endcase

        // ============================================================
        // DISTANCE FIELD
        // ============================================================

        dx = $signed({1'b0, x}) - lx;
        dy = $signed({1'b0, y}) - ly;

        dist2 = dx*dx + dy*dy;

        light = 16'sd255 - (dist2 >>> 7);

        // ============================================================
        // MODE MIXING
        // ============================================================

        case (mode)

            // ----------------------------------------------------
            // MODE 0
            // ----------------------------------------------------
            2'b00: begin
                tmp = light + (in_pixel >>> 1);
            end

            // ----------------------------------------------------
            // MODE 1
            // ----------------------------------------------------
            2'b01: begin
                tmp = light + (in_pixel >>> 1) + (x >>> 3);
            end

            // ----------------------------------------------------
            // MODE 2: EXTREME SPOTLIGHT
            // ----------------------------------------------------
            2'b10: begin

                tmp = dist2 >> 5;

                // nonlinear-like falloff shaping
                tmp = tmp + (tmp >> 1);
                tmp = tmp + (tmp >> 2);

                tmp = 16'sd255 - tmp;

                if (tmp < 0)
                    tmp = 0;

                tmp = tmp + (in_pixel >> 5);

            end

            // ----------------------------------------------------
            // MODE 3 (UNCHANGED)
            // ----------------------------------------------------
            2'b11: begin
                tmp = light + (in_pixel >>> 1);
            end

        endcase

        // ============================================================
        // CLAMP
        // ============================================================

        if (tmp < 0)
            tmp = 0;
        if (tmp > 255)
            tmp = 255;

        pixel_out = tmp[7:0];

        if (invert)
            pixel_out = ~pixel_out;

    end

endmodule
