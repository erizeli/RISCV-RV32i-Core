typedef logic [4:0] regname;
typedef logic [6:0] opcode;
typedef logic [2:0] funct3;
typedef logic [6:0] funct7;
typedef logic [11:0] i_imm;
typedef logic [20:0] uj_imm;
typedef logic [19:0] u_imm;
typedef logic [4:0] i_store;

typedef enum opcode {
	R_ALU = 7'b0110011;
	I_ALU = 7'b0010011;
} opcode_t;

typedef enum funct3 {
	ADD_SUB = 3'b000;
	SLL = 3'b001;
	SLT = 3'b010;
	SLTU = 3'b011;
	XOR = 3'b100;
	SRL_SRA = 3'b101;
	OR = 3'b110;
	AND = 3'b111;
}	funct3_t;

typedef enum funct7 {
	ADD = 7'b0000000;
	SUB = 7'b0100000;
	SRL = 7'b0000000;
	SRA = 7'b0100000;
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

