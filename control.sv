`ifndef _core_v
`define _core_v
`include "system.sv"
`include "base.sv"
`include "memory_io.sv"
`include "memory.sv"

typedef logic [4:0] regname;
typedef logic [6:0] opcode;
typedef logic [2:0] funct3;
typedef logic [6:0] funct7;
typedef logic [11:0] i_imm;
typedef logic [20:0] uj_imm;
typedef logic [19:0] u_imm;
typedef logic [4:0] i_store;
typedef logic [31:0] dat;

module core(
    input logic       clk
    ,input logic      reset
    ,input logic      [`word_address_size-1:0] reset_pc
    ,output memory_io_req   inst_mem_req
    ,input  memory_io_rsp   inst_mem_rsp
    ,output memory_io_req   data_mem_req
    ,input  memory_io_rsp   data_mem_rsp
    );

typedef enum {
    stage_fetch
    ,stage_decode
    ,stage_execute
   // ,stage_mem
   //,stage_writeback
}   stage;

stage   current_stage;

opcode inst_code;
funct3 inst_funct3;
funct7 inst_funct7;
i_imm inst_i_imm;
regname rs1;
regname rs2;
regname rd;
dat data1;
dat data2;
dat alu_data;
logic write_enable;
logic [31:0] instruction;

register_file r (
    .clk(clk), 
    .rst(reset), 
    .write_enable(write_enable), 
    .write_data(alu_data), 
    .rs1(rs1), 
    .rs2(rs2), 
    .rd(rd), 
    .read_data1(data1), 
    .read_data2(data2)
);

alu a (
    .operand_1(data1), 
    .operand_2(data2), 
    .opcode_t2(inst_code), 
    .immediate(inst_i_imm), 
    .function3(inst_funct3), 
    .function7(inst_funct7), 
    .result(alu_data)
);

word    pc;
always_comb begin
	case(current_stage) 
		stage_fetch: begin
            //$display("%h", inst_mem_rsp.data);
		    inst_mem_req.addr = pc;
            inst_mem_req.do_read  = 4'b1111;
            inst_mem_req.valid = true;
		end
        
		stage_decode: begin
            inst_code = get_opcode(inst_mem_rsp.data);
	        inst_funct3 = get_funct3(inst_mem_rsp.data);
	        inst_funct7 = get_funct7(inst_mem_rsp.data);
	        inst_i_imm = get_i_imm(inst_mem_rsp.data);
	        rs1 = get_rs1(inst_mem_rsp.data);
	        rs2 = get_rs2(inst_mem_rsp.data);
	        rd = get_rd(inst_mem_rsp.data); 
			write_enable = zero;
		end
		
		stage_execute: begin
			write_enable = one;
		end

        default:
            $display("Should never get here");
	endcase	
end

always @(posedge clk) begin
   if (reset)
      pc <= reset_pc;

   if (current_stage == stage_execute) //stage_fetch
      pc <= pc + 4;
end

always @(posedge clk) begin
    if (reset)
        current_stage <= stage_fetch;
    else begin
        case (current_stage)
            stage_fetch:
                current_stage <= stage_decode;
            stage_decode:
                current_stage <= stage_execute;
            stage_execute:
                current_stage <= stage_fetch;//stage_mem
           /* stage_mem:
                current_stage <= stage_writeback;
            stage_writeback:
                current_stage <= stage_fetch; */
            default: begin
                $display("Should never get here");
                current_stage <= stage_fetch;
            end
        endcase
    end
end


endmodule

`endif


typedef enum logic [6:0] {
	R_ALU = 7'b0110011,
	I_ALU = 7'b0010011
} opcode_t;

typedef enum logic[2:0] {
	ADD_SUB = 3'b000,
	SLL = 3'b001,
	SLT = 3'b010,
	SLTU = 3'b011,
	XOR = 3'b100,
	SRL_SRA = 3'b101,
	OR = 3'b110,
	AND = 3'b111
}	funct3_t;

typedef enum logic [6:0] {
	ADD_SRL = 7'b0000000,
	SUB_SRA = 7'b0100000
} funct7_t;

// Helper functions to extract fields
function regname get_rd(logic [31:0] instr);
  return instr[11:7];
endfunction

function regname get_rs1(logic [31:0] instr);
  return instr[19:15];
endfunction

function regname get_rs2(logic [31:0] instr);
  return instr[24:20];
endfunction

function opcode get_opcode(logic [31:0] instr);
  return instr[6:0];
endfunction

function funct3 get_funct3(logic [31:0] instr);
  return instr[14:12];
endfunction

function funct7 get_funct7(logic [31:0] instr);
  return instr[31:25];
endfunction

function i_imm get_i_imm(logic [31:0] instr);
    return instr[31:20];
endfunction

function uj_imm get_uj_imm(logic [31:0] instr);
    return {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
endfunction

function u_imm get_u_imm(logic [31:0] instr);
    return instr[31:12];
endfunction

function i_store get_i_store(logic [31:0] instr);
    return instr[24:20];
endfunction

module register_file(
	input logic clk,
	input logic rst,
	input logic write_enable,
	input logic [31:0] write_data, //data to write to rd
	input logic [4:0] rs1, //register address to read from
	input logic [4:0] rs2, //register address to read from
	input logic [4:0] rd,  //register address to write to
	output logic [31:0] read_data1,
	output logic [31:0] read_data2
);
	
	logic [31:0]registers[4:0];
	
	always_ff@(posedge clk) begin
		if (rst) begin
			for (int i = 0; i<32; i++)
				registers[i] = 32'b0;
		end
		
		else if (write_enable & rd != 0) 
			registers[rd] <= write_data;
	end
	
	always_comb begin
		read_data1 = registers[rs1];
		read_data2 = registers[rs2];
	end
endmodule

module alu (
    input dat operand_1,
    input dat operand_2,
    input opcode_t opcode_t2,
    input i_imm immediate,
    input funct3_t function3,
    input funct7_t function7,
    output dat result
);

    always_comb begin
        case (opcode_t2)
            R_ALU: begin
                case (function3)
                    ADD_SUB: begin
                        case (function7)
                            ADD_SRL: result = operand_1 + operand_2;
                            SUB_SRA: result = operand_1 - operand_2;
                            default: result = 32'bx;
                        endcase
                    end

                    SLL: result = operand_1 << operand_2[4:0];

                    SLT: result = ($signed(operand_1) < $signed(operand_2)) ? 32'b1 : 32'b0;

                    SLTU: result = (operand_1 < operand_2) ? 32'b1 : 32'b0;

                    XOR: result = operand_1 ^ operand_2;

                    SRL_SRA: begin
                        case (function7)
                            ADD_SRL: result = operand_1 >> operand_2[4:0];
                            SUB_SRA: result = $signed(operand_1) >>> operand_2[4:0];
                            default: result = 32'bx;
                        endcase
                    end

                    OR: result = operand_1 | operand_2;

                    AND: result = operand_1 & operand_2;

                    default: result = 32'bx;
                endcase
            end

            I_ALU: begin
                case (function3)
                    ADD_SUB: result = operand_1 + $signed(immediate);

                    SLL: result = operand_1 << immediate[4:0];

                    SLT: result = ($signed(operand_1) < $signed(immediate)) ? 32'b1 : 32'b0;

                    SLTU: result = (operand_1 < immediate) ? 32'b1 : 32'b0;

                    XOR: result = operand_1 ^ immediate;

                    SRL_SRA: begin
                        case (function7)
                            ADD_SRL: result = operand_1 >> immediate[4:0];
                            SUB_SRA: result = $signed(operand_1) >>> immediate[4:0];
                            default: result = 32'bx;
                        endcase
                    end

                    OR: result = operand_1 | immediate;

                    AND: result = operand_1 & immediate;

                    default: result = 32'bx;
                endcase
            end

            default: result = 32'bx;
        endcase
    end

endmodule
