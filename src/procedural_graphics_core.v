`default_nettype none

module procedural_graphics_core (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [1:0] mode,
    input  wire       freeze,
    input  wire       invert,

    output wire [7:0] pixel_out
);

    // ============================================================
    // Raster generator (GPU scanout)
    // ============================================================

    reg [7:0] x;
    reg [7:0] y;
    reg [15:0] time_ctr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x <= 0;
            y <= 0;
            time_ctr <= 0;
        end else begin
            x <= x + 1;
            if (x == 8'hFF)
                y <= y + 1;

            if (!freeze)
                time_ctr <= time_ctr + 1;
        end
    end

    // ============================================================
    // FEATURE LAYER
    // ============================================================

    wire [7:0] t = time_ctr[7:0];

    wire [7:0] gx = x >> 2;
    wire [7:0] gy = y >> 2;

    wire [7:0] noise =
        (x + (y >> 1) + (t >> 3)) ^ ((x >> 1) + y);

    wire [7:0] field =
        (x + y) >> 1;

    // ============================================================
    // SHADER STAGE
    // ============================================================

    reg signed [15:0] dx;
    reg signed [15:0] dy;
    reg [15:0] tmp;

    reg [7:0] next_pixel;

    always @(*) begin

        tmp = 0;
        next_pixel = 0;

        case (mode)

            // ====================================================
            // MODE 0 : vertical gradient
            // ====================================================
            2'b00: begin
                tmp = (y >> 1) + (y >> 2) + (x >> 4);
                next_pixel = tmp[7:0];
            end

            // ====================================================
            // MODE 1 : directional lighting
            // ====================================================
            2'b01: begin
                tmp = (x >> 1) + (y >> 2) + ((x + y) >> 3) + (t >> 5);
                next_pixel = tmp[7:0];
            end

            // ====================================================
            // MODE 2 : circular light source (stable)
            // ====================================================
            2'b10: begin
                dx = $signed({1'b0, x}) - 16'sd128;
                dy = $signed({1'b0, y}) - 16'sd128;

                tmp = dx * dx + dy * dy;
                tmp = tmp >> 4;

                tmp = 16'd255 - tmp;

                if (tmp[15] || tmp > 255)
                    tmp = 0;

                next_pixel = tmp[7:0];
            end

            // ====================================================
            // MODE 3 : FINAL FIX — isotropic hash noise (NO LINE STRUCTURE)
            // ====================================================
            2'b11: begin

                // fully non-directional spatial hash core
                tmp =
                    (x * 17) ^
                    (y * 23) ^
                    ((x ^ y) * 29) ^
                    (t * 11);

                // avalanche mixing (breaks residual correlation)
                tmp = tmp ^ (tmp >> 4);
                tmp = tmp + (tmp << 3);
                tmp = tmp ^ (tmp >> 7);

                // final decorrelation pass
                tmp = tmp * 9;
                tmp = tmp ^ (tmp >> 5);

                next_pixel = tmp[7:0];

            end

        endcase

        // ========================================================
        // POST PROCESSING
        // ========================================================

        if (invert)
            next_pixel = ~next_pixel;

    end

    // ============================================================
    // OUTPUT REGISTER
    // ============================================================

    reg [7:0] pixel;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pixel <= 0;
        else
            pixel <= next_pixel;
    end

    assign pixel_out = pixel;

endmodule
