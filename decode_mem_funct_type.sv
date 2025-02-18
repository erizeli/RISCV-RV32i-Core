typedef logic [`word_size-1:0] instruction;
typedef logic [4:0] regname; 
typedef logic [6:0] opcode;
typedef logic [2:0] funct3;
typedef logic [6:0] funct7;
typedef logic [4:0] shamt;

typedef enum {
     r_format = 0
    ,i_format
    ,s_format
    ,b_format
    ,u_format
    ,j_format
} instr_format;


typedef enum logic[2:0] {
	ADD_SUB_BEQ = 3'b000,
	SLL_BNE = 3'b001,
	SLT = 3'b010,
	SLTU = 3'b011,
	XOR_BLT = 3'b100,
	SRL_SRA_BGE = 3'b101,
	OR_BLTU = 3'b110,
	AND_BGEU = 3'b111
}	funct3_t;

typedef enum logic [6:0] {
	ADD_SRL = 7'b0000000,
	SUB_SRA = 7'b0100000
} funct7_t;

// Helper functions to extract fields
function regname get_rd(instruction instr);
  return instr[11:7];
endfunction

function regname get_rs1(instruction instr);
  return instr[19:15];
endfunction

function regname get_rs2(instruction instr);
  return instr[24:20];
endfunction


typedef enum logic [4:0] {
    q_load   = 5'b00000,
    q_store  = 5'b01000,
    q_op     = 5'b01100,
    q_op_i   = 5'b00100,
    q_auipc  = 5'b00101,
    q_lui    = 5'b01101,
    q_jal    = 5'b11011,
    q_jalr   = 5'b11001,
    q_branch = 5'b11100,
    q_unknown = 5'bx
} opcode_q;
  
function opcode get_opcode(instruction instr);
    case (instr[6:2])
            q_load:     return q_load;
            q_store:    return q_store;
            q_branch:   return q_branch;
            q_jalr:     return q_jalr;
            q_jal:      return q_jal;
            q_op_i:     return q_op_i;
            q_op:       return q_op;
            q_auipc:    return q_auipc;
            q_lui:      return q_lui;
        default:
            return q_unknown;
    endcase
endfunction

function funct3 get_funct3(instruction instr);
  return instr[14:12];
endfunction

function funct7 get_funct7(instruction instr);
  return instr[31:25];
endfunction

function instr_format get_format(opcode op);
    case(op)
        q_load, q_op_i, q_jalr:  return i_format;
        q_op:                     return r_format;
        q_store:                  return s_format;
        q_lui, q_auipc:           return u_format;
        q_branch:                 return b_format;
        q_jal:                    return j_format;   
        default:                  return r_format;
    endcase
endfunction

function logic [`word_size-1:0] get_imm(instruction instr, instr_format format);
    case(format)
        i_format : return { {(`word_size - 32 + 21){instr[31]}},           instr[30:25], instr[24:21], instr[20] };
        s_format : return { {(`word_size - 32 + 21){instr[31]}},           instr[30:25], instr[11:8], instr[7] };
        b_format: return {{19{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // SB-type (Branch, 13-bit signed)
        u_format : return { instr[31], instr[30:20], instr[19:12], {12{1'b0}} };
        j_format: return {{11{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0}; // J-type (JAL)
        default: return {`word_size{1'b0}};       
    endcase 
endfunction

function shamt get_shamt(instruction instr);
    return instr[24:20];
endfunction

function logic get_writeback(opcode in);
    case (in)
        q_load:   return 1'b1;
        q_op_i:   return 1'b1;
        q_op:     return 1'b1;
        q_auipc:  return 1'b1;
        q_lui:    return 1'b1;
        default:  return 1'b0;
    endcase
endfunction

// Must match instruction encoding
typedef enum logic [2:0] {
     memory_b = 0
    ,memory_h = 1
    ,memory_w = 2
    ,memory_bu = 4
    ,memory_hu = 5
}   memory_op;

function automatic memory_op cast_to_memory_op(funct3 in);
// This works, except Vivado complains. So we take the long way (below)
//    return in;  // Yes really
    case (in)
        memory_b: return memory_b;
        memory_h: return memory_h;
        memory_w: return memory_w;
        memory_bu: return memory_bu;
        memory_hu: return memory_hu;
        default: return memory_b;
    endcase;
endfunction


function automatic word shuffle_load_data(word in, word low_addr); begin
    logic [7:0] b0 = in[7:0];
    logic [7:0] b1 = in[15:8];
    logic [7:0] b2 = in[23:16];
    logic [7:0] b3 = in[31:24];

    case (low_addr[1:0])
        2'b00:  return { b3, b2, b1, b0 };
        2'b01:  return { b0, b3, b2, b1 };
        2'b10:  return { b1, b0, b3, b2 };
        2'b11:  return { b2, b1, b0, b3 };
    endcase
end
endfunction

function automatic word shuffle_store_data(word in, word low_addr); begin
    logic [7:0] b0 = in[7:0];
    logic [7:0] b1 = in[15:8];
    logic [7:0] b2 = in[23:16];
    logic [7:0] b3 = in[31:24];

    case (low_addr[1:0])
        2'b00:  return { b3, b2, b1, b0 };
        2'b01:  return { b2, b1, b0, b3 };
        2'b10:  return { b1, b0, b3, b2 };
        2'b11:  return { b0, b3, b2, b1 };
    endcase
end
endfunction

function word subset_load_data(word in, memory_op op);
    case (op)
        memory_b:   return { {24{in[7]}}, in[7:0] };
        memory_h:   return { {16{in[15]}}, in[15:0] };
        memory_w:   return in;
        memory_bu:  return { {24{1'b0}}, in[7:0] };
        memory_hu:  return { {16{1'b0}}, in[15:0] };
        default:    return in;
    endcase
endfunction

function automatic logic [3:0] shuffle_store_mask(logic [3:0] mask, word low_addr);
    case (low_addr[1:0])
        2'b00:  return { mask[3], mask[2], mask[1], mask[0] };
        2'b01:  return { mask[2], mask[1], mask[0], mask[3] };
        2'b10:  return { mask[1], mask[0], mask[3], mask[2] };
        2'b11:  return { mask[0], mask[3], mask[2], mask[1] };
    endcase
endfunction

function automatic logic [3:0] memory_mask(memory_op op);
    case (op)
        memory_b, memory_bu:    return 4'b0001;
        memory_h, memory_hu:    return 4'b0011;
        default:                return 4'b1111;
    endcase
endfunction
