`timescale 1ns / 1ps

module serial_crc (
    input wire clk,
    input wire reset,
    input wire start_of_frame,
    input wire end_of_frame,
    input wire data_in,
    output wire [31:0] fcs_output, 
    output wire fcs_error
);

logic done = 1'b0;
logic product = 1'b1;
logic end_shift = 1'b1;

logic complement_end = 1'b0;

logic [12:0] bit_c = 0;
logic [10:0] upper_complement_c = 0;

// FCS registers
logic [31:0] fcs_reg = 0;
logic [31:0] debug_reg = 0; // debugging
// Skip check for initial fields (Preamble, SFD, etc.)
wire skip_check = (bit_c > 61) ? 1'b1 : 1'b0;

// **FSM State Definitions**
typedef enum logic [1:0] {
    IDLE, 
    SKIP,  
    CAPTURE_AND_CALCULATE
} state_t;
    
state_t current_state, next_state;

// **FSM State Transition Logic**
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin
    case (current_state)
        IDLE: 
            next_state = start_of_frame ? SKIP : IDLE;
        
        SKIP: 
            next_state = skip_check ? CAPTURE_AND_CALCULATE : SKIP;
        
        CAPTURE_AND_CALCULATE: 
            next_state = done ? IDLE : CAPTURE_AND_CALCULATE;
    endcase
end

// **Main Processing Logic**
always_ff @(posedge clk) begin
    case (current_state)
        IDLE: begin
            bit_c <= 0;
            complement_end <= 1'b0;
        end

        SKIP: begin
            bit_c <= bit_c + 1;
        end

        CAPTURE_AND_CALCULATE: begin
            bit_c <= bit_c + 1;
            if (end_of_frame)
                    complement_end <= 1'b1;
            if (upper_complement_c < 32 || complement_end || end_of_frame) begin
                upper_complement_c <= upper_complement_c + 1;
                debug_reg[31:0] <= {data_in, debug_reg[31:1]};
                fcs_reg[0] <= ~data_in ^ fcs_reg[31];
            end else begin
                fcs_reg[0] <= data_in ^ fcs_reg[31];
            end
            if (end_shift) begin 
                fcs_reg[1]  <= fcs_reg[0]  ^ fcs_reg[31];
                fcs_reg[2]  <= fcs_reg[1]  ^ fcs_reg[31];
                fcs_reg[3]  <= fcs_reg[2];
                fcs_reg[4]  <= fcs_reg[3]  ^ fcs_reg[31];
                fcs_reg[5]  <= fcs_reg[4]  ^ fcs_reg[31];
                fcs_reg[6]  <= fcs_reg[5];
                fcs_reg[7]  <= fcs_reg[6]  ^ fcs_reg[31];
                fcs_reg[8]  <= fcs_reg[7]  ^ fcs_reg[31];
                fcs_reg[9]  <= fcs_reg[8];
                fcs_reg[10] <= fcs_reg[9]  ^ fcs_reg[31];
                fcs_reg[11] <= fcs_reg[10] ^ fcs_reg[31];
                fcs_reg[12] <= fcs_reg[11] ^ fcs_reg[31];
                fcs_reg[13] <= fcs_reg[12];
                fcs_reg[14] <= fcs_reg[13];
                fcs_reg[15] <= fcs_reg[14];
                fcs_reg[16] <= fcs_reg[15] ^ fcs_reg[31];
                fcs_reg[17] <= fcs_reg[16];
                fcs_reg[18] <= fcs_reg[17];
                fcs_reg[19] <= fcs_reg[18];
                fcs_reg[20] <= fcs_reg[19];
                fcs_reg[21] <= fcs_reg[20];
                fcs_reg[22] <= fcs_reg[21] ^ fcs_reg[31];
                fcs_reg[23] <= fcs_reg[22] ^ fcs_reg[31];
                fcs_reg[24] <= fcs_reg[23];
                fcs_reg[25] <= fcs_reg[24];
                fcs_reg[26] <= fcs_reg[25] ^ fcs_reg[31];
                fcs_reg[27] <= fcs_reg[26];
                fcs_reg[28] <= fcs_reg[27];
                fcs_reg[29] <= fcs_reg[28];
                fcs_reg[30] <= fcs_reg[29];
                fcs_reg[31] <= fcs_reg[30];  
            end
            if (complement_end && upper_complement_c == 62) 
                end_shift <= 
                done <= 1'b1;
        end
    endcase
end

assign fcs_output = fcs_reg;
assign fcs_error = (fcs_reg == 32'b0) ? 1'b0 : 1'b1;

endmodule
