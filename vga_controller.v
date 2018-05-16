module vga_controller(clock, reset, display_col, display_row, visible, hsync, vsync, calc);

	// 72 Hz 800 x 600 VGA - 50MHz clock

	parameter HOR_FIELD = 799;
	parameter HOR_STR_SYNC = 855;
	parameter HOR_STP_SYNC = 978;
	parameter HOR_TOTAL = 1042;
	parameter VER_FIELD = 599;
	parameter VER_STR_SYNC = 636;
	parameter VER_STP_SYNC = 642;
	parameter VER_TOTAL= 665;

	input clock;
	input reset;

	output reg [11:0] display_col;
	output reg [10:0] display_row;
	output reg visible;
	output reg hsync, vsync;
    output reg calc;

	reg line_start_pulse;

    always @(posedge clock) begin
        if (reset) begin
            calc = 0;
        end else begin
            if (display_row > VER_FIELD) begin
                calc = 1;
            end else begin
                calc = 0;
            end
        end
    end

	always @(posedge clock) begin
		if (reset) begin
			display_col = 0;
			display_row = 0;
			hsync = 1;
			vsync = 1;
		end else begin
			display_col <= display_col + 1;

			if (display_col == HOR_TOTAL) begin
				line_start_pulse <= 1;
				display_col <= 0;
			end else if (display_col == HOR_STR_SYNC) begin
				hsync <= 0;
			end else if (display_col == HOR_STP_SYNC) begin
				hsync <= 1;
			end

			if (line_start_pulse == 1) begin
				line_start_pulse <= 0;
				display_row <= display_row + 1;
			end

			if(display_row == VER_TOTAL) begin
				display_row <= 0;
			end if(display_row == VER_STR_SYNC) begin
				vsync <= 0;
			end if(display_row == VER_STP_SYNC) begin
				vsync <= 1;
			end
		end
	end

	always @(posedge clock) begin
		if (display_row == VER_FIELD || display_col == HOR_FIELD) begin
			visible <= 0;
		end else if (display_row < VER_FIELD && display_col < HOR_FIELD) begin
			visible <= 1;
		end
	end
endmodule
