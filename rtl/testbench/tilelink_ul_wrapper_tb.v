`timescale 1ns / 1ps

module tilelink_wrapper_top_tb;

    // Parameters
    parameter TL_ADDR_WIDTH   = 64;
    parameter TL_DATA_WIDTH   = 64;
    parameter TL_STRB_WIDTH   = TL_DATA_WIDTH / 8;
    parameter TL_SOURCE_WIDTH = 3;
    parameter TL_SINK_WIDTH   = 3;
    parameter TL_OPCODE_WIDTH = 3;
    parameter TL_PARAM_WIDTH  = 3;
    parameter TL_SIZE_WIDTH   = 8;

    // Clock and reset
    reg clk;
    reg rst;

    // Input stimulus
    reg a_valid_in;
    reg [TL_OPCODE_WIDTH-1:0] a_opcode_in;
    reg [TL_PARAM_WIDTH-1:0]  a_param_in;
    reg [TL_ADDR_WIDTH-1:0]   a_address_in;
    reg [TL_SIZE_WIDTH-1:0]   a_size_in;
    reg [TL_STRB_WIDTH-1:0]   a_mask_in;
    reg [TL_DATA_WIDTH-1:0]   a_data_in;
    reg [TL_SOURCE_WIDTH-1:0] a_source_in;
    
    // register outputs for testbench
    wire d_valid_tb;
    wire [TL_OPCODE_WIDTH-1:0] d_opcode_tb;
    wire [TL_PARAM_WIDTH-1:0]  d_param_tb;
    wire [TL_SIZE_WIDTH-1:0]   d_size_tb;
    wire [TL_DATA_WIDTH-1:0]   d_data_tb;
    wire [TL_SOURCE_WIDTH-1:0] d_source_tb;
    wire [TL_SINK_WIDTH-1:0]   d_sink_tb;
    wire d_error_tb;
    wire d_ready_tb;
    wire a_ready_tb;
    wire a_valid_tb;
    wire [TL_OPCODE_WIDTH-1:0] a_opcode_tb;
    wire [TL_PARAM_WIDTH-1:0]  a_param_tb;
    wire [TL_ADDR_WIDTH-1:0]   a_address_tb;
    wire [TL_SIZE_WIDTH-1:0]   a_size_tb;
    wire [TL_STRB_WIDTH-1:0]   a_mask_tb;
    wire [TL_DATA_WIDTH-1:0]   a_data_tb;
    wire [TL_SOURCE_WIDTH-1:0] a_source_tb;    

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
//    tilelink_wrapper_top #(
//        .TL_ADDR_WIDTH     (TL_ADDR_WIDTH),
//        .TL_DATA_WIDTH     (TL_DATA_WIDTH),
//        .TL_STRB_WIDTH     (TL_STRB_WIDTH),
//        .TL_SOURCE_WIDTH   (TL_SOURCE_WIDTH),
//        .TL_SINK_WIDTH     (TL_SINK_WIDTH),
//        .TL_OPCODE_WIDTH   (TL_OPCODE_WIDTH),
//        .TL_PARAM_WIDTH    (TL_PARAM_WIDTH),
//        .TL_SIZE_WIDTH     (TL_SIZE_WIDTH)
//    ) dut (
//        .clk           (clk),
//        .rst           (rst),
//        .a_valid_in    (a_valid_in),
//        .a_opcode_in   (a_opcode_in),
//        .a_param_in    (a_param_in),
//        .a_address_in  (a_address_in),
//        .a_size_in     (a_size_in),
//        .a_mask_in     (a_mask_in),
//        .a_data_in     (a_data_in),
//        .a_source_in   (a_source_in)
//    );

    tilelink_ul_1M_3S #(
        .TL_ADDR_WIDTH     (TL_ADDR_WIDTH),
        .TL_DATA_WIDTH     (TL_DATA_WIDTH),
        .TL_STRB_WIDTH     (TL_STRB_WIDTH),
        .TL_SOURCE_WIDTH   (TL_SOURCE_WIDTH),
        .TL_SINK_WIDTH     (TL_SINK_WIDTH),
        .TL_OPCODE_WIDTH   (TL_OPCODE_WIDTH),
        .TL_PARAM_WIDTH    (TL_PARAM_WIDTH),
        .TL_SIZE_WIDTH     (TL_SIZE_WIDTH)
    ) dut (
        .clk           (clk),
        .rst           (rst),
        .a_valid_in    (a_valid_in),
        .a_opcode_in   (a_opcode_in),
        .a_param_in    (a_param_in),
        .a_address_in  (a_address_in),
        .a_size_in     (a_size_in),
        .a_mask_in     (a_mask_in),
        .a_data_in     (a_data_in),
        .a_source_in   (a_source_in),

        // Outputs for testbenh
        .d_valid_tb   (d_valid_tb),
        .d_opcode_tb  (d_opcode_tb),
        .d_param_tb   (d_param_tb),
        .d_size_tb    (d_size_tb),
        .d_data_tb    (d_data_tb),
        .d_source_tb  (d_source_tb),
        .d_sink_tb    (d_sink_tb),
        .d_error_tb   (d_error_tb),
        .d_ready_tb   (d_ready_tb),

        .a_ready_tb   (a_ready_tb),
        .a_valid_tb   (a_valid_tb),
        .a_opcode_tb  (a_opcode_tb),
        .a_param_tb   (a_param_tb),
        .a_address_tb (a_address_tb),
        .a_size_tb    (a_size_tb),
        .a_mask_tb    (a_mask_tb),
        .a_data_tb    (a_data_tb),
        .a_source_tb  (a_source_tb)
    );



    

    task check_data;
        input [2:0] id;
        input [63:0] expected;
        begin
            #20;
            if (d_valid_tb && d_data_tb !== expected) begin
                $display("ERROR: Slave %0d returned incorrect data! Got %h, expected %h", id, d_data_tb, expected);
            end else begin
                $display("PASS: Slave %0d returned correct data.", id);
            end
        end
    endtask



    // Stimulus
    initial begin
        // Initialize
        rst = 1;
        a_valid_in   = 0;
        a_opcode_in  = 0;
        a_param_in   = 0;
        a_address_in = 0;
        a_size_in    = 0;
        a_mask_in    = 0;
        a_data_in    = 0;
        a_source_in  = 0;
    
        // Reset
        #20;
        rst = 0;
        #20;
    
        //////////////////////////
        // PUT_FULL_DATA to slave 0
        //////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd0; // PUT_FULL_DATA_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h0;
        a_size_in    <= 3'd3; // 8 bytes
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'hDEADBEEF_CAFEBABE;
        a_source_in  <= 3'd0;
    
        @(posedge clk);
        a_valid_in <= 0;
    
        // Wait
        #50;
    
        //////////////////////////
        // PUT_FULL_DATA to slave 1
        //////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd0; // PUT_FULL_DATA_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h0;
        a_size_in    <= 3'd3; // 8 bytes
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'h12345678_9ABCDEF0;
        a_source_in  <= 3'd1;
    
        @(posedge clk);
        a_valid_in <= 0;
    
        // Wait
        #50;
    
        //////////////////////////
        // PUT_FULL_DATA to slave 2
        //////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd0; // PUT_FULL_DATA_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h0;
        a_size_in    <= 3'd3; // 8 bytes
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'hFEEDFACE_BADC0FFE;
        a_source_in  <= 3'd2;
    
        @(posedge clk);
        a_valid_in <= 0;
    
        // Wait before GETs
        #100;
    
        //////////////////////////
        // GET from slave 0
        //////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd4; // GET_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h0;
        a_size_in    <= 3'd3;
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'h0; // ignored
        a_source_in  <= 3'd0;
    
        @(posedge clk);
        a_valid_in <= 0;
    
        #50;
    
        //////////////////////////
        // GET from slave 1
        //////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd4; // GET_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h0;
        a_size_in    <= 3'd3;
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'h0; // ignored
        a_source_in  <= 3'd1;
    
        @(posedge clk);
        a_valid_in <= 0;
    
        #50;
    
        //////////////////////////
        // GET from slave 2
        //////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd4; // GET_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h0;
        a_size_in    <= 3'd3;
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'h0; // ignored
        a_source_in  <= 3'd2;
    
        @(posedge clk);
        a_valid_in <= 0;
    
        #200;
    
        $finish;
    end


endmodule
