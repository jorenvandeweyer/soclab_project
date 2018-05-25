module enemies(clock, reset, display_col, display_row, calc, enemy_color, hit);

    parameter SIZE = 64;

    input clock, reset;

    input [11:0] display_col;
    input [10:0] display_row;

    input calc;
    input hit;

    output reg [24:0] enemy_color;

    reg [31:0] counter;
    reg new_clock;
    reg create_enemy;
    wire [23:0] color;

    wire [3:0] address_ver, address_hor;
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

    reg counter_down;
    always @(posedge new_clock) begin
        if (reset) begin
            create_enemy <= 0;
        end else begin
            if (counter[27] && counter_down && state <= create_state) begin//(counter[27] && counter_down && state == create_state) begin
                create_enemy <= 1;
                counter_down <= 0;
            end else if (!counter[27]) begin
                counter_down <= 0;
            end else begin
                create_enemy <= 0;
            end
        end
    end

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

    wire [23:0] enemy_read_data;
    reg [23:0] enemy_write_data;
    reg [5:0] enemy_read_address;
    reg [5:0] enemy_write_address;
    reg enemy_wren;

    reg init;

    reg move;
    reg clear;
    reg passed;
    reg [5:0] last_empty;
    reg [23:0] insert_value;

    reg [2:0] state;

    wire [1:32] lfsr_out;

    lfsr lfsr(.clock(clock),
        .reset(reset),
        .out(lfsr_out)
    );

    parameter clean_state = 0, create_state = 1, move_state = 2, shoot_state = 3, idle = 4;
    reg creating_enemy;

    always @(posedge new_clock) begin
        if (reset) begin
            state <= clean_state;
            init <= 1;
            enemy_read_address <= 6'b0;
        end else begin
            if (!calc) begin
                if (init) begin
                    enemy_read_address <= 6'b0;
                    init <= 0;
                end else begin
                    if (enemy_read_data[0] && enemy_read_data[23:1] < {{display_row}, {display_col}}) begin
                        enemy_read_address <= enemy_read_address + 1;
                    end

                    // if (hit) begin
                    //     enemy_write_address <= enemy_read_address;
                    //     enemy_write_data <= 24'b0;
                    //     enemy_wren <= 1;
                    // end else begin
                    //     enemy_wren <= 0;
                    // end
                end
            end else begin
                if (calcWasZero) begin
                    state <= clean_state;
                    init <= 1;
                    enemy_read_address <= 6'b0;
                end else begin
                    case (state)
                        clean_state:
                            begin
                                if (init) begin
                                    enemy_read_address <= 0;
                                    init <= 0;
                                    passed <= 0;
                                    enemy_wren <= 0;
                                    clear <= 0;
                                    move <= 0;
                                    enemy_write_address <= 6'b0;
                                    enemy_write_data <= 24'b0;
                                    last_empty <= 6'b0;
                                end else begin
                                    if (clear) begin
                                        enemy_wren <= 1;
                                        enemy_write_data <= 24'b0;
                                        enemy_write_address <= enemy_read_address;
                                        clear <= 0;
                                    end else if (enemy_read_data[0] && move) begin
                                        enemy_write_address <= last_empty;
                                        enemy_write_data <= enemy_read_data;
                                        enemy_wren <= 1;
                                        last_empty <= last_empty + 1;
                                        clear <= 1;
                                    end else if (!enemy_read_data[0] && !move) begin
                                        enemy_wren <= 0;
                                        move <= 1;
                                        last_empty <= enemy_read_address;
                                        enemy_read_address <= enemy_read_address + 1;
                                    end else begin
                                        enemy_read_address <= enemy_read_address + 1;
                                        enemy_wren <= 0;
                                    end

                                    if (enemy_read_address == 6'b0 && passed) begin
                                        init <= 1;
                                        enemy_wren <= 0;
                                        state <= create_state;
                                    end
                                    passed = 1;
                                end
                            end
                        create_state:
                            begin
                                if (init) begin
                                    init <= 0;
                                    enemy_wren <= 0;
                                    passed = 0;
                                    creating_enemy <= 0;
                                end else begin
                                    if (create_enemy || creating_enemy) begin
                                        if (create_enemy) begin
                                            insert_value <= {{11'h080}, {lfsr_out[1:12]}, {1'b1}};
                                            creating_enemy <= 1;
                                        end else begin
                                            if (insert_value[0] && insert_value < enemy_read_data || !enemy_read_data[0]) begin
                                                enemy_write_data <= insert_value;
                                                insert_value <= enemy_read_data;
                                                enemy_write_address <= enemy_read_address;
                                                enemy_wren <= 1;
                                            end else begin
                                                enemy_wren <= 0;
                                            end

                                            enemy_read_address <= enemy_read_address + 1;

                                            if (enemy_read_address == 6'b0 && passed) begin
                                                init <= 1;
                                                enemy_wren <= 0;
                                                state <= move_state;
                                            end
                                            passed = 1;
                                        end
                                    end else begin
                                        state <= move_state;
                                    end
                                end
                            end
                        move_state:
                            begin
                                state <= shoot_state;
                            end
                        shoot_state:
                            begin
                                state <= idle;
                            end
                        default: state <= idle;
                    endcase
                end
            end
        end
    end

    assign address_ver = display_row[5:2] - enemy_read_data[18:15];
    assign address_hor = display_col[5:2] - enemy_read_data[6:3];
    assign address = {{address_ver}, {address_hor}};

    always @(posedge clock) begin
        if (reset) begin
            enemy_color <= 25'b0;
        end else begin
            if (enemy_read_data[0] && enemy_read_data[23:13] >= display_row && enemy_read_data[23:13] < display_row + SIZE && enemy_read_data[12:1] >= display_col && enemy_read_data[12:1] < display_col + SIZE) begin
                if (color == 24'h808000) begin
                    enemy_color <= {{color}, {1'b0}};
                end else begin
                    enemy_color <= {{color}, {1'b1}};
                end
            end else begin
                enemy_color <= 25'b0;
            end
        end
    end

    enemy_memory em (.clock(clock),
        .data(enemy_write_data),
        .rdaddress(enemy_read_address),
        .wraddress(enemy_write_address),
        .wren(enemy_wren),
        .q(enemy_read_data)
    );

    enemy_image image(.address(address), .clock(clock), .q(color_address));

    colorpalette cp(.address(color_address), .clock(clock), .q(color));
endmodule
