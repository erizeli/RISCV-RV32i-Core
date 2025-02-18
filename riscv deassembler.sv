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

function void print_instruction(word pc, instruction instr, instr_format format);
    //$display("Debug: Instruction = %b, Opcode = %b, funct3 = %b, funct7 = %b", instr, get_opcode(instr), get_funct3(instr), get_funct7(instr));
    $write("%x: ", pc);
    $write("%x   ", instr);
   // More here that you do

  case(get_opcode(instr))
    q_lui: begin // LUI
      $write("lui     %s,0x%x", reg_to_abi(get_rd(instr)), get_imm(instr, format));
    end
    
    q_auipc: begin // AUIPC 
      $write("auipc   %s,0x%x", reg_to_abi(get_rd(instr)), get_imm(instr, format));
    end
    
    q_jal: begin // JAL
      $write("jal     %s,%0d", reg_to_abi(get_rd(instr)), $signed(get_imm(instr, format)));
    end
    
    q_jalr: begin // JALR
      $write("jalr    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
    end
    
    q_op_i: begin // I-type ALU
      case(get_funct3(instr))
        3'b000: $write("addi    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
        3'b010: $write("slti    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
        3'b011: $write("sltiu   %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), get_imm(instr, format));
        3'b100: $write("xori    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
        3'b110: $write("ori     %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
        3'b111: $write("andi    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
        3'b001: $write("slli    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), get_shamt(instr));
        3'b101: begin
          if (get_funct7(instr) == 7'b0)
            $write("srli    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), get_shamt(instr));
          else
            $write("srai    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), get_shamt(instr));
        end
      endcase
    end
	 
	 //R-type ALU
	q_op: begin 
		case(get_funct3(instr))
			3'b000: begin
				if (get_funct7(instr) == 7'b0)
					$write("add    %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
				else if (get_funct7(instr) == 7'b0100000)
					$write("sub    %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
					end
			3'b001: $write("sll	   %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
			3'b010: $write("slt	   %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));	
			3'b011: $write("sltu   %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
			3'b100: $write("xor	   %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
			3'b101: begin
				if (get_funct7(instr) == 7'b0)
					$write("srl	   %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
				else if (get_funct7(instr) == 7'b0100000)
					$write("sra	   %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
					end
			3'b110: $write("or	%s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
			3'b111: $write("and	 %s,%s,%s", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), reg_to_abi(get_rs2(instr)));
		endcase
	end
	
	//SB-type
	q_branch: begin
		case(get_funct3(instr))
			3'b000: $write("beq    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
			3'b001: $write("bne    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
			3'b100: $write("blt    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
			3'b101: $write("bge    %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
			3'b110: $write("bltu   %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
			3'b111: $write("bgeu   %s,%s,%0d", reg_to_abi(get_rd(instr)), reg_to_abi(get_rs1(instr)), $signed(get_imm(instr, format)));
			
			default: $write("unknown instr");
		endcase
	end
	
	//I-type load functions
	q_load: begin
		case(get_funct3(instr))
			3'b000: $write("lb    %s,%0d(%s)", reg_to_abi(get_rd(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			3'b001: $write("lh    %s,%0d(%s)", reg_to_abi(get_rd(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			3'b010: $write("lw    %s,%0d(%s)", reg_to_abi(get_rd(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			3'b100: $write("lbu   %s,%0d(%s)", reg_to_abi(get_rd(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			3'b101: $write("lhu   %s,%0d(%s)", reg_to_abi(get_rd(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			default: $write("unknown instr");
		endcase
	end
	
	//S-type
	q_store: begin
		case(get_funct3(instr))
			3'b000: $write("sb    %s,%0d(%s)", reg_to_abi(get_rs2(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			3'b001: $write("sh    %s,%0d(%s)", reg_to_abi(get_rs2(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
			3'b010: $write("sw    %s,%0d(%s)", reg_to_abi(get_rs2(instr)), $signed(get_imm(instr, format)), reg_to_abi(get_rs1(instr)));
		
			default: $write("unknown instr");
		endcase
	end
	
   default: $write("unknown instr");
 endcase
  
   $write("\n");
endfunction
