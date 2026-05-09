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
    // GPU FEATURE STAGE (important architectural step)
    // ============================================================

    wire [7:0] t = time_ctr[7:0];

    // spatial basis (low frequency space)
    wire [7:0] gx = x >> 2;
    wire [7:0] gy = y >> 2;

    // controlled low-noise field (no grid resonance)
    wire [7:0] noise =
        (x + (y >> 1) + (t >> 3)) ^ ((x >> 1) + y);

    // smooth interaction field (prevents banding)
    wire [7:0] field =
        (x + y) >> 1;

    // ============================================================
    // FRAGMENT SHADER STAGE
    // ============================================================

    reg [7:0] next_pixel;

    always @(*) begin

        next_pixel = 0;

        case (mode)

            // ====================================================
		// MODE 0 : vertical height lighting (true gradient shader)
		// ====================================================
		2'b00: begin
		    next_pixel =
			(y >> 1) +              // dominant vertical gradient
			(y >> 2) +              // soft falloff shaping
			(x >> 4);               // very weak horizontal texture
		end

		// ====================================================
		// MODE 1 : directional / angled lighting (different basis)
		// ====================================================
		2'b01: begin
		    next_pixel =
			(x >> 1) +              // horizontal dominance (key difference)
			(y >> 2) +              // weaker vertical component
			((x + y) >> 3) +       // diagonal lighting bias
			(t >> 5);              // subtle animation drift
		end

            // ====================================================
            // MODE 2 : interference shader (stable waves, no XOR banding)
            // ====================================================
            2'b10: begin
                next_pixel =
                    (x + y) +
                    ((x >> 1) + (y >> 2)) ^
                    (t >> 3);
            end

            // ====================================================
            // MODE 3 : procedural texture (de-coupled noise material)
            // ====================================================
            2'b11: begin
                next_pixel =
                    noise +
                    (gx << 1) +
                    (gy << 1);
            end

        endcase

        // ========================================================
        // POST-PROCESSING STAGE (GPU-like final step)
        // ========================================================

        if (invert)
            next_pixel = ~next_pixel;

    end

    // ============================================================
    // OUTPUT PIPELINE REGISTER
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
