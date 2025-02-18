module alu (
    input logic enable,
    input logic [31:0] pc,
    input logic [31:0] operand_1,
    input logic [31:0] operand_2,
    input opcode_q opcode_t,
    input logic [31:0] immediate,
    input funct3_t function3,
    input funct7_t function7,
    output logic [31:0] result,
    output logic [31:0] next_pc
);
    always_comb begin
        if (enable) begin
            next_pc = (opcode_t == q_branch || opcode_t == q_jal || opcode_t == q_jalr) ? pc : pc + 4; // Default case for non-branching instructions

            case (opcode_t)

                q_load, q_store: result = operand_1 + $signed(immediate); 

                q_op: begin
                    case (function3)
                        ADD_SUB: begin
                            case (function7)
                                ADD_SRL_BEQ: result = operand_1 + operand_2;
                                SUB_SRA_BNE: result = operand_1 - operand_2;
                                default: result = 32'bx;
                            endcase
                        end
                        SLL: result = operand_1 << operand_2[4:0];
                        SLT: result = ($signed(operand_1) < $signed(operand_2)) ? 32'b1 : 32'b0;  
                        SLTU: result = (operand_1 < operand_2) ? 32'b1 : 32'b0; 
                        XOR_BLT: result = operand_1 ^ operand_2;
                        SRL_SRA_BGE: begin
                            case (function7)
                                ADD_SRL: result = operand_1 >> operand_2[4:0]; 
                                SUB_SRA: result = $signed(operand_1) >>> operand_2[4:0]; 
                                default: result = 32'bx;
                            endcase
                        end
                        OR_BLTU: result = operand_1 | operand_2;
                        AND_BGEU: result = operand_1 & operand_2;
                        default: result = 32'bx;
                    endcase
                end

                q_op_i: begin
                    case (function3)
                        ADD_SUB_BEQ: result = operand_1 + $signed(immediate); 
                        SLL_BNE: result = operand_1 << immediate[4:0];
                        SLT: result = ($signed(operand_1) < $signed(immediate)) ? 32'b1 : 32'b0; 
                        SLTU: result = (operand_1 < immediate) ? 32'b1 : 32'b0; 
                        XOR_BLT: result = operand_1 ^ immediate;
                        SRL_SRA_BGE: begin
                            case (function7)
                                ADD_SRL: result = operand_1 >> immediate[4:0]; 
                                SUB_SRA: result = $signed(operand_1) >>> immediate[4:0]; 
                                default: result = 32'bx;
                            endcase
                        end
                        OR_BLTU: result = operand_1 | immediate;
                        AND_BGEU: result = operand_1 & immediate;
                        default: result = 32'bx;
                    endcase
                end

                q_branch: begin
                    case (function3)
                        ADD_SUB_BEQ: if (operand_1 == operand_2) next_pc = pc + $signed(immediate);
                        SLL_BNE: if (operand_1 != operand_2) next_pc = pc + $signed(immediate);
                        XOR_BLT: if ($signed(operand_1) < $signed(operand_2)) next_pc = pc + $signed(immediate);
                        SRL_SRA_BGE: if ($signed(operand_1) >= $signed(operand_2)) next_pc = pc + $signed(immediate);
                        OR_BLTU: if (operand_1 < operand_2) next_pc = pc + immediate;
                        AND_BGEU: if (operand_1 >= operand_2) next_pc = pc + immediate;
                        default: next_pc = pc + 4;
                    endcase
                end

                // Jump instructions
                q_jal: next_pc = pc + $signed(immediate);
                q_jalr: next_pc = (operand_1 + $signed(immediate)) & ~32'b1; // Align to even address

                default: result = 32'bx;
            endcase
        end else begin
            result = 32'b0; // Default case when ALU is not enabled
            next_pc = pc;   // Keep the PC unchanged if ALU is disabled
        end
    end
endmodule
