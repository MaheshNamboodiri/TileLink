/*******************************************************************************************************************************************

This top-level module acts as a wrapper for the TileLink UltraLite (TL-UL) interface.
It connects the TileLink UltraLite interface to a TileLink UltraLite master and slave.

*******************************************************************************************************************************************/


module tilelink_wrapper_top #( 
    parameter TL_ADDR_WIDTH     = 64,
    parameter TL_DATA_WIDTH     = 64,
    parameter TL_STRB_WIDTH     = TL_DATA_WIDTH / 8,
    parameter TL_SOURCE_WIDTH   = 3,
    parameter TL_SINK_WIDTH     = 3,
    parameter TL_OPCODE_WIDTH   = 3,
    parameter TL_PARAM_WIDTH    = 3,
    parameter TL_SIZE_WIDTH     = 8
)(
    input  wire                              clk,
    input  wire                              rst,

    // Inputs to drive the master from testbench
    input  wire                              a_valid_in,
    input  wire [TL_OPCODE_WIDTH-1:0]        a_opcode_in,
    input  wire [TL_PARAM_WIDTH-1:0]         a_param_in,
    input  wire [TL_ADDR_WIDTH-1:0]          a_address_in,
    input  wire [TL_SIZE_WIDTH-1:0]          a_size_in,
    input  wire [TL_STRB_WIDTH-1:0]          a_mask_in,
    input  wire [TL_DATA_WIDTH-1:0]          a_data_in,
    input  wire [TL_SOURCE_WIDTH-1:0]        a_source_in
);

    /////////////////////////////////////////
    //////// Localparams for opcodes ////////
    /////////////////////////////////////////

    localparam PUT_FULL_DATA_A     = 3'd0;
    localparam PUT_PARTIAL_DATA_A  = 3'd1;
    localparam ARITHMETIC_DATA_A   = 3'd2;
    localparam LOGICAL_DATA_A      = 3'd3;
    localparam GET_A               = 3'd4;
    localparam INTENT_A            = 3'd5;
    localparam ACQUIRE_BLOCK_A     = 3'd6;
    localparam ACQUIRE_PERM_A      = 3'd7;

    localparam ACCESS_ACK_D        = 3'd0;
    localparam ACCESS_ACK_DATA_D   = 3'd1;
    localparam HINT_ACK_D          = 3'd2;
    localparam GRANT_D             = 3'd4;
    localparam GRANT_DATA_D        = 3'd5;
    localparam RELEASE_ACK_D       = 3'd6;

    localparam IDLE     = 2'd0;
    localparam REQUEST  = 2'd1;
    localparam RESPONSE = 2'd2;
    localparam CLEANUP  = 2'd3;


    // Internal wires for A and D channels between master and slave
    wire a_ready;
    wire a_valid;
    wire [TL_OPCODE_WIDTH-1:0] a_opcode;
    wire [TL_PARAM_WIDTH-1:0]  a_param;
    wire [TL_ADDR_WIDTH-1:0]   a_address;
    wire [TL_SIZE_WIDTH-1:0]   a_size;
    wire [TL_STRB_WIDTH-1:0]   a_mask;
    wire [TL_DATA_WIDTH-1:0]   a_data;
    wire [TL_SOURCE_WIDTH-1:0] a_source;

    wire d_valid;
    wire d_ready;
    wire [TL_OPCODE_WIDTH-1:0] d_opcode;
    wire [TL_PARAM_WIDTH-1:0]  d_param;
    wire [TL_SIZE_WIDTH-1:0]   d_size;
    wire [TL_SINK_WIDTH-1:0]   d_sink;
    wire [TL_SOURCE_WIDTH-1:0] d_source;
    wire [TL_DATA_WIDTH-1:0]   d_data;
    wire                       d_error;

	// Instantiate the TileLink Uncached Lightweight master

    tilelink_master_top_new_updated #(
        .TL_ADDR_WIDTH     (TL_ADDR_WIDTH),
        .TL_DATA_WIDTH     (TL_DATA_WIDTH),
        .TL_STRB_WIDTH     (TL_STRB_WIDTH),
        .TL_SOURCE_WIDTH   (TL_SOURCE_WIDTH),
        .TL_SINK_WIDTH     (TL_SINK_WIDTH),
        .TL_OPCODE_WIDTH   (TL_OPCODE_WIDTH),
        .TL_PARAM_WIDTH    (TL_PARAM_WIDTH),
        .TL_SIZE_WIDTH     (TL_SIZE_WIDTH),
        .PUT_FULL_DATA_A   (PUT_FULL_DATA_A),
        .PUT_PARTIAL_DATA_A(PUT_PARTIAL_DATA_A),
        .ARITHMETIC_DATA_A (ARITHMETIC_DATA_A),
        .LOGICAL_DATA_A    (LOGICAL_DATA_A),
        .GET_A             (GET_A),
        .INTENT_A          (INTENT_A),
        .ACQUIRE_BLOCK_A   (ACQUIRE_BLOCK_A),
        .ACQUIRE_PERM_A    (ACQUIRE_PERM_A),
        .ACCESS_ACK_D      (ACCESS_ACK_D),
        .ACCESS_ACK_DATA_D (ACCESS_ACK_DATA_D),
        .HINT_ACK_D        (HINT_ACK_D),
        .GRANT_D           (GRANT_D),
        .GRANT_DATA_D      (GRANT_DATA_D),
        .RELEASE_ACK_D     (RELEASE_ACK_D),
        .REQUEST           (REQUEST),
        .RESPONSE          (RESPONSE),
        .CLEANUP           (CLEANUP),
        .IDLE              (IDLE)
    ) master_inst (
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

        .a_ready       (a_ready),
        .a_valid       (a_valid),
        .a_opcode      (a_opcode),
        .a_param       (a_param),
        .a_address     (a_address),
        .a_size        (a_size),
        .a_mask        (a_mask),
        .a_data        (a_data),
        .a_source      (a_source),

        .d_valid       (d_valid),
        .d_ready       (d_ready),
        .d_opcode      (d_opcode),
        .d_param       (d_param),
        .d_size        (d_size),
        .d_sink        (d_sink),
        .d_source      (d_source),
        .d_data        (d_data),
        .d_error       (d_error)
    );

	// Instantiate the TileLink Uncached Lightweight slave

    tilelink_ul_slave_top #(
        .TL_ADDR_WIDTH      (TL_ADDR_WIDTH),
        .TL_DATA_WIDTH      (TL_DATA_WIDTH),
        .TL_STRB_WIDTH      (TL_STRB_WIDTH),
        .TL_SOURCE_WIDTH    (TL_SOURCE_WIDTH),
        .TL_SINK_WIDTH      (TL_SINK_WIDTH),
        .TL_OPCODE_WIDTH    (TL_OPCODE_WIDTH),
        .TL_PARAM_WIDTH     (TL_PARAM_WIDTH),
        .TL_SIZE_WIDTH      (TL_SIZE_WIDTH),
        .PUT_FULL_DATA_A    (PUT_FULL_DATA_A),
        .PUT_PARTIAL_DATA_A (PUT_PARTIAL_DATA_A),
        .ARITHMETIC_DATA_A  (ARITHMETIC_DATA_A),
        .LOGICAL_DATA_A     (LOGICAL_DATA_A),
        .GET_A              (GET_A),
        .INTENT_A           (INTENT_A),
        .ACQUIRE_BLOCK_A    (ACQUIRE_BLOCK_A),
        .ACQUIRE_PERM_A     (ACQUIRE_PERM_A),
        .ACCESS_ACK_D       (ACCESS_ACK_D),
        .ACCESS_ACK_DATA_D  (ACCESS_ACK_DATA_D),
        .HINT_ACK_D         (HINT_ACK_D),
        .GRANT_D            (GRANT_D),
        .GRANT_DATA_D       (GRANT_DATA_D),
        .RELEASE_ACK_D      (RELEASE_ACK_D),
        .REQUEST            (REQUEST),
        .RESPONSE           (RESPONSE),
        .CLEANUP            (CLEANUP),
        .IDLE              (IDLE)
    ) slave_inst (
        .clk        (clk),
        .rst        (rst),

        .a_ready    (a_ready),
        .a_valid    (a_valid),
        .a_opcode   (a_opcode),
        .a_param    (a_param),
        .a_address  (a_address),
        .a_size     (a_size),
        .a_mask     (a_mask),
        .a_data     (a_data),
        .a_source   (a_source),

        .d_valid    (d_valid),
        .d_ready    (d_ready),
        .d_opcode   (d_opcode),
        .d_param    (d_param),
        .d_size     (d_size),
        .d_sink     (d_sink),
        .d_source   (d_source),
        .d_data     (d_data),
        .d_error    (d_error)
    );
	


endmodule