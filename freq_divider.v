`timescale 1ns / 1ps
module freq_divider(
input clk,
output sclk);
reg [1:0]count;
always@(posedge clk)
    count=count+1;
assign sclk=count[1];
endmodule