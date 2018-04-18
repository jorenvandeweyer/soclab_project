module counter(clock_in, reset, clock_out);

output 		clock_out; 
input 		reset;
input 		clock_in;

reg [30:0] 	counter;
reg 		clock_out;

always @(posedge clock_in)
	if (reset) begin
		counter = 0;
		clock_out = 0;
	end else begin
		if (counter == 500000) begin	//every 10ms
			clock_out = 1;
			counter = 0;
		end else begin		
			clock_out = 0;	
			counter = counter + 1;
		end
			
	end				

endmodule
