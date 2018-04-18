module bouncing_ball(clock, reset, x_axis, y_axis, hor_pos, ver_pos);

	input clock;
	input reset;
    input [3:0] x_axis, y_axis;

	parameter HOR_FIELD = 799;
	parameter VER_FIELD = 599;
	parameter SIZE = 25;

	output reg [11:0] hor_pos;
	output reg [10:0] ver_pos;

	reg [31:0] counter;
	reg pulse;

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
                ver_pos = ver_pos - (y_axis - 7);
                hor_pos = hor_pos + (x_axis - 8);

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
endmodule
