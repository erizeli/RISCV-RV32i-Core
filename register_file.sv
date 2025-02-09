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
