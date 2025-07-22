`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.12.2023 16:09:14
// Design Name: 
// Module Name: memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module memory (
	input 			clk_i,
	input 			reset_i,
	input  [31:0]	daddr_i,
	input  [31:0]	dwdata_i,
	output reg [31:0]	drdata_o,
	output reg accept,
	output reg acknowledge,
	input   [1:0]	dsize_i,
	input 			drd_i,
	input 			dwr_i,  
	input   [3:0]	dbe_w
);
// initialising memory with 0 by default
	reg [31:0]	data_mem [18640:16640]; //Size reduced. as the actual size will not be needed for verification
	wire [7:0]  data_b [3:0];
	wire [15:0] data_w [1:0];
	wire [31:0] data_in;
	
	wire a;
	wire c;
	
	assign c = (dsize_i ==  2'd0);
	assign a = (dsize_i ==  2'd1);
	
 
	    assign data_b[0] 		 = dbe_w[0] ? dwdata_i[7:0] : {8{1'b0}};
        assign data_b[1]         = dbe_w[1] ? dwdata_i[15:8] : {8{1'b0}};
        assign data_b[2]         = dbe_w[2] ? dwdata_i[23:16] : {8{1'b0}};
        assign data_b[3]         = dbe_w[3] ? dwdata_i[31:24] : {8{1'b0}};
        assign data_w[0]         = (dbe_w[1:0] == 2'b11) ? dwdata_i[15:0] : {16{1'b0}};
        assign data_w[1]         = (dbe_w[3:2] == 2'b11) ? dwdata_i[31:16] : {16{1'b0}};
        assign data_in             = (c) ? {data_b[3], data_b[2], data_b[1], data_b[0]} : (a) ? {data_w[1], data_w[0]} : dwdata_i; 

	always @(posedge clk_i) begin
		if(reset_i) begin
		    accept=0;
		    acknowledge=1;
			drdata_o = 0;  // data out will be 0 at reset
		end
		else begin
			if(dwr_i) begin
				data_mem[daddr_i[31:2]] <= data_in;
			end
			accept=1;
			drdata_o = drd_i ? data_mem[daddr_i[31:2]] : drdata_o;  //dataout will be at posedge clk and hold for other cycles
		end
	end

endmodule 
