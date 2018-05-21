module bullets(clock, reset, fire, x_axis, y_axis, display_col, display_row, calc, bullet_color, hit);

    parameter SIZE = 32;
    parameter SPEED = 8;

    input clock, reset;
    input fire;
    input [11:0] x_axis, display_col;
    input [10:0] y_axis, display_row;
    input calc;
    input hit;

    output reg [24:0] bullet_color;

    reg [31:0] counter;
    reg new_clock;
    wire [23:0] color;

    wire [3:0]  address_ver, address_hor;
    wire [7:0] address;
    wire [3:0] color_address;

    always @(posedge clock) begin
        if (reset) begin
            counter <= 0;
            new_clock <= 0;
        end else begin
            counter <= counter + 1;
            if (counter[2] == 1'b1) begin
                new_clock <= 1;
            end else begin
                new_clock <= 0;
            end
        end
    end

    reg [23:0] fire_bullet;
    reg fire_tick;
    // Shoot bullet
    always @(posedge new_clock) begin
        if(reset) begin
            fire_bullet <= 24'b0;
            fire_tick <= 1;
        end else begin
            if (!fire) begin
                if (fire_tick) begin
                    fire_tick <= 0;
                    fire_bullet <= {{y_axis}, {x_axis}, {1'b1}};
                end else if (calc && state == insert_state && !init) begin
                    fire_bullet <= 24'b0;
                end
            end else begin
                fire_tick <= 1;
            end
        end
    end

    wire [23:0] bullet_read_data;
    reg [23:0] bullet_write_data;
    reg [5:0] bullet_read_address;
    reg [5:0] bullet_write_address;
    reg bullet_wren;

    reg init;

    reg move;
    reg clear;
    reg passed;
    reg [5:0] last_empty;
    reg [23:0] insert_value;

    bullet_memory bm (.clock(clock),
        .data(bullet_write_data),
        .rdaddress(bullet_read_address),
        .wraddress(bullet_write_address),
        .wren(bullet_wren),
        .q(bullet_read_data)
    );

    reg resetState;
    reg calcWasZero;

    always @(posedge new_clock) begin
        if (reset) begin
            resetState <= 0;
            calcWasZero <= 0;
        end else if (calc) begin
            if (resetState) begin
                resetState <= 0;
                calcWasZero <= 1;
            end else begin
                calcWasZero <= 0;
            end
        end else begin
            resetState <= 1;
        end
    end

    parameter clean_state = 0, insert_state = 1, move_state = 2, idle = 3;

    reg [1:0] state;

    always @(posedge new_clock) begin
        if (reset) begin
            init <= 1;
            state <= clean_state;

            passed <= 0;
            move <= 0;
            clear <= 0;

            last_empty <= 6'b0;

            insert_value <= 24'b0;

            bullet_read_address <= 6'b0;
            bullet_write_address <= 6'b0;
            bullet_write_data <= 24'b0;
            bullet_wren <= 0;
        end else begin
            if (!calc) begin
                if (init) begin
                    bullet_read_address <= 6'b0;
                    init <= 0;
                end else begin
                    if (bullet_read_data[0] && bullet_read_data[23:1] < {{display_row}, {display_col}}) begin
                        bullet_read_address <= bullet_read_address + 1;
                    end

                    if (hit) begin
                        bullet_write_address <= bullet_read_address;
                        bullet_write_data <= 24'b0;
                        bullet_wren <= 1;
                    end else begin
                        bullet_wren <= 0;
                    end
                end
            end else begin
                if (calcWasZero) begin
                    init = 1;
                    state <= clean_state;
                    bullet_read_address <= 6'b0;
                end else begin
                    case (state)
                        clean_state:
                            begin
                                if (init) begin
                                    bullet_read_address <= 0;
                                    init <= 0;
                                    passed <= 0;
                                    bullet_wren <= 0;
                                    clear <= 0;
                                    move <= 0;
                                    bullet_write_address <= 6'b0;
                                    bullet_write_data <= 24'b0;
                                    last_empty <= 6'b0;
                                end else begin
                                    if (clear) begin
                                        bullet_wren <= 1;
                                        bullet_write_data <= 24'b0;
                                        bullet_write_address <= bullet_read_address;
                                        clear <= 0;
                                    end else if (bullet_read_data[0] && move) begin
                                        bullet_write_address <= last_empty;
                                        bullet_write_data <= bullet_read_data;
                                        bullet_wren <= 1;
                                        last_empty <= last_empty + 1;
                                        clear <= 1;
                                    end else if (!bullet_read_data[0] && !move) begin
                                        bullet_wren <= 0;
                                        move <= 1;
                                        last_empty <= bullet_read_address;
                                        bullet_read_address <= bullet_read_address + 1;
                                    end else begin
                                        bullet_read_address <= bullet_read_address + 1;
                                        bullet_wren <= 0;
                                    end

                                    if (bullet_read_address == 6'b0 && passed) begin
                                        init <= 1;
                                        bullet_wren <= 0;
                                        state <= insert_state;
                                    end
                                    passed = 1;
                                end
                            end
                        insert_state:
                            begin
                                if (init) begin
                                    if (fire_bullet[0]) begin
                                        init <= 0;
                                        insert_value <= fire_bullet;
                                        bullet_read_address <= 0;
                                        passed = 0;
                                    end else begin
                                        state <= move_state;
                                    end
                                end else begin
                                    if (insert_value[0] && insert_value < bullet_read_data || !bullet_read_data[0]) begin
                                        bullet_write_data <= insert_value;
                                        bullet_write_address <= bullet_read_address;
                                        insert_value <= bullet_read_data;
                                        bullet_wren <= 1;
                                    end else begin
                                        bullet_wren <= 0;
                                    end

                                    bullet_read_address <= bullet_read_address + 1;

                                    if (bullet_read_address == 6'b0 && passed) begin
                                        init <= 1;
                                        bullet_wren <= 0;
                                        state <= move_state;
                                    end
                                    passed = 1;
                                end
                            end
                        move_state:
                            begin
                                if (init) begin
                                    init <= 0;
                                    bullet_read_address <= 0;
                                    passed <= 0;
                                end else begin
                                    if (bullet_read_data[0]) begin
                                        if (bullet_read_data[23:13] - SPEED < bullet_read_data[23:13]) begin
                                            bullet_write_data <= {{bullet_read_data[23:13] - SPEED}, {bullet_read_data[12:1]}, {1'b1}};
                                        end else begin
                                            bullet_write_data <= 24'b0;
                                        end
                                        bullet_write_address <= bullet_read_address;
                                        bullet_wren <= 1;
                                    end else begin
                                        bullet_wren <= 0;
                                    end

                                    bullet_read_address <= bullet_read_address + 1;

                                    if (bullet_read_address == 6'b0 && passed) begin
                                        init <= 1;
                                        bullet_wren <= 0;
                                        state <= idle;
                                    end

                                    passed = 1;
                                end
                            end
                        default: state <= idle;
                    endcase
                end
            end
        end
    end

    assign address_ver = display_row[4:1] - bullet_read_data[17:14];
    assign address_hor = display_col[4:1] - bullet_read_data[5:2];
    assign address = {{address_ver}, {address_hor}};

    always @(posedge clock) begin
        if (reset) begin
            bullet_color <= 25'b0;
        end else begin
            if (bullet_read_data[0] && bullet_read_data[23:13] >= display_row && bullet_read_data[23:13] < display_row + SIZE && bullet_read_data[12:1] >= display_col && bullet_read_data[12:1] < display_col + SIZE) begin
                if (color == 24'h808000) begin
                    bullet_color <= {{color}, {1'b0}};
                end else begin
                    bullet_color <= {{color}, {1'b1}};
                end
            end else begin
                bullet_color <= 25'b0;
            end
        end
    end

    colorpalette cp(.address(color_address), .clock(clock), .q(color));

    bullet_image image(.address(address), .clock(clock), .q(color_address));

endmodule
