`default_nettype none

module procedural_graphics_core (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [1:0] mode,
    input  wire       freeze,
    input  wire       invert,

    output wire [7:0] pixel_out
);

    reg [7:0]  x;
    reg [7:0]  y;
    reg [15:0] time_ctr;

    reg [7:0] pixel;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            x        <= 8'd0;
            y        <= 8'd0;
            time_ctr <= 16'd0;
        end else begin
            x <= x + 8'd1;

            if (x == 8'hFF)
                y <= y + 8'd1;

            if (!freeze)
                time_ctr <= time_ctr + 16'd1;
        end
    end

    reg [7:0] next_pixel;

    always @(*) begin

        next_pixel = 8'h00;

        case (mode)

            // MODE 0 : Improved gradient plasma (unchanged from before)
            2'b00: begin
		    next_pixel =
			(y >> 1) +                          // PRIMARY gradient (must dominate)
			(x >> 3) +                          // very weak horizontal bias
			((x ^ y) >> 4) +                   // small texture only
			(time_ctr[7:0] >> 3);              // very subtle motion
		end

            // ============================================================
            // MODE 1 : 
            // ============================================================
            
            2'b01: begin
		    next_pixel =
			(x >> 2) +                     // smooth horizontal gradient
			(y >> 2) +                     // smooth vertical gradient
			((x + y + time_ctr[7:0]) >> 3); // very soft global drift
		end

            // MODE 2 : Interference Texture
            2'b10: begin
                next_pixel = ((x + time_ctr[7:0])
                           & (y ^ time_ctr[7:0]));
            end

            // MODE 3 : Pseudo Noise
            2'b11: begin
                next_pixel = ((x << 1) + x)
                           ^ (y + time_ctr[7:0]);
            end

            default: begin
                next_pixel = 8'h00;
            end

        endcase

        if (invert) begin
            next_pixel = ~next_pixel;
        end

    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pixel <= 8'd0;
        else
            pixel <= next_pixel;
    end

    assign pixel_out = pixel;

endmodule
