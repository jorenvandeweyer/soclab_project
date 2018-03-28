module bouncing_ball(clock, reset, control, hor_pos, ver_pos);

	input clock;
	input reset;
    input [3:0] control;

	parameter HOR_FIELD = 799;
	parameter VER_FIELD = 599;
	parameter SIZE = 25;

	output reg [11:0] hor_pos;
	output reg [10:0] ver_pos;

	reg [31:0] counter;
	reg pulse;

    assign up = control[3];
    assign down = control[2];
    assign left = control[1];
    assign right = control[0];

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
                if (up) begin
                    ver_pos = ver_pos + 1;
                end
                if (down) begin
                    ver_pos = ver_pos - 1;
                end
                if (right) begin
                    hor_pos = hor_pos - 1;
                end
                if (left) begin
                    hor_pos = hor_pos + 1;
                end

                if (hor_pos <= 0) begin
                    hor_pos = (HOR_FIELD - SIZE) - 1;
                end
                if (hor_pos + SIZE > HOR_FIELD) begin
                    hor_pos = 1;
                end

                if (ver_pos <= 0) begin
                    ver_pos = (VER_FIELD - SIZE) - 1;
                end
                if (ver_pos + SIZE > VER_FIELD) begin
                    ver_pos = 1;
                end
            end
        end
    end

endmodule
