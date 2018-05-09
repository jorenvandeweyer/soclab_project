module ship (clock, reset, display_col, display_row, wii_data, ship_color, hor_pos_out, ver_pos_out);

    parameter HOR_FIELD = 799;
    parameter VER_FIELD = 599;
    parameter SIZE = 64;

    input clock, reset;
    input [11:0] display_col;
    input [10:0] display_row;
    input [47:0] wii_data;

    output reg [24:0] ship_color;
    output reg [11:0] hor_pos_out;
    output reg [10:0] ver_pos_out;

    always @(posedge clock) hor_pos_out = hor_pos;
    always @(posedge clock) ver_pos_out = ver_pos;

    reg [11:0] hor_pos;
    reg [10:0] ver_pos;
    reg [31:0] counter;
	reg pulse;

    wire [3:0] x_axis;
    wire [3:0] y_axis;
    wire [3:0] color_address;
    wire [7:0] address;
    wire [23:0] color;
    wire [3:0]  address_ver, address_hor;
    assign x_axis = wii_data[45:42];
    assign y_axis = wii_data[37:34];

    always @(posedge clock) begin
        if (reset) begin
            counter = 0;
            pulse = 0;
        end else begin
            if (counter[19] == 1'b1) begin
                counter = 32'b0;
                pulse = 1;
            end else begin
                counter = counter + 1;
                pulse = 0;
            end
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            hor_pos = 0;
            ver_pos = 0;
        end else begin
            if (pulse) begin
                ver_pos = ver_pos - (y_axis - 8);
                hor_pos = hor_pos + (x_axis - 7);

                if (hor_pos <= 1) begin
                    hor_pos = (HOR_FIELD - SIZE) - 1;
                end
                if (hor_pos + SIZE > HOR_FIELD) begin
                    hor_pos = 1;
                end

                if (ver_pos <= 1) begin
                    ver_pos = (VER_FIELD - SIZE) - 1;
                end
                if (ver_pos + SIZE > VER_FIELD) begin
                    ver_pos = 1;
                end
            end
        end
    end

    assign address_ver = display_row[5:2] - ver_pos[5:2];
    assign address_hor = display_col[5:2] - hor_pos[5:2];
    assign address = {{address_ver}, {address_hor}};

    always @(posedge clock) begin
        if (reset) begin
            ship_color = 24'b0;
        end else begin
            if (display_col >= hor_pos && display_col <= hor_pos + SIZE && display_row >= ver_pos && display_row <= ver_pos + SIZE) begin
                if (color == 24'h808000) begin
                    ship_color = {{color}, {1'b0}};
                end else begin
                    ship_color = {{color}, {1'b1}};
                end
            end else begin
                ship_color = 24'b0;
            end
        end
    end

    ship_image image(.address(address), .clock(clock), .q(color_address));

    colorpalette cp(.address(color_address), .clock(clock), .q(color));
endmodule
