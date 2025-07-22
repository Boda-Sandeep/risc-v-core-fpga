`timescale 1ns / 1ps

module top_matrix_bram_tb;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg transfer_start;
    reg transfer_reset;

    // Outputs
    wire busy;
    wire done;
    wire TxD;

    // Instantiate the Unit Under Test (UUT)
    top_matrix_bram uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .transfer_start(transfer_start),
        .transfer_reset(transfer_reset),
        .busy(busy),
        .done(done),
        .TxD(TxD)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Stimulus
    initial begin
        // Initialize Inputs
        rst = 1;
        start = 0;
        transfer_start = 0;


        // Wait 20ns and release reset
        #20;
        rst = 0;

        // Wait a few cycles then start matrix multiplication
        #50;
        start = 1;

        // Wait for the done signal
        wait(done);
        start=0;
        #20;
                transfer_reset = 1;
                #30;
                transfer_reset = 0;
                #50;
                
        
        // Start UART transmission
        transfer_start = 1;
        #10;
//        transfer_start = 0;

        // Wait some time to observe UART output
        #50000;

        $finish;  
    end

endmodule