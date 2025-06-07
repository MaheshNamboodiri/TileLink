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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    tilelink_wrapper_top #(
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
        .a_source_in   (a_source_in)
    );

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

        /////////////////////////
        // PUT_FULL_DATA (Write)
        /////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd0; // PUT_FULL_DATA_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h10;
        a_size_in    <= 3'd3; // 8 bytes
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'hCAFEBABE_DEADBEEF;
        a_source_in  <= 3'd1;

        @(posedge clk);
        a_valid_in <= 0;

        // Wait for slave to process
        #50;

        /////////////////////////
        // GET (Read)
        /////////////////////////
        @(posedge clk);
        a_valid_in   <= 1;
        a_opcode_in  <= 3'd4; // GET_A
        a_param_in   <= 3'd0;
        a_address_in <= 64'h10;
        a_size_in    <= 3'd3; // 8 bytes
        a_mask_in    <= 8'hFF;
        a_data_in    <= 64'h0; // Ignored in GET
        a_source_in  <= 3'd1;

        @(posedge clk);
        a_valid_in <= 0;

        // Wait and observe
        #200;

        $finish;
    end

endmodule
