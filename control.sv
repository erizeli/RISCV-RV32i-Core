`ifndef _core_v
`define _core_v
`include "system.sv"
`include "base.sv"
`include "memory_io.sv"
`include "memory.sv"

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
    ,stage_mem
    ,stage_writeback
}   stage;

stage   current_stage;

opcode inst_code;
funct3 inst_funct3;
funct7 inst_funct7;
word imm;
shamt sham;
regname rs1;
regname rs2;
regname rd;
word data1;
word data2;
word write_data;
word alu_data;
instr_format format;
logic write_enable;
logic read_enable;
logic exec_enable;
logic wb_valid;
logic memory_stage_complete;

word pc;
word next_pc;

register_file r (
    .clk(clk), 
    .rst(reset), 
    .read_enable(read_enable),
    .write_enable(write_enable), 
    .write_data(write_data), 
    .rs1(rs1), 
    .rs2(rs2), 
    .rd(rd), 
    .read_data1(data1), 
    .read_data2(data2)
);

alu a (
    .enable(exec_enable),
    .pc(pc),
    .operand_1(data1), 
    .operand_2(data2), 
    .opcode_t(inst_code), 
    .immediate(imm), 
    .function3(inst_funct3), 
    .function7(inst_funct7), 
    .result(alu_data),
    .next_pc(next_pc)
);

instruction latched_instruction;
always @(posedge clk) begin
	if (inst_mem_rsp.valid) 
		latched_instruction <= inst_mem_rsp.data;
end

instruction fetched_instruction;
assign fetched_instruction = (inst_mem_rsp.valid) ? inst_mem_rsp.data : latched_instruction;

assign inst_mem_req.addr = pc;
assign inst_mem_req.valid = inst_mem_rsp.ready && (stage_fetch == current_stage);
assign inst_mem_req.do_read = (current_stage == stage_fetch) ? 4'b1111 : 0;

assign read_enable = (current_stage == stage_decode) ? true : false;
assign wb_valid = get_writeback(inst_code);

always_comb begin
    if (inst_code == q_load || inst_code == q_store) begin
        if (data_mem_rsp.valid)
            memory_stage_complete = true;
        else
            memory_stage_complete = false;
    end else
        memory_stage_complete = true;
end

assign write_enable = (memory_stage_complete && current_stage == stage_writeback && wb_valid) ? true: false;

always_comb begin
	inst_code = get_opcode(fetched_instruction);
	inst_funct3 = get_funct3(fetched_instruction);
	inst_funct7 = get_funct7(fetched_instruction);
	rs1 = get_rs1(fetched_instruction);
	rs2 = get_rs2(fetched_instruction);
	rd = get_rd(fetched_instruction); 
	format = get_format(inst_code);
	imm = get_imm(fetched_instruction, format);
end

assign exec_enable = (current_stage == stage_execute) ? true : false;

always_comb begin
    data_mem_req = memory_io_no_req32; //sets default request to invalid

    if (data_mem_rsp.ready && current_stage == stage_mem && (inst_code == q_store || inst_code == q_load)) begin
        data_mem_req.addr = alu_data[`word_address_size - 1:0];
        if (inst_code == q_store) begin
            data_mem_req.valid = true;
            data_mem_req.do_write = shuffle_store_mask(memory_mask(cast_to_memory_op(inst_funct3)), alu_data);
            data_mem_req.data = shuffle_store_data(data2, alu_data);
        end else
        if (inst_code == q_load) begin
            data_mem_req.valid = true;
            data_mem_req.do_read = shuffle_store_mask(memory_mask(cast_to_memory_op(inst_funct3)), alu_data);
        end
    end
end

word load_result;
always_ff @(posedge clk) begin
    if (data_mem_rsp.valid)
        load_result <= data_mem_rsp.data;
end

always_comb begin
    if (inst_code == q_load)
        rd = subset_load_data(
                    shuffle_load_data(data_mem_rsp.valid ? data_mem_rsp.data : load_result, alu_data),
                    cast_to_memory_op(inst_funct3));
    else
        rd = alu_data;

end
always @(posedge clk) begin
   if (reset)
      pc <= reset_pc;

   if (current_stage == stage_execute) //stage_fetch
      pc <= pc + 4;
end

always_ff @(posedge clk) begin
    if (reset)
        current_stage <= stage_fetch;
    else begin
        case (current_stage)
            stage_fetch: begin
                $display("[FETCH]: pc: %h   instruction: %h", pc, fetched_instruction);
                if (inst_mem_rsp.valid)
                    current_stage <= stage_decode;
            end stage_decode: begin
                $write("[DECODE]:   ");
                print_instruction(pc, fetched_instruction, format);
                current_stage <= stage_execute;
            end stage_execute: begin
                $display("[EXECUTE] : result: %d", alu_data);
                current_stage <= stage_mem;
            end stage_mem: begin
                $display("[MEM]");
                current_stage <= stage_writeback;
            end stage_writeback: begin
                $display("[WB]");
                if (memory_stage_complete)
                    current_stage <= stage_fetch;
            end default: begin
                $display("[???]");
                current_stage <= stage_fetch;
            end
        endcase
    end
end


endmodule
`endif
