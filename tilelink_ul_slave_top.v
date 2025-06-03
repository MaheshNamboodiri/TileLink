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
	parameter TL_SOURCE_WIDTH   = 3,			 // Tags each request with a unique ID. The same ID must appear in the corresponding response.
	parameter TL_SINK_WIDTH     = 3,			 // Tags each response with an ID that matches that of the request.
	parameter TL_OPCODE_WIDTH   = 3,			 // Opcode width for instructions
	parameter TL_PARAM_WIDTH    = 3,             // Currently reserved for future performance hints and must be 0 
	parameter TL_SIZE_WIDTH     = 8,             // Width of size field, value of which determines data beat size in bytes as 2^size.
	

	// Define opcodes for channels
	// A Channel Opcodes
	parameter PUT_FULL_DATA_A     = 3'd0,
	parameter PUT_PARTIAL_DATA_A  = 3'd1,
	parameter ARITHMETIC_DATA_A   = 3'd2,
	parameter LOGICAL_DATA_A      = 3'd3,
	parameter GET_A               = 3'd4,
	parameter INTENT_A            = 3'd5,
	parameter ACQUIRE_BLOCK_A     = 3'd6,
	parameter ACQUIRE_PERM_A      = 3'd7,

	// D Channel Opcodes
	parameter ACCESS_ACK_D      = 3'd0,
	parameter ACCESS_ACK_DATA_D = 3'd1,
	parameter HINT_ACK_D        = 3'd2,
	parameter GRANT_D           = 3'd4,
	parameter GRANT_DATA_D      = 3'd5,
	parameter RELEASE_ACK_D     = 3'd6,
	
	// Slave FSM States
	parameter REQUEST 			 = 2'd0,
	parameter RESPONSE   		 = 2'd1,
	parameter CLEANUP 			 = 2'd2,
	parameter RESET   			 = 2'd3	
)(
	input  wire                              clk,
	input  wire                              rst,

	// A Channel: Received from MASTER
	output wire                              a_ready,		// Slave sends a_ready to Master to indicate that it is ready to accept data.
	input  wire                              a_valid, 		// Asserted to indicate valid instruction
	input  wire [TL_OPCODE_WIDTH-1:0]        a_opcode,		// Opcode for instruction
	input  wire [TL_PARAM_WIDTH-1:0]         a_param,		// Reserved, always 0.
	input  wire [TL_ADDR_WIDTH-1:0]          a_address,	    // Address 
	input  wire [TL_SIZE_WIDTH-1:0]          a_size,		// Width of full data sent in one go = 2^size. For TLUL, size = Data Width of Channel.
	input  wire [TL_STRB_WIDTH-1:0]          a_mask,		// Bit masking
	input  wire [TL_DATA_WIDTH-1:0]          a_data,		// Incoming data
	input  wire [TL_SOURCE_WIDTH-1:0]        a_source,		// Transaction ID

	// D Channel Sent to MASTER
	output reg 									     d_valid,
	input  wire                              d_ready, 		// Master ends d_ready to Slave to indicate that it is ready to accept data.
	output reg [TL_OPCODE_WIDTH-1:0]        d_opcode,
	output reg [TL_PARAM_WIDTH-1:0]         d_param,
	output reg [TL_SIZE_WIDTH-1:0]          d_size,
	output reg [TL_SINK_WIDTH-1:0]          d_sink,
	output reg [TL_SOURCE_WIDTH-1:0]        d_source,	
	output reg [TL_DATA_WIDTH-1:0]          d_data,
	output reg                              d_error
);

	// State variable for slave FSM
	reg [1:0] slave_state;

	// State flags
	wire in_reset;
	wire in_request;
	wire in_response;
	wire in_cleanup;
	
	// Memory Flags
	
	reg  [TL_ADDR_WIDTH-1:0] waddr;
	reg              		   wen;
	reg  [TL_DATA_WIDTH-1:0] wdata;
	wire  [TL_ADDR_WIDTH-1:0] raddr;
	wire [TL_DATA_WIDTH-1:0] rdata;
	
	
	// For loop variables
	integer i,j;
	
	// Registers for A Channel (Slave side input)
	reg                             a_ready_reg;
	reg [TL_OPCODE_WIDTH-1:0]       a_opcode_reg;
	reg [TL_PARAM_WIDTH-1:0]        a_param_reg;
	reg [TL_ADDR_WIDTH-1:0]         a_address_reg;
	reg [TL_SIZE_WIDTH-1:0]         a_size_reg;
	reg [TL_STRB_WIDTH-1:0]         a_mask_reg;
	reg [TL_DATA_WIDTH-1:0]         a_data_reg;
	reg [TL_SOURCE_WIDTH-1:0]       a_source_reg;

	// Registers for D Channel (Slave side output)
	reg                             d_valid_reg;
	reg [TL_OPCODE_WIDTH-1:0]       d_opcode_reg;
	reg [TL_PARAM_WIDTH-1:0]        d_param_reg;
	reg [TL_SIZE_WIDTH-1:0]         d_size_reg;
	reg [TL_SINK_WIDTH-1:0]         d_sink_reg;
	reg [TL_SOURCE_WIDTH-1:0]       d_source_reg;
	reg [TL_DATA_WIDTH-1:0]         d_data_reg;
	reg                             d_error_reg;
	// Wait signal
	
	reg wait_flag;
	
	/////////////////////////////////////////////////////////////
	//////////// 				  FSM BLOCK    	 	 	 ////////////
	/////////////////////////////////////////////////////////////	

	// Assign flags based on state
	assign in_reset    = (slave_state == RESET);
	assign in_request  = (slave_state == REQUEST);
	assign in_response = (slave_state == RESPONSE);
	assign in_cleanup  = (slave_state == CLEANUP);	
	
	
    assign raddr = in_request      ? a_address :
                   wait_flag   ? a_address_reg :
                                64'd0;
       
	
	// State machine

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			slave_state <= REQUEST;
		end
		else begin
			case (slave_state)

				REQUEST: begin
				if (a_valid)
					slave_state <= RESPONSE;
				else
					slave_state <= REQUEST;
				end

				RESPONSE: begin
					if (!d_ready) begin
						slave_state <= REQUEST;
						wait_flag <= 1;  
					end
					else begin
						slave_state <= RESPONSE;
						wait_flag <= 0;
					end
				end

				CLEANUP: begin
					slave_state <= REQUEST;
				end

				default: slave_state <= REQUEST;

			endcase
		end
	end
	
	
	/////////////////////////////////////////////////////////////
	//////////// 			   DATAPATH        	 	 ////////////
	/////////////////////////////////////////////////////////////		
	
	assign a_ready =  in_request;

	
	
	// Slave response
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic for any control registers or outputs
            wen   <= 1'b0;
            waddr <= {TL_ADDR_WIDTH{1'b0}};
            wdata <= {TL_DATA_WIDTH{1'b0}};
            // Add others as needed
        end else if (in_request | wait_flag) begin
            case (a_opcode )
                PUT_FULL_DATA_A: begin
                    // Full memory write
                    waddr <= a_address ;
                    wdata <= a_data ;
                    wen   <= 1'b1;

                    // Slave response
                    if (!wait_flag) begin
                        d_valid   <= 1'b1;
                        d_opcode  <= ACCESS_ACK_D;
                        d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0
                        d_size    <= a_size ;                 // Same as from MASTER
                        d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored
                        d_source  <= a_source ;               // Same as sent by MASTER
                        d_data    <= {TL_DATA_WIDTH{1'b0}};      // Ignored. Dataless response
                        d_error   <= 1'b0;                       // No error. Change later! Add error logic from memory (failed mem access etc).
                    end
                    else begin
                        d_valid   <= 1'b1;
                        d_opcode  <= ACCESS_ACK_D;
                        d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0
                        d_size    <= a_size_reg ;                 // Same as from MASTER
                        d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored
                        d_source  <= a_source_reg ;               // Same as sent by MASTER
                        d_data    <= {TL_DATA_WIDTH{1'b0}};      // Ignored. Dataless response
                        d_error   <= 1'b0;                       // No error. Change later! Add error logic from memory (failed mem access etc).                    
                    
                    end
                end

                PUT_PARTIAL_DATA_A: begin
                    // Partial write example (you may use mask  to gate bytes)
                    waddr <= a_address ;

                    // Masked Data
//                    for (i = 0; i < TL_STRB_WIDTH; i=i+1)
//                        for (j = 0; j < TL_STRB_WIDTH; j=j+1) 
//                            wdata[j + i*8] <= a_data [j + i*8] & a_mask [i];

//                    wen   <= 1'b1;

                    // Slave response
                    if(!wait_flag) begin
                        d_valid   <= 1'b1;
                        d_opcode  <= ACCESS_ACK_D;
                        d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0
                        d_size    <= a_size ;                 // Same as from MASTER
                        d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored
                        d_source  <= a_source ;               // Same as sent by MASTER
                        d_data    <= {TL_DATA_WIDTH{1'b0}};      // Ignored. Dataless response
                        d_error   <= 1'b0;                        // No error. Change later! Add error logic from memory (failed mem access etc).

                        for (i = 0; i < TL_STRB_WIDTH; i=i+1)
                            for (j = 0; j < TL_STRB_WIDTH; j=j+1) 
                                wdata[j + i*8] <= a_data [j + i*8] & a_mask [i];
    
                        wen   <= 1'b1;                        
                    end
                    else begin
                        d_valid   <= 1'b1;
                        d_opcode  <= ACCESS_ACK_D;
                        d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0
                        d_size    <= a_size_reg ;                 // Same as from MASTER
                        d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored
                        d_source  <= a_source_reg ;               // Same as sent by MASTER
                        d_data    <= {TL_DATA_WIDTH{1'b0}};      // Ignored. Dataless response
                        d_error   <= 1'b0;                        // No error. Change later! Add error logic from memory (failed mem access etc).                    

                        for (i = 0; i < TL_DATA_WIDTH; i=i+1) wdata[i] <= 0;
//                            for (j = 0; j < TL_STRB_WIDTH; j=j+1) 
//                                wdata[j + i*8] <= a_data [j + i*8] & a_mask [i];
    
                        wen   <= 1'b0;                      
                    end
                end

//                ARITHMETIC_DATA_A: begin
//                    // Placeholder for arithmetic
//                    wen <= 1'b0;
//                end

//                LOGICAL_DATA_A: begin
//                    // Placeholder for logic ops
//                    wen <= 1'b0;
//                end

                GET_A: begin
                    // Read only - no write enable
                    wen <= 1'b0;
//                    raddr <= a_address ;

                    // Slave response
                    d_valid   <= 1'b1;
                    d_opcode  <= ACCESS_ACK_DATA_D;
                    d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0
                    d_size    <= a_size ;                 // Same as from MASTER
                    d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored
                    d_source  <= a_source ;               // Same as sent by MASTER
                    d_data    <= rdata;                      // Data requested. Single data, no burst.
                    d_error   <= 1'b0;                        // No error. Change later! Add error logic from memory (failed mem access etc).
                end

//                INTENT_A: begin
//                    // No effect
//                    wen <= 1'b0;
//                end

//                ACQUIRE_BLOCK_A: begin
//                    wen <= 1'b0;
//                end

//                ACQUIRE_PERM_A: begin
//                    wen <= 1'b0;
//                end

                default: begin
                    wen <= 1'b0;
                    d_valid   <= 1'b0;                                                                                                      
                    d_opcode  <= 0;                                                                                              
                    d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0                                                               
                    d_size    <= 0 ;                 // Same as from MASTER                                                            
                    d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored                                                                     
                    d_source  <= 0 ;               // Same as sent by MASTER                                                         
                    d_data    <= {TL_DATA_WIDTH{1'b0}};      // Ignored. Dataless response                                                  
                    d_error   <= 1'b0;                       // No error. Change later! Add error logic from memory (failed mem access etc).                    
                end
            endcase
        end else begin
            wen <= 1'b0; // Deassert write when not responding
//            wen <= 1'b0;
            d_valid   <= 1'b0;                                                                                                      
            d_opcode  <= 0;                                                                                              
            d_param   <= {TL_PARAM_WIDTH{1'b0}};     // Reserved at 0                                                               
            d_size    <= 0 ;                 // Same as from MASTER                                                            
            d_sink    <= {TL_SINK_WIDTH{1'b0}};      // Ignored                                                                     
            d_source  <= 0 ;               // Same as sent by MASTER                                                         
            d_data    <= {TL_DATA_WIDTH{1'b0}};      // Ignored. Dataless response                                                  
            d_error   <= 1'b0;                       // No error. Change later! Add error logic from memory (failed mem access etc).             
        end
    end


	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// A Channel Registers
			a_ready_reg   <= 1'b0;
			a_opcode_reg  <= {TL_OPCODE_WIDTH{1'b0}};
			a_param_reg   <= {TL_PARAM_WIDTH{1'b0}};
			a_address_reg <= {TL_ADDR_WIDTH{1'b0}};
			a_size_reg    <= {TL_SIZE_WIDTH{1'b0}};
			a_mask_reg    <= {TL_STRB_WIDTH{1'b0}};
			a_data_reg    <= {TL_DATA_WIDTH{1'b0}};
			a_source_reg  <= {TL_SOURCE_WIDTH{1'b0}};

			// D Channel Registers
			d_valid_reg   <= 1'b0;
			d_opcode_reg  <= {TL_OPCODE_WIDTH{1'b0}};
			d_param_reg   <= {TL_PARAM_WIDTH{1'b0}};
			d_size_reg    <= {TL_SIZE_WIDTH{1'b0}};
			d_sink_reg    <= {TL_SINK_WIDTH{1'b0}};
			d_source_reg  <= {TL_SOURCE_WIDTH{1'b0}};
			d_data_reg    <= {TL_DATA_WIDTH{1'b0}};
			d_error_reg   <= 1'b0;
		end
		else begin
			if (a_valid) begin
				a_opcode_reg  <= a_opcode;
				a_param_reg   <= a_param;
				a_address_reg <= a_address;
				a_size_reg    <= a_size;
				a_mask_reg    <= a_mask;
				a_data_reg    <= a_data;
				a_source_reg  <= a_source;
			end
			// else begin
			// 	a_opcode_reg  <= 0;
			// 	a_param_reg   <= 0;
			// 	a_address_reg <= 0;
			// 	a_size_reg    <= 0;
			// 	a_mask_reg    <= 0;
			// 	a_data_reg    <= 0;
			// 	a_source_reg  <= 0;			
			// end
		end
	end




	


	


	
	
memory_block #(
    .TL_DATA_WIDTH(TL_DATA_WIDTH),      // Data width for memory
    .DEPTH(512),                // Memory depth (number of entries)
    .TL_ADDR_WIDTH(TL_ADDR_WIDTH)       // Address width
) memory_inst (
    .clk(clk),                  // Clock input
    .rst(rst),                // Reset input
    .waddr(waddr),              // Write address from slave logic
    .wen(wen),                  // Write enable from slave logic
    .wdata(wdata),              // Write data from slave logic
    .raddr(raddr),              // Read address from slave logic
    .rdata(rdata)               // Read data to be sent back to master
);      
      
      
endmodule
      
      
      

	/////////////////////////////////////////////////////////////
	//////////// 				CPU MEMORY     	 	 	 ////////////
	/////////////////////////////////////////////////////////////	

	// Dual Port RAM
	
	module memory_block # (
		parameter TL_DATA_WIDTH = 8,
		parameter DEPTH = 512,
		parameter TL_ADDR_WIDTH = $clog2(DEPTH)
	)(
		input  clk,
		input  rst,
		input  [TL_ADDR_WIDTH-1:0] waddr,
		input  wen,
		input  [TL_DATA_WIDTH-1:0] wdata,
		input  [TL_ADDR_WIDTH-1:0] raddr,
		output [TL_DATA_WIDTH-1:0] rdata
	);

	reg [TL_DATA_WIDTH-1:0] mem [0:500-1];

	reg [TL_ADDR_WIDTH-1:0] r_raddr, r_waddr;
	reg [TL_DATA_WIDTH-1:0] r_rdata, r_wdata;
	reg r_wen;

	integer i;

// 	initial begin
// 		for (i = 0; i < DEPTH; i = i + 1) begin
// 			mem[i] = 0;
// 		end
// 	end

	always @ (posedge clk) begin
		if (rst) begin
//			r_raddr <= 0;
			r_waddr <= 0;
			r_wdata <= 0;
			r_rdata <= 0;
		end else begin
//			r_raddr <= raddr;
			r_wen <= wen;
			r_waddr <= waddr;
			r_wdata <= wdata;
			r_rdata <= mem[raddr];
			
			if (wen) mem[waddr] <= wdata;
		end
	end

	assign rdata = mem[raddr];
      
    endmodule      




// Shift register for data masking

always @(posedge clk) begin
	data = {{1'b0}, a_data[TL_DATA_WIDTH-1:1]};

	for (i = 0; i < 5; i = i + 1) begin
		data[i] <= data[i-1];
	end	
end
