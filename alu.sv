module alu (
    input data operand_1,
    input data operand_2,
    input opcode_t opcode_t2,
    input i_imm immediate,
    input funct3_t function3,
    input funct7_t function7,
    output data result
);

    always_comb begin
        case (opcode_t2)
            opcode_t'R_ALU: begin
                case (function3)
                    funct3_t'ADD_SUB: begin
                        case (function7)
                            funct7_t'ADD: result = operand_1 + operand_2;
                            funct7_t'SUB: result = operand_1 - operand_2;
                            default: result = 32'bx;
                        endcase
                    end

                    funct3_t'SLL: result = operand_1 << operand_2[4:0];

                    funct3_t'SLT: result = ($signed(operand_1) < $signed(operand_2)) ? 32'b1 : 32'b0;

                    funct3_t'SLTU: result = (operand_1 < operand_2) ? 32'b1 : 32'b0;

                    funct3_t'XOR: result = operand_1 ^ operand_2;

                    funct3_t'SRL_SRA: begin
                        case (function7)
                            funct7_t'SRL: result = operand_1 >> operand_2[4:0];
                            funct7_t'SRA: result = $signed(operand_1) >>> operand_2[4:0];
                            default: result = 32'bx;
                        endcase
                    end

                    funct3_t'OR: result = operand_1 | operand_2;

                    funct3_t'AND: result = operand_1 & operand_2;

                    default: result = 32'bx;
                endcase
            end

            opcode_t'I_ALU: begin
                case (function3)
                    funct3_t'ADD_SUB: result = operand_1 + $signed(immediate);

                    funct3_t'SLL: result = operand_1 << immediate[4:0];

                    funct3_t'SLT: result = ($signed(operand_1) < $signed(immediate)) ? 32'b1 : 32'b0;

                    funct3_t'SLTU: result = (operand_1 < immediate) ? 32'b1 : 32'b0;

                    funct3_t'XOR: result = operand_1 ^ immediate;

                    funct3_t'SRL_SRA: begin
                        case (function7)
                            funct7_t'SRL: result = operand_1 >> immediate[4:0];
                            funct7_t'SRA: result = $signed(operand_1) >>> immediate[4:0];
                            default: result = 32'bx;
                        endcase
                    end

                    funct3_t'OR: result = operand_1 | immediate;

                    funct3_t'AND: result = operand_1 & immediate;

                    default: result = 32'bx;
                endcase
            end

            default: result = 32'bx;
        endcase
    end

endmodule
