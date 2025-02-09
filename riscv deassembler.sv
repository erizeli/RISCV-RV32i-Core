typedef logic [4:0] regname;
typedef logic [6:0] opcode;
typedef logic [2:0] funct3;
typedef logic [6:0] funct7;
typedef logic [11:0] i_imm;
typedef logic [20:0] uj_imm;
typedef logic [19:0] u_imm;
typedef logic [4:0] i_store;

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

function string reg_to_abi(regname regt);
  case(regt)
    5'd0: return "zero";
    5'd1: return "ra";
    5'd2: return "sp";
    5'd3: return "gp";
	 5'd4: return "tp";
	 5'd5: return "t0";
	 5'd6: return "t1";
	 5'd7: return "t2";
	 5'd8: return "s0";
	 5'd9: return "s1";
	 5'd10: return "a0";
	 5'd11: return "a1";
	 5'd12: return "a2";
	 5'd13: return "a3";
	 5'd14: return "a4";
	 5'd15: return "a5";
	 5'd16: return "a6";
	 5'd17: return "a7";
	 5'd18: return "s2";
	 5'd19: return "s3";
	 5'd20: return "s4";
	 5'd21: return "s5";
	 5'd22: return "s6";
	 5'd23: return "s7";
	 5'd24: return "s8";
	 5'd25: return "s9";
	 5'd26: return "s10";
	 5'd27: return "s11";
	 5'd28: return "t3";
	 5'd29: return "t4";
	 5'd30: return "t5";
	 5'd31: return "t6";

    default: return $sformatf("x%d", regt);
  endcase
endfunction

function void print_instruction(logic [31:0] pc, logic [31:0] instruction);
    //$display("Debug: Instruction = %b, Opcode = %b, funct3 = %b, funct7 = %b", instruction, get_opcode(instruction), get_funct3(instruction), get_funct7(instruction));
    $write("%x: ", pc);
    $write("%x   ", instruction);
   // More here that you do

  case(get_opcode(instruction))
    7'b0110111: begin // LUI
      $write("lui     %s,0x%x", reg_to_abi(get_rd(instruction)), get_u_imm(instruction));
    end
    
    7'b0010111: begin // AUIPC 
      $write("auipc   %s,0x%x", reg_to_abi(get_rd(instruction)), get_u_imm(instruction));
    end
    
    7'b1101111: begin // JAL
      $write("jal     %s,%0d", reg_to_abi(get_rd(instruction)), $signed(get_uj_imm(instruction)));
    end
    
    7'b1100111: begin // JALR
      $write("jalr    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(get_i_imm(instruction)));
    end
    
    7'b0010011: begin // I-type ALU
      case(get_funct3(instruction))
        3'b000: $write("addi    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(get_i_imm(instruction)));
        3'b010: $write("slti    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(get_i_imm(instruction)));
        3'b011: $write("sltiu   %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), get_i_imm(instruction));
        3'b100: $write("xori    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(get_i_imm(instruction)));
        3'b110: $write("ori     %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(get_i_imm(instruction)));
        3'b111: $write("andi    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(get_i_imm(instruction)));
        3'b001: $write("slli    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), get_i_store(instruction));
        3'b101: begin
          if (get_funct7(instruction) == 7'b0)
            $write("srli    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), get_i_store(instruction));
          else
            $write("srai    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), get_i_store(instruction));
        end
      endcase
    end
	 
	 //R-type ALU
	7'b0110011: begin 
		case(get_funct3(instruction))
			3'b000: begin
				if (get_funct7(instruction) == 7'b0)
					$write("add    %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
				else if (get_funct7(instruction) == 7'b0100000)
					$write("sub    %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
					end
			3'b001: $write("sll	   %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
			3'b010: $write("slt	   %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));	
			3'b011: $write("sltu   %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
			3'b100: $write("xor	   %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
			3'b101: begin
				if (get_funct7(instruction) == 7'b0)
					$write("srl	   %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
				else if (get_funct7(instruction) == 7'b0100000)
					$write("sra	   %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
					end
			3'b110: $write("or	%s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
			3'b111: $write("and	 %s,%s,%s", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), reg_to_abi(get_rs2(instruction)));
		endcase
	end
	
	//SB-type
	7'b1100011: begin
		logic [12:0] imm;
		  imm[12] = instruction[31];    // imm[12]
		  imm[11] = instruction[7];     // imm[11]
		  imm[10:5] = instruction[30:25]; // imm[10:5]
		  imm[4:1] = instruction[11:8];   // imm[4:1]
		  imm[0] = 1'b0;                // Implicit 0
		case(get_funct3(instruction))
			3'b000: $write("beq    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(imm));
			3'b001: $write("bne    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(imm));
			3'b100: $write("blt    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(imm));
			3'b101: $write("bge    %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(imm));
			3'b110: $write("bltu   %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(imm));
			3'b111: $write("bgeu   %s,%s,%0d", reg_to_abi(get_rd(instruction)), reg_to_abi(get_rs1(instruction)), $signed(imm));
			
			default: $write("unknown instruction");
		endcase
	end
	
	//I-type load functions
	7'b0000011: begin
		case(get_funct3(instruction))
			3'b000: $write("lb    %s,%0d(%s)", reg_to_abi(get_rd(instruction)), $signed(get_i_imm(instruction)), reg_to_abi(get_rs1(instruction)));
			3'b001: $write("lh    %s,%0d(%s)", reg_to_abi(get_rd(instruction)), $signed(get_i_imm(instruction)), reg_to_abi(get_rs1(instruction)));
			3'b010: $write("lw    %s,%0d(%s)", reg_to_abi(get_rd(instruction)), $signed(get_i_imm(instruction)), reg_to_abi(get_rs1(instruction)));
			3'b100: $write("lbu   %s,%0d(%s)", reg_to_abi(get_rd(instruction)), $signed(get_i_imm(instruction)), reg_to_abi(get_rs1(instruction)));
			3'b101: $write("lhu   %s,%0d(%s)", reg_to_abi(get_rd(instruction)), $signed(get_i_imm(instruction)), reg_to_abi(get_rs1(instruction)));
			default: $write("unknown instruction");
		endcase
	end
	
	//S-type
	7'b0100011: begin
		logic [11:0] imm;
		imm[11:5] = instruction[31:25];
		imm[4:0] = instruction[11:7];
		
		case(get_funct3(instruction))
			3'b000: $write("sb    %s,%0d(%s)", reg_to_abi(get_rs2(instruction)), $signed(imm), reg_to_abi(get_rs1(instruction)));
			3'b001: $write("sh    %s,%0d(%s)", reg_to_abi(get_rs2(instruction)), $signed(imm), reg_to_abi(get_rs1(instruction)));
			3'b010: $write("sw    %s,%0d(%s)", reg_to_abi(get_rs2(instruction)), $signed(imm), reg_to_abi(get_rs1(instruction)));
		
			default: $write("unknown instruction");
		endcase
	end
	
   default: $write("unknown instruction");
 endcase
  
   $write("\n");
endfunction

