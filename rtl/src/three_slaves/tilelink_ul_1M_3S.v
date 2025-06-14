module tilelink_ul_1M_3S #( 
    parameter TL_ADDR_WIDTH     = 64,
    parameter TL_DATA_WIDTH     = 64,
    parameter TL_STRB_WIDTH     = TL_DATA_WIDTH / 8,
    parameter TL_SOURCE_WIDTH   = 3,
    parameter TL_SINK_WIDTH     = 3,
    parameter TL_OPCODE_WIDTH   = 3,
    parameter TL_PARAM_WIDTH    = 3,
    parameter TL_SIZE_WIDTH     = 8,
	parameter MEM_BASE_ADDR 	  = 64'h0000_0000_0000_0000, // Base address for memory
	parameter DEPTH           = 512                      // Memory depth (number of entries)        
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
    input  wire [TL_SOURCE_WIDTH-1:0]        a_source_in,


    // A channel for testbench
    output reg [TL_ADDR_WIDTH-1:0] a_address_tb,
    output reg [TL_DATA_WIDTH-1:0] a_data_tb,
    output reg [TL_OPCODE_WIDTH-1:0] a_opcode_tb,
    output reg [TL_PARAM_WIDTH-1:0] a_param_tb,
    output reg [TL_SIZE_WIDTH-1:0] a_size_tb,
    output reg [TL_STRB_WIDTH-1:0] a_mask_tb,
    output reg [TL_SOURCE_WIDTH-1:0] a_source_tb,
    output reg a_valid_tb,
    output reg a_ready_tb,

    // D channel for testbench
    output reg [TL_OPCODE_WIDTH-1:0] d_opcode_tb,
    output reg [TL_PARAM_WIDTH-1:0] d_param_tb,
    output reg [TL_SIZE_WIDTH-1:0] d_size_tb,
    output reg [TL_SINK_WIDTH-1:0] d_sink_tb,
    output reg [TL_SOURCE_WIDTH-1:0] d_source_tb,
    output reg [TL_DATA_WIDTH-1:0] d_data_tb,
    output reg d_valid_tb,
    output reg d_ready_tb,
    output reg d_error_tb

);

    /////////////////////////////////////////
    //////// Localparams for opcodes ////////
    /////////////////////////////////////////
    
//    localparam TL_ADDR_WIDTH     = 64;
//    localparam TL_DATA_WIDTH     = 64;
//    localparam TL_STRB_WIDTH     = TL_DATA_WIDTH / 8;
//    localparam TL_SOURCE_WIDTH   = 3;
//    localparam TL_SINK_WIDTH     = 3;
//    localparam TL_OPCODE_WIDTH   = 3;
//    localparam TL_PARAM_WIDTH    = 3;
//    localparam TL_SIZE_WIDTH     = 8;    

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

	localparam REQUEST 			 = 2'd0;
	localparam RESPONSE   		 = 2'd1;
	localparam CLEANUP 			 = 2'd2;
	localparam IDLE   			 = 2'd3;

    // Number of slaves
    localparam NUM_SLAVES = 3;

    // Address Ranges for slaves
    localparam ADDR_RANGE = 500;

    // Create variables for A channel three slaves
    reg [TL_ADDR_WIDTH-1:0] slave_a_address[2:0];
    reg [TL_DATA_WIDTH-1:0] slave_a_data[2:0];
    reg [TL_OPCODE_WIDTH-1:0] slave_a_opcode[2:0];
    reg [TL_PARAM_WIDTH-1:0] slave_a_param[2:0];
    reg [TL_SIZE_WIDTH-1:0] slave_a_size[2:0];
    reg [TL_STRB_WIDTH-1:0] slave_a_mask[2:0];
    reg [TL_SOURCE_WIDTH-1:0] slave_a_source[2:0];
    reg slave_a_valid[2:0];
    wire slave_a_ready[2:0];

    // Create variables for D channel three slaves
    wire [TL_OPCODE_WIDTH-1:0] slave_d_opcode[2:0];
    wire [TL_PARAM_WIDTH-1:0] slave_d_param[2:0];
    wire [TL_SIZE_WIDTH-1:0] slave_d_size[2:0];
    wire [TL_SINK_WIDTH-1:0] slave_d_sink[2:0];
    wire [TL_SOURCE_WIDTH-1:0] slave_d_source[2:0];
    wire [TL_DATA_WIDTH-1:0] slave_d_data[2:0];
    wire slave_d_valid[2:0];
    reg  slave_d_ready[2:0];
    wire slave_d_error[2:0];

    // Slave inputs into master
    reg d_error;
    reg [TL_DATA_WIDTH-1:0] d_data;
    reg [TL_OPCODE_WIDTH-1:0] d_opcode;
    reg [TL_PARAM_WIDTH-1:0] d_param;
    reg [TL_SIZE_WIDTH-1:0] d_size;
    reg [TL_SINK_WIDTH-1:0] d_sink;
    reg [TL_SOURCE_WIDTH-1:0] d_source;
    reg d_valid;
    wire d_ready;

    // Master outputs to slaves
    reg a_ready;
    wire a_valid;
    wire [TL_OPCODE_WIDTH-1:0] a_opcode;
    wire [TL_PARAM_WIDTH-1:0] a_param;
    wire [TL_ADDR_WIDTH-1:0] a_address;
    wire [TL_SIZE_WIDTH-1:0] a_size;
    wire [TL_STRB_WIDTH-1:0] a_mask;
    wire [TL_DATA_WIDTH-1:0] a_data;
    wire [TL_SOURCE_WIDTH-1:0] a_source;

    // Instantiate the tilelink master
    tilelink_ul_master_top #(
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

    // Instantiate the tilelink slave three times for three slaves using generate
    genvar i;
    generate
    for (i = 0; i < NUM_SLAVES; i = i + 1) begin : gen_peripheral_slaves
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
            .IDLE               (IDLE),
            .MEM_BASE_ADDR     (i * DEPTH + MEM_BASE_ADDR),
            .DEPTH(DEPTH)            
        ) slave_inst (
            .clk        (clk),
            .rst        (rst),

            .a_ready    (slave_a_ready[i]),
            .a_valid    (slave_a_valid[i]),
            .a_opcode   (slave_a_opcode[i]),
            .a_param    (slave_a_param[i]),
            .a_address  (slave_a_address[i]),
            .a_size     (slave_a_size[i]),
            .a_mask     (slave_a_mask[i]),
            .a_data     (slave_a_data[i]),
            .a_source   (slave_a_source[i]),

            .d_valid    (slave_d_valid[i]),
            .d_ready    (slave_d_ready[i]),
            .d_opcode   (slave_d_opcode[i]),
            .d_param    (slave_d_param[i]),
            .d_size     (slave_d_size[i]),
            .d_sink     (slave_d_sink[i]),
            .d_source   (slave_d_source[i]),
            .d_data     (slave_d_data[i]),
            .d_error    (slave_d_error[i])
        );
    end
    endgenerate

    // Arbiter Design for slave selection
    integer j,k,m;



    always @(*) begin
        // Default outputs
        a_ready     = 0;
        a_ready_tb  = 0;
        d_opcode_tb = 0;
        d_param_tb  = 0;
        d_size_tb   = 0;
        d_sink_tb   = 0;
        d_source_tb = 0;
        d_data_tb   = 0;
        d_error_tb  = 0;
        d_valid_tb  = 0;
        d_ready_tb  = 0;

        // Reset all slaves
        for (j = 0; j < 3; j = j + 1) begin
            slave_a_address[j] = 0;
            slave_a_data[j]    = 0;
            slave_a_opcode[j]  = 0;
            slave_a_param[j]   = 0;
            slave_a_size[j]    = 0;
            slave_a_mask[j]    = 0;
            slave_a_source[j]  = 0;
            slave_a_valid[j]   = 0;
            slave_d_ready[j]   = 0;
        end

        if (!rst) begin
            for (k = 0; k < NUM_SLAVES; k=k+1) begin 
                if ((a_address >= k*ADDR_RANGE) && (a_address < (k+1)*ADDR_RANGE)) begin
                    // Assigning slave
                    slave_a_address[k] = a_address;
                    slave_a_data[k] = a_data;
                    slave_a_opcode[k] = a_opcode;
                    slave_a_param[k] = a_param;
                    slave_a_size[k] = a_size;
                    slave_a_mask[k] = a_mask;
                    slave_a_source[k] = a_source;
                    slave_a_valid[k] = a_valid;
                    a_ready = slave_a_ready[k];
                    a_ready_tb = slave_a_ready[k];

                    // D channnel back to master
                    d_opcode = slave_d_opcode[k];
                    d_param = slave_d_param[k];
                    d_size = slave_d_size[k];
                    d_sink = slave_d_sink[k];
                    d_source = slave_d_source[k];
                    d_data = slave_d_data[k];
                    d_error = slave_d_error[k];
                    d_valid = slave_d_valid[k];
                    slave_d_ready[k] = d_ready;

                    
                    // Assigning outputs for testbench
                    a_address_tb = slave_a_address[k];
                    a_data_tb = slave_a_data[k];
                    a_opcode_tb = slave_a_opcode[k];
                    a_param_tb = slave_a_param[k];
                    a_size_tb = slave_a_size[k];
                    a_mask_tb = slave_a_mask[k];
                    a_source_tb = slave_a_source[k];
                    a_valid_tb = slave_a_valid[k];
                    a_ready_tb = slave_a_ready[k];

                    // Assigning D channel outputs for testbench
                    d_opcode_tb = slave_d_opcode[k];
                    d_param_tb = slave_d_param[k];
                    d_size_tb = slave_d_size[k];
                    d_sink_tb = slave_d_sink[k];
                    d_source_tb = slave_d_source[k];
                    d_data_tb = slave_d_data[k];
                    d_error_tb = slave_d_error[k];
                    d_valid_tb = slave_d_valid[k];
                    d_ready_tb = d_ready;

                end              
            end            
        end
    end        




endmodule