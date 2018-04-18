module vgasystem1(CLOCK_50, KEY, SW, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLOCK, VGA_SYNC_N, VGA_BLANK_N, Received_data );
    input CLOCK_50;
    input [3:0] KEY;
    input [9:0] SW;
    input [47:0] Received_data;

    output [7:0] VGA_R, VGA_G, VGA_B;
    output VGA_CLOCK, VGA_SYNC_N;
    output reg VGA_HS, VGA_VS, VGA_BLANK_N;

    wire [7:0] VGA_R, VGA_G, VGA_B;
    reg [7:0] red, green, blue;

    // assign clock = CLOCK_50;
    wire clock;
    assign reset = SW[0];
    assign VGA_R = red;
    assign VGA_G = green;
    assign VGA_B = blue;

    // add one additional clock cycle to compensate for videoDAC delay
    always @(posedge clock) VGA_HS = hsync;
    always @(posedge clock) VGA_VS = vsync;
    always @(posedge clock) VGA_BLANK_N = hsync & vsync;
    assign VGA_CLOCK = clock;
    assign VGA_SYNC_N = 1'b0;
    wire hsync, vsync;
    wire visible;
    wire [15:0] address;
    wire [14:0] color;
    wire [11:0] display_col; // column number of pixel on the screen
    wire [10:0] display_row; // row number of pixel on the screen

    wire [11:0] hor_ball;
	wire [10:0] ver_ball;

    assign address = {{display_col[7:0]}, {display_row[7:0]}};

    PLL100MHz u1 (.refclk(CLOCK_50), .rst(reset), .outclk_0(clock));

    vga_controller #(.HOR_FIELD (1279),
                        .HOR_STR_SYNC(1327),
                        .HOR_STP_SYNC(1439),
                        .HOR_TOTAL (1687),
                        .VER_FIELD (1023),
                        .VER_STR_SYNC(1024),
                        .VER_STP_SYNC(1027),
                        .VER_TOTAL (1065) )
                    vga(clock, reset, display_col, display_row, visible, hsync, vsync);

    bouncing_ball #(.HOR_FIELD (1279),
                    .VER_FIELD (1023),
                    .SIZE(32) )
                ball (clock, reset, Received_data[6:3], hor_ball, ver_ball);

    always @(posedge clock) begin
        if (reset) begin
            red = 0; green = 0; blue = 0;
        end else begin
            if (visible) begin
                if(display_col >= hor_ball && display_col <= hor_ball + 32 && display_row >= ver_ball && display_row <= ver_ball + 32) begin
                    red = {{color[14:10]}, {3'b0}};
                    green = {{color[9:5]}, {3'b0}};
                    blue = {{color[4:0]}, {3'b0}};
                end else begin
                    red = {SW[8:6], {5{display_row[7] ^ display_col[7]}}};
                    green = {SW[5:3], {5{display_row[7] ^ display_col[7]}}};
                    blue = {SW[2:0], {5{display_row[7] ^ display_col[7]}}};
                end
            end else begin
                red = 0;
                green = 0;
                blue = 0;
            end
        end
    end
endmodule
