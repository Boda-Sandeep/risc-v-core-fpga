//-----------------------------------------------------------------
//                         RISC-V Core
//                            V1.0.1
//                     Ultra-Embedded.com
//                     Copyright 2014-2019
//
//                   admin@ultra-embedded.com
//
//                       License: BSD

//Summary of Fetch unit
// The fetch unit in a processor is responsible for fetching instructions from memory and preparing them for further processing in the pipeline. Its main tasks include:

//     Instruction Fetching: The fetch unit fetches instructions from the memory subsystem, typically using the program counter (PC) to determine the next instruction address.

//     Branch Handling: It handles branch instructions, determining the target address based on branch conditions and updating the program counter accordingly.

//     Instruction Buffering: The fetched instructions are often stored temporarily in a buffer or pipeline stage to facilitate subsequent stages of the pipeline.

//     Instruction Validity Checking: The fetch unit may perform checks on the validity of the fetched instructions, detecting any errors or exceptions during the fetch operation.

//     Interaction with Instruction Cache: In many modern processors, the fetch unit interacts with an instruction cache to improve performance by storing frequently accessed instructions.

//     Control Flow Handling: It manages control flow instructions, such as branches, jumps, and calls, ensuring the correct sequence of instruction execution.

//     Interface with Downstream Stages: The fetch unit provides instructions to downstream stages of the pipeline, such as the decode stage, execution stage, etc.

//     Handling Pipeline Stalls: The fetch unit may experience stalls in instruction fetching, for example, due to cache misses or other hazards. It manages these stalls and ensures the correct flow of instructions through the pipeline.

//     In summary, the fetch unit is crucial for the initial stage of instruction processing in a processor, ensuring a continuous flow of instructions through the pipeline while handling control flow changes and interacting with the memory subsystem.

module riscv_fetch
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MMU      = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i    
    ,input           rst_i
    ,input           fetch_accept_i   //next stage is ready to fetch the instruction
    ,input           icache_accept_i  //cache is ready to accept new request
    ,input           icache_valid_i   //instruction fetched is valid  
    ,input           icache_error_i  //error in cache
    ,input  [ 31:0]  icache_inst_i   //instruction recieved from the cache
    ,input           icache_page_fault_i //page fault in instruction cache
    ,input           fetch_invalidate_i //fetch is invalid
    ,input           branch_request_i   //branch request
    ,input  [ 31:0]  branch_pc_i     //program counter value for branch instruction
    ,input  [  1:0]  branch_priv_i   //privilege level

    // Outputs
    ,output          fetch_valid_o  //instruction is ready to flow downstream
    ,output [ 31:0]  fetch_instr_o //fetched instruction data
    ,output [ 31:0]  fetch_pc_o   //program counter fetched instruction
    ,output          fetch_fault_fetch_o //fault in fetch
    ,output          fetch_fault_page_o //page fault
    ,output          icache_rd_o   //need to read from instruction cache 
    ,output          icache_flush_o //signal to flush the invalid instruction
    ,output          icache_invalidate_o //signal to invalidate the instruction cache
    ,output [ 31:0]  icache_pc_o //pc related to the cache instruction
    ,output [  1:0]  icache_priv_o //privilege value related to the pc
    ,output          squash_decode_o //branch the signal to invalidate decode
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "riscv_defs.v"

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg         active_q;

wire        icache_busy_w;
wire        stall_w       = !fetch_accept_i || icache_busy_w || !icache_accept_i;

//-------------------------------------------------------------
// Buffered branch
//-------------------------------------------------------------
reg         branch_q;
reg [31:0]  branch_pc_q;
reg [1:0]   branch_priv_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    branch_q       <= 1'b0;
    branch_pc_q    <= 32'b0;
    branch_priv_q  <= `PRIV_MACHINE;
end
else if (branch_request_i)
begin
    branch_q       <= 1'b1;
    branch_pc_q    <= branch_pc_i;
    branch_priv_q  <= branch_priv_i;
end
else if (icache_rd_o && icache_accept_i)
begin
    branch_q       <= 1'b0;
    branch_pc_q    <= 32'b0;
end

wire        branch_w      = branch_q;
wire [31:0] branch_pc_w   = branch_pc_q;
wire [1:0]  branch_priv_w = branch_priv_q;

assign squash_decode_o    = branch_request_i;

//-------------------------------------------------------------
// Active flag
//-------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    active_q    <= 1'b0;
else if (branch_w && ~stall_w)
    active_q    <= 1'b1;

//-------------------------------------------------------------
// Stall flag
//-------------------------------------------------------------
reg stall_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    stall_q    <= 1'b0;
else
    stall_q    <= stall_w;

//-------------------------------------------------------------
// Request tracking
//-------------------------------------------------------------
reg icache_fetch_q; //indicate currently cache is fetching the instruction
reg icache_invalidate_q; //check the validity of the cache

// ICACHE fetch tracking
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_fetch_q <= 1'b0;
else if (icache_rd_o && icache_accept_i) 
    icache_fetch_q <= 1'b1;
else if (icache_valid_i) //if instruction is valid
    icache_fetch_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_invalidate_q <= 1'b0;
else if (icache_invalidate_o && !icache_accept_i)
    icache_invalidate_q <= 1'b1;
else
    icache_invalidate_q <= 1'b0;

//-------------------------------------------------------------
// PC
//-------------------------------------------------------------
reg [31:0]  pc_f_q;
reg [31:0]  pc_d_q;

wire [31:0] icache_pc_w;
wire [1:0]  icache_priv_w;
wire        fetch_resp_drop_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_f_q  <= 32'b0;
// Branch request
else if (branch_w && ~stall_w)
    pc_f_q  <= branch_pc_w;
// NPC
else if (!stall_w)
    pc_f_q  <= {icache_pc_w[31:2],2'b0} + 32'd4;

reg [1:0] priv_f_q;
reg       branch_d_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    priv_f_q  <= `PRIV_MACHINE;
// Branch request
else if (branch_w && ~stall_w)
    priv_f_q  <= branch_priv_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    branch_d_q  <= 1'b0;
// Branch request
else if (branch_w && ~stall_w)
    branch_d_q  <= 1'b1;
// NPC
else if (!stall_w)
    branch_d_q  <= 1'b0;

assign icache_pc_w       = pc_f_q;
assign icache_priv_w     = priv_f_q;
assign fetch_resp_drop_w = branch_w | branch_d_q;

// Last fetch address
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_d_q <= 32'b0;
else if (icache_rd_o && icache_accept_i)
    pc_d_q <= icache_pc_w;

//-------------------------------------------------------------
// Outputs
//-------------------------------------------------------------
assign icache_rd_o         = active_q & fetch_accept_i & !icache_busy_w;
assign icache_pc_o         = {icache_pc_w[31:2],2'b0};
assign icache_priv_o       = icache_priv_w;
assign icache_flush_o      = fetch_invalidate_i | icache_invalidate_q;
assign icache_invalidate_o = 1'b0;

assign icache_busy_w       =  icache_fetch_q && !icache_valid_i;

//-------------------------------------------------------------
// Response Buffer
//-------------------------------------------------------------
reg [65:0]  skid_buffer_q;
reg         skid_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    skid_buffer_q  <= 66'b0;
    skid_valid_q   <= 1'b0;
end 
// Instruction output back-pressured - hold in skid buffer
else if (fetch_valid_o && !fetch_accept_i)
begin
    skid_valid_q  <= 1'b1;
    skid_buffer_q <= {fetch_fault_page_o, fetch_fault_fetch_o, fetch_pc_o, fetch_instr_o};
end
else
begin
    skid_valid_q  <= 1'b0;
    skid_buffer_q <= 66'b0;
end

assign fetch_valid_o       = (icache_valid_i || skid_valid_q) & !fetch_resp_drop_w;
assign fetch_pc_o          = skid_valid_q ? skid_buffer_q[63:32] : {pc_d_q[31:2],2'b0};
assign fetch_instr_o       = skid_valid_q ? skid_buffer_q[31:0]  : icache_inst_i;

// Faults
assign fetch_fault_fetch_o = skid_valid_q ? skid_buffer_q[64] : icache_error_i;
assign fetch_fault_page_o  = skid_valid_q ? skid_buffer_q[65] : icache_page_fault_i;



endmodule
