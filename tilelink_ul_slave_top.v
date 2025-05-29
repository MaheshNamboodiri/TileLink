/*******************************************************************************************************************************************

This top-level module sets up signals for the slave instance of the TileLink UL protocol. It will work in the low speed domain with 
peripherals like GPIO and Flash.

*******************************************************************************************************************************************/


module tilelink_ul_slave_top #(

	//////////////////////////////////////////////////////////////////
	////////////////////// Core interface widths /////////////////////
	//////////////////////////////////////////////////////////////////
	
	parameter TL_ADDR_WIDTH     = 64,            		// Address width
	parameter TL_DATA_WIDTH     = 64,            		// Data width
	parameter TL_STRB_WIDTH     = TL_DATA_WIDTH / 8, 	// Byte mask width/Byte strobe. Each bit represents one byte of the data.

	
	//////////////////////////////////////////////////////////////////
	//////////////////// TileLink metadata widths ////////////////////
	//////////////////////////////////////////////////////////////////
	
	// Check again! Bigger the source width, more the number of active transactions.
	parameter TL_SOURCE_WIDTH   = 3;					// Tags each request with a unique ID. The same ID must appear in the corresponding response.
	parameter TL_SINK_WIDTH     = 3;					// Tags each response with an ID that matches that of the request.
	parameter TL_OPCODE_WIDTH   = 3,					// Opcode width for instructions
	parameter TL_PARAM_WIDTH    = 3,             // Currently reserved for future performance hints and must be 0 
	parameter TL_SIZE_WIDTH     = 8,             // Width of size field, value of which determines data beat size in bytes as 2^size.
	

	// Define opcodes for channels
	// A Channel Opcodes
	parameter PUT_FULL_DATA     = 3'd0,
	parameter PUT_PARTIAL_DATA  = 3'd1,
	parameter ARITHMETIC_DATA   = 3'd2,
	parameter LOGICAL_DATA      = 3'd3,
	parameter GET               = 3'd4,
	parameter INTENT            = 3'd5,
	parameter ACQUIRE_BLOCK     = 3'd6,
	parameter ACQUIRE_PERM      = 3'd7,

	// D Channel Opcodes
	parameter ACCESS_ACK_D      = 3'd0,
	parameter ACCESS_ACK_DATA_D = 3'd1,
	parameter HINT_ACK_D        = 3'd2,
	parameter GRANT_D           = 3'd4,
	parameter GRANT_DATA_D      = 3'd5,
	parameter RELEASE_ACK_D     = 3'd6,
	
	// Slave FSM States
	parameter FETCH_INS 			 = 2'd0,
	parameter EVALUATE_INS		 = 2'd1,
	parameter CLEANUP 			 = 2'd2

)(
	input  wire                              clk,
	input  wire                              reset,

	// A Channel: Received from MASTER
	output wire                              a_ready,		// Slave sends a_ready to Master to indicate that it is ready to accept data.
	input  wire                              a_valid, 		// Asserted to indicate valid instruction
	input  wire [TL_OPCODE_WIDTH-1:0]        a_opcode,		// Opcode for instruction
	input  wire [TL_PARAM_WIDTH-1:0]         a_param,		// Reserved, always 0.
	input  wire [TL_ADDR_WIDTH-1:0]          a_address,	// Address 
	input  wire [TL_SIZE_WIDTH-1:0]          a_size,		// Width of full data sent in one go = 2^size. For TLUL, size = Data Width of Channel.
	input  wire [TL_STRB_WIDTH-1:0]          a_mask,		// Bit masking
	input  wire [TL_DATA_WIDTH-1:0]          a_data,		// Incoming data
	input  wire [TL_SOURCE_WIDTH-1:0]        a_source,		// Transaction ID

	// D Channel Sent to MASTER
	output wire 									  d_valid,
	input  wire                              d_ready, 		// Master ends d_ready to Slave to indicate that it is ready to accept data.
	output wire [TL_OPCODE_WIDTH-1:0]        d_opcode,
	output wire [TL_PARAM_WIDTH-1:0]         d_param,
	output wire [TL_SIZE_WIDTH-1:0]          d_size,
	output wire [TL_SINK_WIDTH-1:0]          d_sink,
	output wire [TL_SOURCE_WIDTH-1:0]        d_source,	
	output wire [TL_DATA_WIDTH-1:0]          d_data,
	output wire                              d_error,
);

	// FSM State Variables:
	
	// State variable for slave FSM
	reg [:0] slave_state;
  
  
	
	
	
	
	
	
	
	
	
	
endmodule

