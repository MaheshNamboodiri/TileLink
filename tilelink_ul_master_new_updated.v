/*******************************************************************************************************************************************

This top-level module sets up signals for the master instance of the TileLink UL protocol. It will work in the low speed domain with 
peripherals like GPIO and Flash.

*******************************************************************************************************************************************/


module tilelink_master_top_new_updated #( 

	//////////////////////////////////////////////////////////////////
	////////////////////// Core interface widths /////////////////////
	//////////////////////////////////////////////////////////////////
	
	parameter TL_ADDR_WIDTH     = 64,            		// Address width
	parameter TL_DATA_WIDTH     = 64,            		// Data width
	parameter TL_STRB_WIDTH     = TL_DATA_WIDTH / 8, 	// Byte mask width/Byte strobe

	//////////////////////////////////////////////////////////////////
	//////////////////// TileLink metadata widths ////////////////////
	//////////////////////////////////////////////////////////////////
	
	parameter TL_SOURCE_WIDTH   = 3,			        // Request ID
	parameter TL_SINK_WIDTH     = 3,			        // Response ID
	parameter TL_OPCODE_WIDTH   = 3,			        // Opcode width
	parameter TL_PARAM_WIDTH    = 3,                  // Reserved (0)
	parameter TL_SIZE_WIDTH     = 8,                  // log2(size in bytes)
	
	// Opcodes for A Channel
	parameter PUT_FULL_DATA_A     = 3'd0,
	parameter PUT_PARTIAL_DATA_A  = 3'd1,
	parameter ARITHMETIC_DATA_A   = 3'd2,
	parameter LOGICAL_DATA_A      = 3'd3,
	parameter GET_A               = 3'd4,
	parameter INTENT_A            = 3'd5,
	parameter ACQUIRE_BLOCK_A     = 3'd6,
	parameter ACQUIRE_PERM_A      = 3'd7,

	// Opcodes for D Channel
	parameter ACCESS_ACK_D        = 3'd0,
	parameter ACCESS_ACK_DATA_D   = 3'd1,
	parameter HINT_ACK_D          = 3'd2,
	parameter GRANT_D             = 3'd4,
	parameter GRANT_DATA_D        = 3'd5,
	parameter RELEASE_ACK_D       = 3'd6,

	// Master FSM States
	parameter REQUEST 			 = 2'd1,
	parameter RESPONSE   		 = 2'd2,
	parameter CLEANUP 			 = 2'd3,
	parameter IDLE   			 = 2'd0	

)(
	input  wire                              clk,
	input  wire                              rst,

	// Inputs for commands from testbench, defined as a_valid_in, a_opcode_in, etc.
	input  wire                              a_valid_in,		// Slave ready to accept data
	input  wire [TL_OPCODE_WIDTH-1:0]        a_opcode_in,
	input  wire [TL_PARAM_WIDTH-1:0]         a_param_in,		// Reserved, 0
	input  wire [TL_ADDR_WIDTH-1:0]          a_address_in,
	input  wire [TL_SIZE_WIDTH-1:0]          a_size_in,
	input  wire [TL_STRB_WIDTH-1:0]          a_mask_in,
	input  wire [TL_DATA_WIDTH-1:0]          a_data_in,
	input  wire [TL_SOURCE_WIDTH-1:0]        a_source_in,

	// A Channel: Sent TO SLAVE (Master drives it)
	input  wire                              a_ready,			// Slave ready to accept data
	output reg                               a_valid, 			// Master asserts to send valid request
	output reg  [TL_OPCODE_WIDTH-1:0]        a_opcode,
	output reg  [TL_PARAM_WIDTH-1:0]         a_param,			// Reserved, 0
	output reg  [TL_ADDR_WIDTH-1:0]          a_address,
	output reg  [TL_SIZE_WIDTH-1:0]          a_size,
	output reg  [TL_STRB_WIDTH-1:0]          a_mask,
	output reg  [TL_DATA_WIDTH-1:0]          a_data,
	output reg  [TL_SOURCE_WIDTH-1:0]        a_source,

	// D Channel: Received FROM SLAVE
	input  wire                              d_valid, 			// Slave responds
	output wire                              d_ready, 			// Master ready to accept
	input  wire [TL_OPCODE_WIDTH-1:0]        d_opcode,
	input  wire [TL_PARAM_WIDTH-1:0]         d_param,
	input  wire [TL_SIZE_WIDTH-1:0]          d_size,
	input  wire [TL_SINK_WIDTH-1:0]          d_sink,
	input  wire [TL_SOURCE_WIDTH-1:0]        d_source,
	input  wire [TL_DATA_WIDTH-1:0]          d_data,
	input  wire                              d_error
);

	// State variable for slave FSM
	reg [1:0] master_state, next_state;

	// State flags
	wire is_idle;
	wire is_request;
	wire is_response;
	wire is_cleanup;
	
	reg d_ready_out;
	reg r_d_valid;

	// Registers for flopping A Channel signals
	// These registers hold the values for the A Channel signals that are sent to the slave.
	// They are useful in case the slave is not ready to accept the request in the current cycle.
	// They will be used to send the request in the next cycle when the slave is ready.
	reg                               r_a_valid; 			// Masterr_asserts to send valid request
	reg   [TL_OPCODE_WIDTH-1:0]       r_a_opcode;
	reg   [TL_PARAM_WIDTH-1:0]        r_a_param;			// Reserved; 0
	reg   [TL_ADDR_WIDTH-1:0]         r_a_address;
	reg   [TL_SIZE_WIDTH-1:0]         r_a_size;
	reg   [TL_STRB_WIDTH-1:0]         r_a_mask;
	reg   [TL_DATA_WIDTH-1:0]         r_a_data;
	reg   [TL_SOURCE_WIDTH-1:0]       r_a_source;


	// Defining a flag for distinguishing between immediate and delayed requests based on whether the slave is ready to accept the request.
	reg flag_a_ready; // This flag indicates whether the slave is ready to accept the request in the current cycle.
	


	///////////////////////////////////////////////////////////////
	//////////// 			 STATE MACHINE     	 	   ////////////
	///////////////////////////////////////////////////////////////
	
	assign is_idle    = (master_state == IDLE);      // Typically consider reset state as IDLE
	assign is_request  = (master_state == REQUEST);   // High when in REQUEST state
	assign is_response = (master_state == RESPONSE);  // High when in RESPONSE state
	assign is_cleanup  = (master_state == CLEANUP);   // High when in CLEANUP state
	

	// State machine for the master
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			master_state <= REQUEST; // Reset to IDLE state
		end else begin
			master_state <= next_state; // Transition to the next state
		end
	end

	// Next state logic

	always @(*) begin
		case (master_state)
//			IDLE: begin
//				if (a_valid_in) begin
//					next_state = REQUEST; // Transition to REQUEST state if a_valid_in is asserted
//				end else begin
//					next_state = IDLE; // Stay in IDLE state otherwise
//				end
//			end
			
			REQUEST: begin
				if (a_valid_in & a_ready) begin
					next_state = RESPONSE; // Transition to RESPONSE if slave response is valid
				end else begin
					next_state = REQUEST; // Stay in REQUEST state otherwise
				end
			end
			
			RESPONSE: begin
			    if (d_valid) begin
			         next_state = REQUEST;
//			    end
//				else if (!d_valid & r_d_valid) begin
//					next_state = REQUEST; // Transition to CLEANUP state if d_valid is asserted
				end else begin
					next_state = RESPONSE; // Stay in RESPONSE state otherwise
				end
			end
			
			CLEANUP: begin
					next_state = IDLE; // Transition back to IDLE state after cleanup
			end

			
			default: next_state = IDLE; // Default case to handle unexpected states
			
		endcase
	end




	/////////////////////////////////////////////////////////////
	//////////// 			   DATAPATH        	 	 ////////////
	/////////////////////////////////////////////////////////////
	
    assign d_ready = is_response;
	
	// Request logic
//	always @(posedge clk or posedge rst) begin
//		if (rst) begin
//			// Reset logic for A Channel registers
//			a_valid <= 1'b0; // Master is not ready to send data
//			a_opcode <= 0;
//			a_param  <= 0; // Reserved, 0
//			a_address <= 0;
//			a_size   <= 0;
//			a_mask   <= 0;
//			a_data   <= 0;
//			a_source <= 0;
//		end else if (a_valid_in & !a_valid) begin // Incoming command is valid and master is not busy
//			// Accept the incoming request from the testbench
//			a_valid <= a_valid_in; // Master is ready to send data
//			a_opcode <= a_opcode_in;
//			a_param  <= a_param_in;
//			a_address <= a_address_in;
//			a_size   <= a_size_in;
//			a_mask   <= a_mask_in;
//			a_data   <= a_data_in;
//			a_source <= a_source_in;
//		end else if (a_ready) begin
//			// This condition is when slave has accepted the request in the current cycle.
//			// So, we can clear the valid signal and reset the values
//			a_valid <= 1'b0; // Master is not ready to send data
//			a_opcode <= 0;
//			a_param  <= 0; // Reserved, 0
//			a_address <= 0;
//			a_size   <= 0;
//			a_mask   <= 0;
//			a_data   <= 0;
//			a_source <= 0;			
//		end
//		else begin
//			// This condition is when slave has not sent the response yet, so we keep the previous values
//			a_valid <= a_valid; // Keep the previous value
//			a_opcode <= a_opcode; // Keep the previous value
//			a_param  <= a_param; // Keep the previous value
//			a_address <= a_address; // Keep the previous value
//			a_size   <= a_size; // Keep the previous value
//			a_mask   <= a_mask; // Keep the previous value
//			a_data   <= a_data; // Keep the previous value
//			a_source <= a_source; // Keep the previous value
//		end
//	end


	// Block for flopping A Channel signals
	// This block is used to flop the A Channel signals that are sent to the slave.
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// Reset logic for A Channel registers
			r_a_valid <= 1'b0; // Master is not ready to send data
			r_a_opcode <= 0;
			r_a_param  <= 0; // Reserved, 0
			r_a_address <= 0;
			r_a_size   <= 0;
			r_a_mask   <= 0;
			r_a_data   <= 0;
			r_a_source <= 0; 
		end 
		else if (a_valid_in) begin
			// Flop the A Channel signals
			r_a_valid <= a_valid_in;
			r_a_opcode <= a_opcode_in;
			r_a_param  <= a_param_in;
			r_a_address <= a_address_in;
			r_a_size   <= a_size_in;
			r_a_mask   <= a_mask_in;
			r_a_data   <= a_data_in;
			r_a_source <= a_source_in; 
		end
		else if (is_response) begin
			// If in RESPONSE state, clear the valid signal and reset the values
			r_a_valid <= 1'b0; // Master is not ready to send data
			r_a_opcode <= 0;
			r_a_param  <= 0; // Reserved, 0
			r_a_address <= 0;
			r_a_size   <= 0;
			r_a_mask   <= 0;
			r_a_data   <= 0;
			r_a_source <= 0;			
		end
		// If not in RESPONSE state, keep the previous values
		else begin
			// Keep the previous values
			r_a_valid <= r_a_valid;
			r_a_opcode <= r_a_opcode;
			r_a_param  <= r_a_param;
			r_a_address <= r_a_address;
			r_a_size   <= r_a_size;
			r_a_mask   <= r_a_mask;
			r_a_data   <= r_a_data;
			r_a_source <= r_a_source;
		end
	end


	always @(*) begin
		if (rst) begin
			// Reset logic for A Channel registers
			a_valid   = 1'b0;
			a_opcode  = 0;
			a_param   = 0;
			a_address = 0;
			a_size    = 0;
			a_mask    = 0;
			a_data    = 0;
			a_source  = 0;
		end else if (a_valid_in) begin
			// New transaction in same cycle
			a_valid   = a_valid_in;
			a_opcode  = a_opcode_in;
			a_param   = a_param_in;
			a_address = a_address_in;
			a_size    = a_size_in;
			a_mask    = a_mask_in;
			a_data    = a_data_in;
			a_source  = a_source_in;
		end else if (is_request) begin
			// Hold previous values (registered versions)
			a_valid   = r_a_valid;
			a_opcode  = r_a_opcode;
			a_param   = r_a_param;
			a_address = r_a_address;
			a_size    = r_a_size;
			a_mask    = r_a_mask;
			a_data    = r_a_data;
			a_source  = r_a_source;
		end else begin
			// Default case: no transaction
			a_valid   = 1'b0;
			a_opcode  = 0;
			a_param   = 0;
			a_address = 0;
			a_size    = 0;
			a_mask    = 0;
			a_data    = 0;
			a_source  = 0;
		end
	end



	// Response logic
	// This logic is for the D channel, which is the response from the slave to the master.
	// Opcode is used to determine the type of response.
	 always @(posedge clk) begin
	 	if(rst) begin
//	 		d_ready_out <= 1'b0; // Master is not ready to accept data`
//	 		d_valid_in <= 0;
	 		r_d_valid <=  0;
	 	end
	 	else begin
//	 		d_ready_out <= is_response; // Master is ready to accept data when in RESPONSE state
//	 		d_ready <= d_ready_out;
//	 		d_valid_in <= d_valid;
	 		r_d_valid <= d_valid;
	 	end
	 end

endmodule