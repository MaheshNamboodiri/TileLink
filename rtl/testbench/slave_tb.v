`timescale 1ns / 1ps

module tilelink_ul_slave_tb;

    // Clock and reset
    reg clk;
    reg rst;

    // Parameters
    parameter TL_ADDR_WIDTH     = 64;
    parameter TL_DATA_WIDTH     = 64;
    parameter TL_STRB_WIDTH     = TL_DATA_WIDTH / 8;
    parameter TL_SOURCE_WIDTH   = 3;
    parameter TL_SINK_WIDTH     = 3;
    parameter TL_OPCODE_WIDTH   = 3;
    parameter TL_PARAM_WIDTH    = 3;
    parameter TL_SIZE_WIDTH     = 8;

    // A Channel (to slave)
    reg                             a_valid;
    wire                            a_ready;
    reg [TL_OPCODE_WIDTH-1:0]       a_opcode;
    reg [TL_PARAM_WIDTH-1:0]        a_param;
    reg [TL_ADDR_WIDTH-1:0]         a_address;
    reg [TL_SIZE_WIDTH-1:0]         a_size;
    reg [TL_STRB_WIDTH-1:0]         a_mask;
    reg [TL_DATA_WIDTH-1:0]         a_data;
    reg [TL_SOURCE_WIDTH-1:0]       a_source;

    // D Channel (from slave)
    wire                            d_valid;
    reg                             d_ready;
    wire [TL_OPCODE_WIDTH-1:0]      d_opcode;
    wire [TL_PARAM_WIDTH-1:0]       d_param;
    wire [TL_SIZE_WIDTH-1:0]        d_size;
    wire [TL_SINK_WIDTH-1:0]        d_sink;
    wire [TL_SOURCE_WIDTH-1:0]      d_source;
    wire [TL_DATA_WIDTH-1:0]        d_data;
    wire                            d_error;

    // Instantiate DUT
    tilelink_ul_slave_top dut (
        .clk(clk),
        .rst(rst),
        .a_ready(a_ready),
        .a_valid(a_valid),
        .a_opcode(a_opcode),
        .a_param(a_param),
        .a_address(a_address),
        .a_size(a_size),
        .a_mask(a_mask),
        .a_data(a_data),
        .a_source(a_source),
        .d_valid(d_valid),
        .d_ready(d_ready),
        .d_opcode(d_opcode),
        .d_param(d_param),
        .d_size(d_size),
        .d_sink(d_sink),
        .d_source(d_source),
        .d_data(d_data),
        .d_error(d_error)
    );
    reg [63:0] expected1;
    reg [63:0] expected2;
    reg [63:0] expected3;    
    // Clock generation
    // Clock generation
    always #5 clk = ~clk;

    initial begin


        $display("Starting TileLink UL Slave Testbench");
        clk = 0;
        rst = 1;
        d_ready = 0;
        a_valid = 0;

        // Release reset
        #20;
        rst = 0;

        // =======================
        // SET 1: PUT_FULL + GET
        // =======================
        expected1 = 64'hDEADBEEFCAFEBABE;

        @(posedge clk);
        $display("WRITE 1: PUT_FULL to 0x10 = 0x%h", expected1);
        a_valid   <= 1;
        a_opcode  <= 3'd0; // PUT_FULL_DATA
        a_param   <= 3'd0;
        a_address <= 64'h10;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= expected1;
        a_source  <= 3'd1;

        @(posedge clk);
        a_valid <= 0;

        d_ready <= 1;
        @(posedge clk);
        d_ready <= 0;

        @(posedge clk);
        $display("READ 1: GET from 0x10");
        a_valid   <= 1;
        a_opcode  <= 3'd4; // GET
        a_param   <= 3'd0;
        a_address <= 64'h10;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= 64'd0;
        a_source  <= 3'd1;

        @(posedge clk);
        a_valid <= 0;

        d_ready <= 1;
        @(posedge clk);
        if (d_data === expected1) begin
            $display("READ 1 CHECK PASSED: 0x%h", d_data);
        end else begin
            $display("READ 1 CHECK FAILED: Expected 0x%h, Got 0x%h", expected1, d_data);
        end
        d_ready <= 0;

        repeat (5) @(posedge clk);

        // =======================
        // SET 2: PUT_PARTIAL + GET
        // =======================
        expected2 = 64'h123456789ABCDEF0;
        @(posedge clk);
        $display("WRITE 2: PUT_PARTIAL to 0x20 = 0x%h (mask=0x0F)", expected2);
        a_valid   <= 1;
        a_opcode  <= 3'd1; // PUT_PARTIAL_DATA
        a_param   <= 3'd0;
        a_address <= 64'h20;
        a_size    <= 8'd3;
        a_mask    <= 8'h0F;
        a_data    <= expected2;
        a_source  <= 3'd2;

        @(posedge clk);
        a_valid <= 0;

        d_ready <= 1;
        @(posedge clk);
        d_ready <= 0;

        @(posedge clk);
        $display("READ 2: GET from 0x20");
        a_valid   <= 1;
        a_opcode  <= 3'd4; // GET
        a_param   <= 3'd0;
        a_address <= 64'h20;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= 64'd0;
        a_source  <= 3'd2;

        @(posedge clk);
        a_valid <= 0;

        d_ready <= 1;
        @(posedge clk);
        // Only lower 4 bytes (mask = 0x0F) written, so upper 4 bytes may be 0 or unchanged
        if (d_data[31:0] === expected2[31:0]) begin
            $display("READ 2 CHECK PASSED: Lower 4B = 0x%h", d_data[31:0]);
        end else begin
            $display("READ 2 CHECK FAILED: Expected Lower 4B = 0x%h, Got = 0x%h", expected2[31:0], d_data[31:0]);
        end
        d_ready <= 0;

        // =======================
        // SET 3: PUT_FULL + GET with delayed d_ready
        // =======================

        expected3 = 64'hBADDCAFEBEEF1234;

        @(posedge clk);
        $display("WRITE 3: PUT_FULL to 0x30 = 0x%h", expected3);
        a_valid   <= 1;
        a_opcode  <= 3'd0; // PUT_FULL_DATA
        a_param   <= 3'd0;
        a_address <= 64'h30;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= expected3;
        a_source  <= 3'd3;

        @(posedge clk);
        a_valid <= 0;

        // Delay d_ready for write response
        repeat (2) @(posedge clk);
        d_ready <= 1;
        @(posedge clk);
        d_ready <= 0;

        @(posedge clk);
        $display("READ 3: GET from 0x30");
        a_valid   <= 1;
        a_opcode  <= 3'd4; // GET
        a_param   <= 3'd0;
        a_address <= 64'h30;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= 64'd0;
        a_source  <= 3'd3;

        @(posedge clk);
        a_valid <= 0;

        // Delay d_ready for read response
        repeat (2) @(posedge clk);
        d_ready <= 1;
        @(posedge clk);
        if (d_data === expected3) begin
            $display("READ 3 CHECK PASSED: 0x%h", d_data);
        end else begin
            $display("READ 3 CHECK FAILED: Expected 0x%h, Got 0x%h", expected3, d_data);
        end
        d_ready <= 0;
        

        #50;
        $display("Testbench completed.");
        $finish;
    end

endmodule