`timescale 1ns / 1ps

module master_tb;

	// Parameters
	parameter TL_ADDR_WIDTH     = 64;
	parameter TL_DATA_WIDTH     = 64;
	parameter TL_STRB_WIDTH     = TL_DATA_WIDTH / 8;
	parameter TL_SOURCE_WIDTH   = 3;
	parameter TL_SINK_WIDTH     = 3;
	parameter TL_OPCODE_WIDTH   = 3;
	parameter TL_PARAM_WIDTH    = 3;
	parameter TL_SIZE_WIDTH     = 8;

	parameter GET_A             = 3'd4;
	parameter PUT_FULL_DATA_A   = 3'd0;
	parameter ACCESS_ACK_D      = 3'd0;
	parameter ACCESS_ACK_DATA_D = 3'd1;

	reg clk;
	reg rst;

	// Testbench driving inputs
	reg                              a_valid_in;
	reg  [TL_OPCODE_WIDTH-1:0]       a_opcode_in;
	reg  [TL_PARAM_WIDTH-1:0]        a_param_in;
	reg  [TL_ADDR_WIDTH-1:0]         a_address_in;
	reg  [TL_SIZE_WIDTH-1:0]         a_size_in;
	reg  [TL_STRB_WIDTH-1:0]         a_mask_in;
	reg  [TL_DATA_WIDTH-1:0]         a_data_in;
	reg  [TL_SOURCE_WIDTH-1:0]       a_source_in;

	// Slave (testbench) outputs
	wire                             a_valid;
	reg                              a_ready;
	wire                             d_ready;

	reg                              d_valid;
	reg  [TL_OPCODE_WIDTH-1:0]       d_opcode;
	reg  [TL_PARAM_WIDTH-1:0]        d_param;
	reg  [TL_SIZE_WIDTH-1:0]         d_size;
	reg  [TL_SINK_WIDTH-1:0]         d_sink;
	reg  [TL_SOURCE_WIDTH-1:0]       d_source;
	reg  [TL_DATA_WIDTH-1:0]         d_data;
	reg                              d_error;

	// Instantiate DUT
	tilelink_master_top_new_updated dut (
		.clk(clk),
		.rst(rst),
		.a_valid_in(a_valid_in),
		.a_opcode_in(a_opcode_in),
		.a_param_in(a_param_in),
		.a_address_in(a_address_in),
		.a_size_in(a_size_in),
		.a_mask_in(a_mask_in),
		.a_data_in(a_data_in),
		.a_source_in(a_source_in),

		.a_ready(a_ready),
		.a_valid(a_valid),
		.a_opcode(), // optional if you want to probe
		.a_param(),
		.a_address(),
		.a_size(),
		.a_mask(),
		.a_data(),
		.a_source(),

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
	initial begin
		clk = 1;
		forever #5 clk = ~clk;
	end

	// Stimulus
	initial begin
		rst <= 1;
		a_valid_in <= 0;
		a_opcode_in <= 0;
		a_param_in <= 0;
		a_address_in <= 0;
		a_size_in <= 0;
		a_mask_in <= 0;
		a_data_in <= 0;
		a_source_in <= 0;

		a_ready <= 1;
		d_valid <= 0;
		d_opcode <= 0;
		d_param <= 0;
		d_size <= 3;
		d_sink <= 0;
		d_source <= 0;
		d_data <= 0;
		d_error <= 0;

		@(posedge clk);
		@(posedge clk);
		rst <= 0;

		// --- Write Request ---
		@(posedge clk);
		a_valid_in <= 1;
		a_opcode_in <= PUT_FULL_DATA_A;
		a_param_in <= 0;
		a_address_in <= 64'h1000_0000;
		a_size_in <= 3; // 8 bytes
		a_mask_in <= 8'hFF;
		a_data_in <= 64'hDEAD_BEEF_CAFE_BABE;
		a_source_in <= 3'd1;

		@(posedge clk);
		a_valid_in <= 0;

		// Wait for 5 cycles, then respond
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		d_valid <= 1;
		d_opcode <= ACCESS_ACK_D;
		d_param <= 0;
		d_source <= 3'd1;
		d_data <= 64'h0000000000000000;
		d_error <= 0;

		@(posedge clk);
		d_valid <= 0;

		// --- Read Request ---
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		a_valid_in <= 1;
		a_opcode_in <= GET_A;
		a_param_in <= 0;
		a_address_in <= 64'h1000_0000;
		a_size_in <= 3;
		a_mask_in <= 8'hFF;
		a_data_in <= 64'd0;
		a_source_in <= 3'd2;

		// Respond immediately
		@(posedge clk);
		a_valid_in <= 0;
		
//		@(posedge clk);
         
		d_valid <= 1;
		d_opcode <= ACCESS_ACK_DATA_D;
		d_param <= 0;
		d_source <= 3'd2;
		d_data <= 64'hBEEF_DEAD_BEEF_DEAD;
		d_error <= 0;
        
        // ===============================
        // 3 SUCCESSIVE PUT_FULL + ACK
        // ===============================

        // First Transaction
        @(posedge clk);
        a_valid_in <= 1;
        d_valid <= 0;
        a_opcode_in <= PUT_FULL_DATA_A;
        a_param_in <= 0;
        a_address_in <= 64'h2000_0000;
        a_size_in <= 3;
        a_mask_in <= 8'hFF;
        a_data_in <= 64'h1111_2222_3333_4444;
        a_source_in <= 3'd3;

        @(posedge clk);
        a_valid_in <= 0;

        // Response for first
        @(posedge clk);
        d_valid <= 1;
        d_opcode <= ACCESS_ACK_D;
        d_param <= 0;
        d_source <= 3'd3;
        d_data <= 64'd0;
        d_error <= 0;

        @(posedge clk);
        d_valid <= 0;

        // Second Transaction
        @(posedge clk);
        a_valid_in <= 1;
        a_opcode_in <= PUT_FULL_DATA_A;
        a_param_in <= 0;
        a_address_in <= 64'h2000_0008;
        a_size_in <= 3;
        a_mask_in <= 8'hFF;
        a_data_in <= 64'h5555_6666_7777_8888;
        a_source_in <= 3'd4;

        @(posedge clk);
        a_valid_in <= 0;

        // Response for second
        @(posedge clk);
        d_valid <= 1;
        d_opcode <= ACCESS_ACK_D;
        d_param <= 0;
        d_source <= 3'd4;
        d_data <= 64'd0;
        d_error <= 0;

        @(posedge clk);
        d_valid <= 0;

        // Third Transaction
        @(posedge clk);
        a_valid_in <= 1;
        a_opcode_in <= PUT_FULL_DATA_A;
        a_param_in <= 0;
        a_address_in <= 64'h2000_0010;
        a_size_in <= 3;
        a_mask_in <= 8'hFF;
        a_data_in <= 64'h9999_AAAA_BBBB_CCCC;
        a_source_in <= 3'd5;

        @(posedge clk);
        a_valid_in <= 0;

        // Response for third
        @(posedge clk);
        d_valid <= 1;
        d_opcode <= ACCESS_ACK_D;
        d_param <= 0;
        d_source <= 3'd5;
        d_data <= 64'd0;
        d_error <= 0;

        @(posedge clk);
        d_valid <= 0;

		@(posedge clk);
		$finish;


	end
endmodule


/***************************************************

1. The end of the testbench involved d_valid being left asserted. The slave probably deasserts d_valid after a response is done.
   This needs to be confirmed. 
   
   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   TO BE UPDATED >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
   
2. Otherwise, the design tilelink_master_top_new is able to respond to delayed transactions (from testbench) as well as successive transactions.  




***************************************************/

