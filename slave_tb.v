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

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting TileLink UL Slave Testbench");
        clk = 0;
        rst = 1;
        d_ready = 0;
        a_valid = 0;

        // Wait and release reset
        #20;
        rst = 0;

        // Test WRITE (PUT_FULL_DATA)
        @(posedge clk);
        $display("Write to address 0x10 with data 0xDEADBEEFCAFEBABE");
        a_valid   <= 1'b1;
        a_opcode  <= 3'd0; // PUT_FULL_DATA
        a_param   <= 3'd0;
        a_address <= 64'h10;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= 64'hDEADBEEFCAFEBABE;
        a_source  <= 3'd1;

//        wait(a_ready);
        @(negedge clk);
        @(posedge clk);
        
        a_valid   <= 1'b0;
        d_ready <= 0;
        
//        wait (clk == 0);
//        wait (clk == 1);
//        wait (clk == 0);
//        #50
        repeat(5) @(posedge clk); 
                
        d_ready <= 1;
        
        wait (clk == 1);
        
        @(negedge clk);
        @(posedge clk);
        $display("Read from address 0x10");
        a_valid   <= 1'b1;
        a_opcode  <= 3'd4; // GET
        a_param   <= 3'd0;
        a_address <= 64'h10;
        a_size    <= 8'd3;
        a_mask    <= 8'hFF;
        a_data    <= 64'd0;
        a_source  <= 3'd1;
        
        @(negedge clk);
        @(posedge clk);  
        a_valid   <= 1'b0;      
                
//        a_valid <= 0;

//        wait(d_valid);
//        d_ready <= 1;
//        @(posedge clk);
//        d_ready <= 0;

//        // Test READ (GET)


//        wait(a_ready);
//        @(posedge clk);
//        a_valid <= 0;

//        wait(d_valid);
//        d_ready <= 1;
//        @(posedge clk);
//        $display("READ: Addr = 0x%h, Data = 0x%h", 64'h10, d_data);
//        d_ready <= 0;

        #50;
        $display("Testbench completed.");
        $finish;
    end

endmodule