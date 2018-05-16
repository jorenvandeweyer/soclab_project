module bullets(clock, reset, fire, x_axis, y_axis, display_col, display_row, calc, bullet_color);

    input clock, reset;
    input fire;
    input [11:0] x_axis, display_col;
    input [10:0] y_axis, display_row;
    input calc;

    output reg [24:0] bullet_color;

    reg [31:0] counter;
    reg new_clock;

    wire [23:0] color;

    colorpalette cp(.address(4'b0010), .clock(clock), .q(color));

    always @(posedge clock) begin
        if (reset) begin
            bullet_color = 24'b0;
        end else begin
            if (bullet_read_data[0] && display_col == bullet_read_data[12:1] && display_row == bullet_read_data[23:13]) begin
                bullet_color = {{color}, {1'b1}};
            end else begin
                bullet_color = 24'b0;
            end
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            counter = 0;
            new_clock = 0;
        end else begin
            counter = counter + 1;
            if (counter[2] == 1'b1) begin
                new_clock = 1;
            end else begin
                new_clock = 0;
            end
        end
    end

    reg [23:0] fire_bullet;

    // Shoot bullet
    always @(posedge new_clock) begin
        if(reset) begin
            fire_bullet = 24'b0;
        end else begin
            if (!fire) begin
                fire_bullet = {{x_axis}, {y_axis}, {1'b1}};
            end else if (calc && !insert_value_in_array) begin
                fire_bullet = 24'b0;
            end
        end
    end

    reg [23:0] bullet_write_data;
    wire [23:0] bullet_read_data;
    reg [5:0] bullet_read_address;
    reg [5:0] bullet_write_address;
    reg bullet_wren;

    reg clear_empty_spaces;
    reg insert_value_in_array;
    reg move_bullets_state;

    reg move;
    reg clear;
    reg passed;
    reg [5:0] last_empty;
    reg [23:0] switch_value;
    reg [23:0] insert_value;

    bullet_memory2 bm2 (.clock(clock),
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
            resetState = 0;
            calcWasZero = 0;
        end else if (calc) begin
            if (resetState) begin
                resetState = 0;
            end else if (calcWasZero) begin
                resetState = 1;
            end
            calcWasZero = 0;
        end else begin
            calcWasZero = 1;
        end
    end

    always @(posedge new_clock) begin
        if (reset) begin
            clear_empty_spaces = 1;
            insert_value_in_array = 1;
            move_bullets_state = 1;

            move = 0;
            clear = 0;
            passed = 0;

            last_empty = 5'b0;

            switch_value = 24'b0;
            insert_value = 24'b0;

            bullet_read_address = 6'b0;
            bullet_write_address = 6'b0;
            bullet_wren = 0;
        end else begin
            if (calc) begin
                if (resetState) begin
                    clear_empty_spaces = 1;
                    insert_value_in_array = 1;
                    move_bullets_state = 1;

                    move = 0;
                    clear = 0;
                    passed = 0;

                    last_empty = 5'b0;

                    switch_value = 24'b0;
                    insert_value = 24'b0;

                    bullet_read_address = 6'b0;
                    bullet_write_address = 6'b0;
                    bullet_wren = 0;
                end else if (clear_empty_spaces) begin
                    if (clear) begin
                        clear = 0;
                        bullet_wren = 1;
                        bullet_write_data = 23'b0;
                    end else if (bullet_read_data[0] && move) begin
                        bullet_wren = 0;
                        bullet_write_address = last_empty;
                        clear = 1;
                        last_empty = last_empty + 1;
                    end else if (!bullet_read_data[0] && !move) begin
                        last_empty = bullet_read_address;
                        move = 1;
                        bullet_read_address = bullet_read_address + 1;
                        passed = 1;
                    end else begin
                        bullet_read_address = bullet_read_address + 1;
                        passed = 1;
                    end

                    if (passed && bullet_read_address == 6'b0) begin
                        clear_empty_spaces = 0;
                        passed = 0;
                        bullet_wren = 0;
                    end
                end else if (insert_value_in_array && fire_bullet[0]) begin
                    if (!passed) begin
                        insert_value = fire_bullet;
                    end

                    if (insert_value < bullet_read_data || !bullet_read_data[0]) begin
                        bullet_write_data = insert_value;
                        bullet_write_address = bullet_read_address;
                        insert_value = bullet_read_data;
                        bullet_wren = 1;
                    end else begin
                        bullet_wren = 0;
                    end

                    if (passed && bullet_read_address == 6'b0) begin
                        insert_value_in_array = 0;
                        passed = 0;
                        bullet_wren = 0;
                    end else begin
                        passed = 1;
                        bullet_read_address = bullet_read_address + 1;
                    end

                end else if (move_bullets_state) begin
                    //MOVE BULLETS UP
                    if (bullet_read_data[0]) begin
                        bullet_write_data = {{bullet_read_data[23:12]}, {bullet_read_data[11:1] - 1}, {1'b1}};
                        bullet_write_address = bullet_read_address;
                        bullet_wren = 1;
                    end else begin
                        bullet_wren = 0;
                    end

                    if (passed && bullet_read_address == 6'b0) begin
                        move_bullets_state = 0;
                        passed = 0;
                        bullet_wren = 0;
                    end else begin
                        passed = 1;
                        bullet_read_address = bullet_read_address + 1;
                    end

                end else begin
                    bullet_read_address = 0;
                end
            end else begin
                if ({{display_row}, {display_col}, {1'b1}} > bullet_read_data) begin
                    bullet_read_address = bullet_read_address + 1;
                end
            end
        end
    end

    //Collision detection
    // always @(posedge clock) begin
    //     if(reset) begin
    //
    //     end else begin
    //         for(integer i = 23; i < 768; i = i + 24) begin
    //             if(bullets[i - 12:i-22] <= 11'b0) begin
    //                 bullets[i - 12:i-22] = ~11'b0;
    //             end
    //         end
    //     end
    // end

endmodule
