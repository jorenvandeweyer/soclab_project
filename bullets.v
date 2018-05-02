module bullets(clock, reset, bullets);

    /*parameter AMOUNT = 32;
    parameter SIZE = 24; //hor_pos + ver_pos + active = 12 + 11 + 1
    parameter INDEX_SIZE = 5;*/

    parameter SPEED = 2;
    parameter DIMENSION = 10;

    input clock, reset;

    output reg [767:0] bullets;//(AMOUNT * SIZE) - 1 aantal bits
    reg [31:0] counter;
    reg pulse;
    reg [4:0] index;//iNDEX_SIZE - 1 aantal bits

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

    //Movement up
    always @(posedge clock) begin
        if(reset) begin
            bullets = 768'b0;
        end else begin
            /*if(index >= 32) begin
                index = 5'b0;
            end else begin
                if(bullets[index * 24]) begin
                    bullets[(index * 24) - 12:(index * 24) - 22] = bullets[(index * 24) - 12:(index * 24) - 22] - SPEED;
                end

                index = index + 1;
            end*/

            for(integer i = 23; i < 768; i = i + 24) begin
                if(bullets[i]) begin
                    bullets[i - 12:i-22] = bullets[i - 12:i-22] - SPEED;
                end
            end
        end
    end

    //Collision detection
    always @(posedge clock) begin
        if(reset) begin

        end else begin
            for(integer i = 23; i < 768; i = i + 24) begin
                if(bullets[i - 12:i-22] <= 11'b0) begin
                    bullets[i - 12:i-22] = ~11'b0;
                end
            end
        end
    end

endmodule
