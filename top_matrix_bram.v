`timescale 1ns / 1ps 

module top_matrix_bram(        
//    input  wire fclk,
    input wire clk,
    input  wire rst,
    input  wire start,             // Start matrix multiplication
    input  wire transfer_start,    // Start UART transfer
    input  wire transfer_reset,    // Reset UART
    output wire busy,
    output wire done, 
    output wire TxD                // UART output to FPGA pin
);

//      BRAM Interface Signals
    wire [16:0]  bram_addr_matrix;  
    wire        bram_we_matrix;
    wire [31:0]  bram_din_matrix;
    wire        bram_en_matrix;


    wire [16:0]  bram_addr_uart;
    wire        bram_en_uart;
    wire        bram_we_uart;
    wire [31:0]  bram_din_uart;

    wire [16:0]  bram_addr_mux;
    wire        bram_ren_mux;
    wire        bram_we_mux;
    wire [31:0]  bram_din_mux;
    wire [31:0]  bram_dout;
//    wire clk;
//    freq_divider fd(fclk,clk);


    //   Matrix Multiplier Instance 
    matrix_multiplier matrix (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_base(17'd0),
        .b_base(17'd64),
        .c_base(17'd128),
        .busy(busy), 
        .done(done),
        .bram_en(bram_en_matrix),  
        .bram_we(bram_we_matrix),
        .bram_addr(bram_addr_matrix),
        .bram_din(bram_din_matrix),
        .bram_dout(bram_dout)
    );
//    //   UART Transfer Module 
    img_transfer_uart uart (
        .clk(clk),
        .reset(transfer_reset), 
        .transmit(transfer_start),
        .TxD(TxD),
        .ea_tx(bram_en_uart),
        .addr_tx(bram_addr_uart),
        .din_tx(bram_din_uart),     // not used, so set to 0
        .dout_tx(bram_dout)
    );

//    //        BRAM Control MUX 
    assign bram_addr_mux = (start) ? bram_addr_matrix :
                           (transfer_start) ? bram_addr_uart : 17'd0;

    assign bram_ren_mux   = (start) ? bram_en_matrix : 
                           (transfer_start) ? bram_en_uart : 1'b0;

    assign bram_we_mux   = (start) ? bram_we_matrix :
                           (transfer_start) ? 1'b0 : 1'b0;

    assign bram_din_mux  = (start) ? bram_din_matrix :
                           (transfer_start) ? bram_din_uart : 32'd0;

    //         BRAM Instance 
    BRAM bram(  
        .clk(clk),
        .en(1),
        .wen(bram_we_mux),
        .ren(bram_ren_mux),
        .addr(bram_addr_mux),
        .din(bram_din_mux),
        .dout(bram_dout)
    );

endmodule