module lfsr(clock, reset, out);

	input clock;
	input reset;
	
	output reg [1:32] out = 37;
	

	always @(posedge clock) begin
		if(reset) 
			out = 37;
		else
			//out = {out[16] ^ out[15] ^ out[13] ^ out[4], out[1:15]};
			out = {out[32] ^ out[22] ^ out[2], out[1:31]};
	end
	
endmodule 