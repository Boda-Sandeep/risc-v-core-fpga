`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.12.2023 11:22:59
// Design Name: 
// Module Name: fetch_tb
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


module fetch_tb;

  // Define parameters
  localparam SUPPORT_MMU = 1;

  // Inputs
  reg clk;
  reg rst;
  reg fetch_accept;
  reg icache_accept;
  reg icache_valid;
  reg icache_error;
  reg [31:0] icache_inst;
  reg icache_page_fault;
  reg fetch_invalidate;
  reg branch_request;
  reg [31:0] branch_pc;
  reg [1:0] branch_priv;

  // Outputs
  wire fetch_valid;
  wire [31:0] fetch_pc;
  wire [31:0] fetch_instr;
  wire fetch_fault_fetch;
  wire fetch_fault_page;
  wire icache_rd;
  wire icache_flush;
  wire icache_invalidate;
  wire [31:0] icache_pc;
  wire [1:0] icache_priv;
  wire squash_decode;

  // Instantiate the module under test
  riscv_fetch uut (
    .clk_i(clk),
    .rst_i(rst),
    .fetch_accept_i(fetch_accept),
    .icache_accept_i(icache_accept),
    .icache_valid_i(icache_valid),
    .icache_error_i(icache_error),
    .icache_inst_i(icache_inst),
    .icache_page_fault_i(icache_page_fault),
    .fetch_invalidate_i(fetch_invalidate),
    .branch_request_i(branch_request),
    .branch_pc_i(branch_pc),
    .branch_priv_i(branch_priv),
    .fetch_valid_o(fetch_valid),
    .fetch_pc_o(fetch_pc),
    .fetch_instr_o(fetch_instr),
    .fetch_fault_fetch_o(fetch_fault_fetch),
    .fetch_fault_page_o(fetch_fault_page),
    .icache_rd_o(icache_rd),
    .icache_flush_o(icache_flush),
    .icache_invalidate_o(icache_invalidate),
    .icache_pc_o(icache_pc),
    .icache_priv_o(icache_priv),
    .squash_decode_o(squash_decode)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Stimulus generation
// Initialize inputs
initial begin
    rst = 1;
    fetch_accept = 0;
    icache_accept = 0;
    icache_valid = 0;
    icache_error = 0;
    icache_inst = 32'hDEADBEEF; // Initialize with some value
    icache_page_fault = 0;
    fetch_invalidate = 0;
    branch_request = 0;
    branch_pc = 32'hFACEBEEF; // Initialize with some value
    branch_priv = 2'b00; // Initialize with some value

    // Release reset after some cycles
    #10 rst = 0;

    // Apply stimuli
    // Test 1: Normal fetch operation
    #20 fetch_accept = 1;
    #20 icache_accept = 1;
 

    // Test 2: Branch request
    #20 branch_request = 1;
    #20 branch_pc = 32'hCAFEBABE;
    #20 branch_priv = 2'b01; // Set branch privilege level
    // Add more cycles for the branch operation to complete

    // Test 3: ICACHE error
    #20 icache_accept = 1;
    #20 icache_error = 1;

    // Test 4: ICACHE page fault
    #20 icache_accept = 1;
    #20 icache_page_fault = 1;

    // Test 5: ICACHE invalidation
    #20 fetch_invalidate = 1;

    // Test 6: PC handling
    #20 fetch_accept = 1;
    #20 icache_accept = 1;
    // Add more cycles for the fetch operation to complete
    
    // Test 7: Branch request with PC handling
    #20 branch_request = 1;
    #20 branch_pc = 32'hCAFEBABE;
    #20 branch_priv = 2'b01; // Set branch privilege level
    // Add more cycles for the branch operation to complete
    
    // Test 8: Privilege level change
    #20 branch_request = 1;
    #20 branch_pc = 32'hCAFEBABE;
    #20 branch_priv = 2'b11; // Set new privilege level
    // Add more cycles for the branch operation to complete
    
    // Test 9: ICACHE error with branch request
    #20 icache_accept = 1;
    #20 icache_error = 1;
    #20 branch_request = 1;
    #20 branch_pc = 32'hCAFEBABE;
    #20 branch_priv = 2'b01; // Set branch privilege level
    // Add more cycles for the branch operation to complete
    
    // Test 10: ICACHE page fault with privilege level change
    #20 icache_accept = 1;
    #20 icache_page_fault = 1;
    #20 branch_request = 1;
    #20 branch_pc = 32'hCAFEBABE;
    #20 branch_priv = 2'b11; // Set new privilege level
    // Add more cycles for the branch operation to complete


    // Stop simulation after a certain time
    #1000 $stop;
  end

  // Add waveform dumping or other simulation configurations as needed

endmodule


