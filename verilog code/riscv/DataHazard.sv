`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.12.2023 00:49:58
// Design Name: 
// Module Name: DataHazard
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
`include "riscv_defs.v"
//`define INST_LW 32'h2003
//`define INST_LW_MASK 32'h707f

module DataHazard(
input [31:0]opcode_i,
input clk_i,reset_i,
output logic stall
);

logic [4:0] ra_idx_w  ;
logic [4:0] rb_idx_w  ;
logic lw;
logic [4:0]rd_1;
logic [4:0]rd_2;

//checking for load instruction
assign ra_idx_w   = opcode_i[19:15];
assign rb_idx_w   = opcode_i[24:20];
assign  lw = (opcode_i & `INST_LW_MASK) == `INST_LW  ;
assign  rd_2 = opcode_i[11:7];

always@(posedge clk_i)begin
    if (reset_i) begin
        rd_1 = 5'b0;
        stall=0;
    end else begin
    if(rd_1==5'b0 ) stall=0;
    else if(((opcode_i & `INST_JAL_MASK) == `INST_JAL)|((opcode_i & `INST_LUI_MASK) == `INST_LUI)    |
                        ((opcode_i & `INST_AUIPC_MASK) == `INST_AUIPC) | ((opcode_i & `INST_ECALL_MASK) == `INST_ECALL) |
                        ((opcode_i & `INST_EBREAK_MASK) == `INST_EBREAK)) stall =0;
    else if(((opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW)            ||
            ((opcode_i & `INST_CSRRS_MASK) == `INST_CSRRS)            ||
            ((opcode_i & `INST_CSRRC_MASK) == `INST_CSRRC)            ||
            ((opcode_i & `INST_CSRRWI_MASK) == `INST_CSRRWI)          ||
            ((opcode_i & `INST_CSRRSI_MASK) == `INST_CSRRSI)          ||
            ((opcode_i & `INST_CSRRCI_MASK) == `INST_CSRRCI)) begin
        if(opcode_i[14]) stall =0;
        else if(lw & (rd_1==ra_idx_w))    
                    stall=1; //for lw instruction
        else stall=0;
    end
    else if(((opcode_i & `INST_JALR_MASK) == `INST_JALR) | opcode_i[6:0] == 7'b0010011 | opcode_i[6:0] == 7'b0000011) begin
             if(lw & (rd_1==ra_idx_w))    
                stall=1; //for lw instruction
            else stall=0;
    end
    else begin
        if(lw & ((rd_1==ra_idx_w)| (rd_1==rb_idx_w)))    
            stall=1; //for lw instruction
        else stall=0;
    end
    rd_1 =rd_2;
    end
end

endmodule

