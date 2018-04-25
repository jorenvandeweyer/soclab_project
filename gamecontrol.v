module gamecontrol(CLOCK_50, reset, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLOCK, VGA_SYNC_N, VGA_BLANK_N, wii_data);

    input CLOCK_50, reset;
    input [47:0] wii_data;

    output [7:0] VGA_R, VGA_G, VGA_B;
    output VGA_CLOCK, VGA_SYNC_N;
    output reg VGA_HS, VGA_VS, VGA_BLANK_N;

    wire clock;
    wire [24:0] ship_color;
    wire [7:0] VGA_R, VGA_G, VGA_B;
    reg [7:0] red, green, blue;

    wire hsync, vsync, visible;
    wire [11:0] display_col; // column number of pixel on the screen
    wire [10:0] display_row; // row number of pixel on the screen

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


    ship #(.HOR_FIELD (1279),
            .VER_FIELD (1023),
            .SIZE(64) )
        ship(clock, reset, display_col, display_row, wii_data, ship_color);

    always @(posedge clock) begin
        if (reset) begin
            red = 0; green = 0; blue = 0;
        end else begin
            if (visible) begin
                if (ship_color[0]) begin
                    red = ship_color[24:17];
                    green = ship_color[16:9];
                    blue = ship_color[8:1];
                end else begin
                    red = {~3'b0, {5{display_row[7] ^ display_col[7]}}};
                    green = {~3'b0, {5{display_row[7] ^ display_col[7]}}};
                    blue = {~3'b0, {5{display_row[7] ^ display_col[7]}}};
                    //background
                end
            end else begin
                red = 0;
                green = 0;
                blue = 0;
            end
        end
    end

    always @(posedge clock) VGA_HS = hsync;
    always @(posedge clock) VGA_VS = vsync;
    always @(posedge clock) VGA_BLANK_N = hsync & vsync;
    assign VGA_CLOCK = clock;
    assign VGA_SYNC_N = 1'b0;
    assign VGA_R = red;
    assign VGA_G = green;
    assign VGA_B = blue;
endmodule
