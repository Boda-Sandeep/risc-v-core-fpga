////note that N,M,K must be multiples of BLOCK
module matrix_multiplier #(
    parameter N     = 4,
    parameter M     = 4,
    parameter K     = 4,
    parameter BLOCK = 2
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [16:0] a_base,
    input  wire [16:0] b_base,
    input  wire [16:0] c_base,
    output reg         busy,
    output reg         done,
    output reg         bram_en,
    output reg         bram_we,
    output reg [16:0]  bram_addr,
    output reg [31:0]  bram_din,
    input  wire [31:0] bram_dout
);

    // FSM States
    localparam IDLE         = 4'd0,
               READ_A       = 4'd1,
               IDLE_A1      = 4'd2,
               IDLE_A2      = 4'd3,
               TAKE_A       = 4'd4,
               PREP_B       = 4'd5,
               READ_B       = 4'd6,
               IDLE_B1      = 4'd7,
               IDLE_B2      = 4'd8,
               TAKE_B       = 4'd9,
               COMPUTE_INIT = 4'd10,
               COMPUTE_STEP = 4'd11,
               WRITE_C      = 4'd12,
               IDLE_C1      = 4'd13,
               IDLE_C2      = 4'd14,
               TAKE_C       = 4'd15,
               PREP_RC      = 5'd16,
               READ_C       = 5'd17,
               IDLE_RC1     = 5'd18,
               IDLE_RC2     = 5'd19,
               TAKE_RC      = 5'd20,        
               DONE         = 5'd21;

    // Tile counts
    localparam NB = N/BLOCK;
    localparam MB = M/BLOCK;
    localparam KB = K/BLOCK;

    // BRAM-backed matrices and accumulator
    reg [31:0] A      [0:N-1][0:M-1];
    reg [31:0] B      [0:M-1][0:K-1];
    reg [31:0] temp_C [0:N-1][0:K-1];

    // FSM state & indices
    reg [4:0] state;
    reg [31:0] li, lj;               // read indices
    reg [31:0] bi_idx, bj_idx, bk_idx;// tile indices
    reg [31:0] ii, jj, kk;           // inner-block loops
    reg [31:0] si, sj;               // write indices
    integer x,y;

    always @(posedge clk ) begin
        if (rst) begin
            state     <= IDLE;
            busy      <= 1'b0;
            done      <= 1'b0;
            bram_en   <= 1'b0;
            bram_we   <= 1'b0;
            bram_addr <= 0;
            bram_din  <= 0;
            li <= 0; lj <= 0;
            bi_idx <= 0; bj_idx <= 0; bk_idx <= 0;
            ii <= 0; jj <= 0; kk <= 0;
            si <= 0; sj <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0; busy <= 1'b0;
                    if (start) begin
                        busy    <= 1'b1;
                        li <= 0; lj <= 0;
                        bram_en <= 1'b1; bram_we <= 1'b0;
                        state   <= READ_A;
                    end
                end

                // READ MATRIX A ---------
                READ_A: begin
                    bram_addr <= (a_base + ((li*M + lj)*4))>>2 ;
                    state     <= IDLE_A1;
                end
                IDLE_A1: state <= IDLE_A2;
                IDLE_A2: state <= TAKE_A;
                TAKE_A: begin
                    A[li][lj] <= bram_dout;
                    $display("A[%0d][%0d] = %0d", li, lj, bram_dout);
                    if (li == N-1 && lj == M-1) begin
                        state <= PREP_B;
                    end else begin
                        if (lj == M-1) begin li <= li+1; lj <= 0; end
                        else lj <= lj+1;
                        state <= READ_A;
                    end
                end

                // PREP_B: reset indices for B read
                PREP_B: begin
                    li <= 0; lj <= 0;
                    state <= READ_B;
                end

                // READ MATRIX B ---------
                READ_B: begin
                    bram_addr <= (b_base + ((li*K + lj)*4))>>2;
                    state     <= IDLE_B1;
                end
                IDLE_B1: state <= IDLE_B2;
                IDLE_B2: state <= TAKE_B;
                TAKE_B: begin
                    B[li][lj] <= bram_dout;
                    $display("B[%0d][%0d] = %0d", li, lj, bram_dout);
                    if (li == M-1 && lj == K-1) begin
                        state <= COMPUTE_INIT;
                    end else begin
                        if (lj == K-1) begin li <= li+1; lj <= 0; end
                        else lj <= lj+1;
                        state <= READ_B;
                    end
                end

                COMPUTE_INIT: begin
                    for (x=0; x<N; x=x+1)
                        for (y=0; y<K; y=y+1)
                            temp_C[x][y] <= 0;
                    bi_idx<=0; bj_idx<=0; bk_idx<=0;
                    ii<=0; jj<=0; kk<=0;
                    state<=COMPUTE_STEP;
                end

                COMPUTE_STEP: begin
                    // Accumulate over k for this tile
                    for (ii = 0; ii < BLOCK; ii = ii + 1) begin
                        for (jj = 0; jj < BLOCK; jj = jj + 1) begin
                            temp_C[bi_idx*BLOCK + ii][bj_idx*BLOCK + jj] <=
                                temp_C[bi_idx*BLOCK + ii][bj_idx*BLOCK + jj] +
                                A[bi_idx*BLOCK + ii][bk_idx*BLOCK + kk] *
                                B[bk_idx*BLOCK + kk][bj_idx*BLOCK + jj];
                        end
                    end

                    // Advance k within the block
                    if (kk < BLOCK - 1) begin
                        kk <= kk + 1;
                    end else begin
                        kk <= 0;
                        // Advance tile indices: k-tile, then j-tile, then i-tile
                        if (bk_idx < MB - 1) begin
                            bk_idx <= bk_idx + 1;
                        end else begin
                            bk_idx <= 0;
                            if (bj_idx < KB - 1) begin
                                bj_idx <= bj_idx + 1;
                            end else begin
                                bj_idx <= 0;
                                if (bi_idx < NB - 1) begin
                                    bi_idx <= bi_idx + 1;
                                end else begin
                                    // All tiles done, go to writing C
                                    bi_idx <= 0;
                                    si <= 0; sj <= 0;
                                    state <= WRITE_C;
                                end
                            end
                        end
                    end
                end

                WRITE_C: begin
                    bram_addr<= (c_base + ((si*K + sj)*4))>>2 ;
                    bram_we  <= 1'b1;
                    bram_en<=1'b0;
                    bram_din <= temp_C[si][sj];
                    state    <= IDLE_C1;
                end
                IDLE_C1: state<=IDLE_C2;
                IDLE_C2: begin
                    state<=TAKE_C;
                    bram_we  <= 1'b0;
                end
                TAKE_C: begin
                    if (si==N-1 && sj==K-1) state<=PREP_RC;
                    else begin
                        if (sj==K-1) begin si<=si+1; sj<=0; end
                        else sj<=sj+1;
                        state<=WRITE_C;
                    end
                end
                PREP_RC: begin
                    li<=0; lj<=0;
                    bram_we<=0; bram_en<=1;
                    state<=READ_C;
                end

//                // Read C
                READ_C: begin
                    bram_addr<=(c_base+((li*K+lj)*4))>>2;
                    state<=IDLE_RC1;
                end
                IDLE_RC1: state<=IDLE_RC2;
                IDLE_RC2: state<=TAKE_RC;
                TAKE_RC: begin
//                    Cout[li][lj]<=bram_dout;
                    $display("C[%0d][%0d] = %0d",li,lj,bram_dout);
                    if(li==N-1&&lj==K-1) state<=DONE;
                    else begin
                        if(lj==K-1) begin li<=li+1; lj<=0; end else lj<=lj+1;
                        state<=READ_C;
                    end
                end
                DONE:begin
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    bram_en <= 1'b0;
                    bram_we <= 1'b0;
                end
                default: state<=IDLE;
            endcase
        end
    end
endmodule