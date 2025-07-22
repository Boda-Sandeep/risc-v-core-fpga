//`timescale 1ns / 1ps

//module img_transfer_uart (
//    input  wire        clk,         // UART input clock (e.g. 100 MHz)
//    input  wire        reset,       // reset signal (synchronous active-high)
//    input  wire        transmit,    // level-high to start UART transfers
//    output reg         TxD,         // UART serial output (idle high)
//    output wire        ea_tx,       // BRAM enable (always high)
//    output wire [16:0] addr_tx,     // BRAM address
//    output wire [31:0] din_tx,      // not used for write
//    input  wire [31:0] dout_tx      // 32-bit data input from BRAM
//);

//    // ---------------------------------------------------
//    // Control registers
//    // ---------------------------------------------------
//    reg [16:0] address;
//    reg        inc_addr;
//    reg  [3:0] bitcounter;      // counts 10 bits (start + 8 data + stop)
//    reg [13:0] counter;         // baud-rate divisor counter
//    reg  [1:0] byte_sel;        // which byte of data32 to send
//    reg [9:0]  shiftreg;        // 1(start) + 8 data + 1(stop)
//    reg [31:0] data32;          // latched 32-bit word
//    reg        load, shift, clear;
//    reg  [1:0] state, nextstate;

//    // ---------------------------------------------------
//    // Constant outputs
//    // ---------------------------------------------------
//    assign ea_tx   = 1'b1;
//    assign addr_tx = address;
//    assign din_tx  = 32'd0;

//    // ---------------------------------------------------
//    // Baud-rate & shift-register update
//    // ---------------------------------------------------
//    always @(posedge clk) begin
//        if (reset) begin
//            state      <= 2'd0;
//            counter    <= 14'd0;
//            bitcounter <= 4'd0;
//            address    <= 17'd0;
//        end else begin
//            // Baud divisor
//            counter <= counter + 14'd1;
//            if (counter >= 14'd10415) begin
//                counter <= 14'd0;
//                state   <= nextstate;

//                // On load, grab the right byte into shiftreg
//                if (load) begin
//                    case (byte_sel)
//                        2'd0: shiftreg <= {1'b1, data32[7:0],   1'b0};
//                        2'd1: shiftreg <= {1'b1, data32[15:8],  1'b0};
//                        2'd2: shiftreg <= {1'b1, data32[23:16], 1'b0};
//                        2'd3: shiftreg <= {1'b1, data32[31:24], 1'b0};
//                    endcase
//                end

//                // Clear bitcounter at start of each byte
//                if (clear)
//                    bitcounter <= 4'd0;

//                // Shift out one bit per baud tick
//                if (shift) begin
//                    shiftreg   <= shiftreg >> 1;
//                    bitcounter <= bitcounter + 4'd1;
//                end

//                // After all 4 bytes, advance address
//                if (inc_addr) begin
//                    address <= address + 17'd1;
//                end
//            end
//        end
//    end

//    // ---------------------------------------------------
//    // FSM & control signals
//    // ---------------------------------------------------
//    localparam IDLE     = 2'd0,
//               SEND     = 2'd1;

//    always @(posedge clk) begin
//        if (reset) begin
//            load     <= 1'b0;
//            shift    <= 1'b0;
//            clear    <= 1'b0;
//            inc_addr <= 1'b0;
//            TxD      <= 1'b1;
//            byte_sel <= 2'd0;
//        end else begin
//            // Default de-asserts
//            load     <= 1'b0;
//            shift    <= 1'b0;
//            clear    <= 1'b0;
//            inc_addr <= 1'b0;
//            TxD      <= 1'b1;

//            case (state)
//                // -----------------------------
//                // IDLE: wait for transmit==1
//                // -----------------------------
//                IDLE: begin
//                    if (transmit) begin
//                        // Latch initial word
//                        data32   <= dout_tx;
//                        byte_sel <= 2'd0;
//                        clear    <= 1'b1;
//                        load     <= 1'b1;
//                        nextstate<= SEND;
//                    end
//                end

//                // -----------------------------
//                // SEND: shift out 4 bytes
//                // -----------------------------
//                SEND: begin
//                    if (bitcounter < 4'd10) begin
//                        // Ongoing shift: drive TxD, increment bitcounter
//                        TxD   <= shiftreg[0];
//                        shift <= 1'b1;
//                        nextstate <= SEND;
//                    end else if (byte_sel < 2'd3) begin
//                        // Move to next byte of same word
//                        byte_sel <= byte_sel + 2'd1;
//                        clear    <= 1'b1;
//                        load     <= 1'b1;
//                        nextstate<= SEND;
//                    end else begin
//                        // All 4 bytes done: advance address if within C matrix
//                        clear <= 1'b1;
//                        // Only send the 16 result words (C[0][0] through C[3][3])
//                        if (address < 17'd15)
//                            inc_addr <= 1'b1;
//                        nextstate <= IDLE;
//                    end
//                end

//                default: begin
//                    nextstate <= IDLE;
//                end
//            endcase
//        end
//    end

//endmodule
`timescale 1ns / 1ps

module img_transfer_uart(
input clk, //UART input clock
input reset, // reset signal
input transmit, //btn signal to trigger the UART communication
output reg TxD, // Transmitter serial output. TxD will be held high during reset, or when no transmissions aretaking place 
//output reg done
output ea_tx,
output [16:0]addr_tx,
output [31:0]din_tx,
input [31:0]dout_tx
    );

//internal variables
reg [16:0] address;
reg donef;
reg inc_addr;
reg [3:0] bitcounter; //4 bits counter to count up to 10
reg [13:0] counter; //14 bits counter to count the baud rate, counter = clock / baud rate
reg state,nextstate; // initial & next state variable
// 10 bits data needed to be shifted out during transmission.
//The least significant bit is initialized with the binary value  0  (a start bit) A binary value  1  is introduced in the most significant bit 
reg [9:0] rightshiftreg; 
wire [31:0]dout;
reg shift; //shift signal to start bit shifting in UART
reg load; //load signal to start loading the data into rightshift register and add start and stop bit
reg clear; //clear signal to start reset the bitcounter for UART transmission
//[7:0] data;
//the following assignment is for the controlling logic of the bram
assign ea_tx = 1;
assign addr_tx = address;
assign din_tx = 0;
assign dout = dout_tx;
reg  [1:0] byte_sel;
//assign data = dout;
//UART transmission logic
always @ (posedge clk) 
begin 
    if (reset) 
	   begin // reset is asserted (reset = 1)
        state <=0; // state is idle (state = 0)
        counter <=0; // counter for baud rate is reset to 0 
        bitcounter <=0; //counter for bit transmission is reset to 0
        address<=0;
        byte_sel<=0;
       end
    else begin
         counter <= counter + 1; //counter for baud rate generator start counting 
            if (counter >= 10415) //if count to 10416 (from 0 to 10415)
               begin 
                  state <= nextstate; //previous state change to next state
                  counter <=0; // reset couter to 0
                  if (load) begin
                    case (byte_sel)
                        2'd0: rightshiftreg <= {1'b1, dout[7:0],   1'b0};
                        2'd1: rightshiftreg <= {1'b1, dout[15:8],  1'b0};
                        2'd2: rightshiftreg <= {1'b1, dout[23:16], 1'b0};
                        2'd3: rightshiftreg <= {1'b1, dout[31:24], 1'b0};
                    endcase
                end
		          if (clear) bitcounter <=0; // reset the bitcounter if clear is asserted
                  if (inc_addr)begin
                      if(byte_sel<3)byte_sel<=byte_sel+1; 
                      else begin
                          byte_sel<=0;
                          address<=address+1;
                      end
                  end
//		          if (donef) done<=1; else done<=0;
                  if (shift) 
                     begin // if shift is asserted
                        rightshiftreg <= rightshiftreg >> 1; //right shift the data as we transmit the data from lsb
                        bitcounter <= bitcounter + 1; //count the bitcounter
                     end
               end
         end
end 

//state machine

always @ (posedge clk) //trigger by positive edge of clock, 
//always @ (state or bitcounter or transmit)
begin
    load <=0; // set load equal to 0 at the beginning
    shift <=0; // set shift equal to 0 at the beginning
    clear <=0; // set clear equal to 0 at the beginning
    TxD <=1; // set TxD equals to during no transmission
    inc_addr <=0;
//    donef<=0;
    case (state)
        0: begin // idle state
             if (transmit) begin // assert transmit input
             nextstate <= 1; // Move to transmit state
             load <=1; // set load to 1 to prepare to load the data
             shift <=0; // set shift to 0 so no shift ready yet
             clear <=0; // set clear to 0 to avoid clear any counter
             end 
		else begin // if transmit not asserted
             nextstate <= 0; // next state is back to idle state
             TxD <= 1; 
             end
           end
        1: begin  // transmit state
             if (bitcounter >=10) begin // check if transmission is complete or not. If complete
             nextstate <= 0; // set nextstate back to 0 to idle state
//             donef<=1;
             if(address<200)begin
                inc_addr <=1;
                end
             clear <=1; // set clear to 1 to clear all counters
             end 
		else begin // if transmisssion is not complete 
             nextstate <= 1; // set nextstate to 1 to stay in transmit state
             TxD <= rightshiftreg[0]; // shift the bit to output TxD
             shift <=1; // set shift to 1 to continue shifting the data
             end
           end
         default: nextstate <= 0;                      
    endcase
end

endmodule