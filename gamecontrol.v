module gamecontrol(CLOCK_50, reset, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLOCK, VGA_SYNC_N, VGA_BLANK_N, wii_data, led, switch);

    input CLOCK_50, reset;
    input [47:0] wii_data;
    input switch;

    output [7:0] VGA_R, VGA_G, VGA_B;
    output reg [9:0] led;
    output VGA_CLOCK, VGA_SYNC_N;
    output reg VGA_HS, VGA_VS, VGA_BLANK_N;

    reg [7:0] red, green, blue;

    wire clock;
    wire [24:0] ship_color, bullet_color, enemy_color;
    wire [7:0] VGA_R, VGA_G, VGA_B;

    wire hsync, vsync, visible, calc;
    wire [11:0] display_col; // column number of pixel on the screen
    wire [10:0] display_row; // row number of pixel on the screen
    wire [11:0] ship_x;
    wire [10:0] ship_y;

    reg hit;

    PLL100MHz u1 (.refclk(CLOCK_50), .rst(reset), .outclk_0(clock));

    vga_controller #(.HOR_FIELD (1279),
                        .HOR_STR_SYNC(1327),
                        .HOR_STP_SYNC(1439),
                        .HOR_TOTAL (1687),
                        .VER_FIELD (1023),
                        .VER_STR_SYNC(1024),
                        .VER_STP_SYNC(1027),
                        .VER_TOTAL (1065) )
                    vga(clock, reset, display_col, display_row, visible, hsync, vsync, calc);


    ship #(.HOR_FIELD (1279),
            .VER_FIELD (1023),
            .SIZE(64) )
        ship(.clock(clock),
            .reset(reset),
            .display_col(display_col),
            .display_row(display_row),
            .wii_data(wii_data),
            .ship_color(ship_color),
            .hor_pos_out(ship_x),
            .ver_pos_out(ship_y)
        );

    bullets b(.clock(clock),
        .reset(reset),
        .fire(wii_data[4]),
        .x_axis(ship_x),
        .y_axis(ship_y),
        .display_col(display_col),
        .display_row(display_row),
        .calc(calc),
        .bullet_color(bullet_color),
        .hit(hit)
    );

    enemies e(.clock(clock),
        .reset(reset),
        .display_col(display_col),
        .display_row(display_row),
        .calc(calc),
        .enemy_color(enemy_color),
        .hit(hit)
    );

    wire [1:32] lfsr_out;

    lfsr lfsr(.clock(clock),
        .reset(reset),
        .out(lfsr_out)
    );

    always @(posedge clock) begin
        if (reset) begin
            hit <= 0;
        end else begin
            if (bullet_color[0] && enemy_color[0]) begin
                hit <= 1;
            end else begin
                hit <= 0;
            end
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            red = 0; green = 0; blue = 0;
        end else begin
            if (visible) begin
                if (ship_color[0]) begin
                    red = ship_color[24:17];
                    green = ship_color[16:9];
                    blue = ship_color[8:1];
                end else if (enemy_color[0]) begin
                    red = enemy_color[24:17];
                    green = enemy_color[16:9];
                    blue = enemy_color[8:1];
                end else if (bullet_color[0]) begin
                    red = bullet_color[24:17];
                    green = bullet_color[16:9];
                    blue = bullet_color[8:1];
                end else begin
                    if (lfsr_out[15] && lfsr_out[13] && lfsr_out[11] && lfsr_out[9] && lfsr_out[7] && lfsr_out[1:3] == 3'b111) begin
                        red = ~8'b0;
                        green = 8'b0;
                        blue = 8'b0;
                    end else if (lfsr_out [10] && lfsr_out[1:6] == 6'b111111) begin
                        red = ~8'b0;
                        green = ~8'b0;
                        blue = ~8'b0;
                    end else begin
                        red = 0;
                        green = 0;
                        blue = 0;
                    end
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
