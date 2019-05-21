
module SPI_Slave
	#(parameter	DataWidth	= 8,
				BuferSize	= 8)
	(input logic					i_SCK, i_NRESET,

	input logic						i_NCE,
	input logic						i_MOSI,
	output logic					o_MISO,

	//	CPU Interface
	input logic[(DataWidth - 1):0]	i_WriteData,
	output logic[(DataWidth - 1):0]	o_ReadData);

	int				BuferCounter, WriteBuferCounter, ReadBuferCounter;
	logic[2:0]		BitCounter;
	logic 			s_MISO;
	logic[(DataWidth - 1):0]	s_ReadData_Reg;
	logic[(DataWidth - 1):0]	s_DataBufer[(BuferSize - 1):0];


	//	Communication logic
	always_ff	@(posedge i_SCK, negedge i_NRESET)
	begin
		if (~i_NRESET)
		begin
			int i;
			for (i = 0; i < BuferSize; i = i + 1)	s_DataBufer[i] <= 8'b0;
			BuferCounter	<= 0;
			//WriteBuferCounter = 0;	ReadBuferCounter = 0;
			BitCounter		<= 3'b111;
		end
		else if (~i_NCE)
		begin
			s_DataBufer[BuferCounter][BitCounter] <= i_MOSI;
			s_MISO <= s_DataBufer[BuferCounter + (BuferSize - 1)][BitCounter];
			if (BitCounter <= 3'b000)
			begin
				BitCounter <= 3'b111;
				if (BuferCounter >= BuferSize)			BuferCounter <= 0;
				else									BuferCounter <= BuferCounter + 1;
			end
			else		BitCounter <= BitCounter - 3'd1;
		end
		else
		begin
			//	Write logic
			s_DataBufer[WriteBuferCounter] <= i_WriteData;
			if (WriteBuferCounter >= BuferSize)		WriteBuferCounter <= 0;
			else									WriteBuferCounter <= WriteBuferCounter + 1;

			//	Read logic
			s_ReadData_Reg <= s_DataBufer[ReadBuferCounter];
			if (ReadBuferCounter >= BuferSize)		ReadBuferCounter <= 0;
			else									ReadBuferCounter <= ReadBuferCounter + 1;
		end
	end


	assign o_MISO = s_MISO;
	assign o_ReadData = s_ReadData_Reg;

endmodule


module SPI_Slave_DDCA
	#(parameter	DataWidth	= 8,
				BuferSize	= 8)
	(input logic			i_NRESET,

	input logic				i_SCK,

	input logic				i_MOSI,
	output logic			o_MISO,

	input logic				i_NCE,

	//
	input logic[(DataWidth - 1):0]	i_WriteData,
	output logic[(DataWidth - 1):0]	o_ReadData);

	logic[2:0]					s_BitCounter;
	logic						s_MISO;

	logic						s_NewByte;
	logic[3:0]					s_BuferCounter;
	logic[(DataWidth - 1):0]	s_ReadData_Reg;
	logic[(DataWidth - 1):0]	s_DataBufer[(BuferSize - 1):0];


	always_ff	@(negedge i_SCK, negedge i_NRESET)
	begin
		if (~i_NRESET)		s_BitCounter <= 3'b000;
		else if (~i_NCE)	s_BitCounter <= s_BitCounter + 3'd1;
	end

	always_ff	@(posedge s_NewByte, negedge i_NRESET)
	begin
		if (~i_NRESET)		s_BuferCounter <= 3'd0;
		else if (~i_NCE)	s_BuferCounter <= s_BuferCounter + 3'd1;
	end

	always_ff	@(posedge i_SCK)
	begin
		if (~i_NCE)
			s_DataBufer[s_BuferCounter] <= (s_BitCounter == 3'd0) ?	{i_WriteData[6:0], i_MOSI} : {s_DataBufer[s_BuferCounter][6:0], i_MOSI};
			//s_ReadData_Reg <= (s_BitCounter == 3'd0) ?	{i_WriteData[6:0], i_MOSI} : {s_ReadData_Reg[6:0], i_MOSI};
	end

	always_ff	@(negedge i_SCK)
	begin
		if (~i_NCE)		s_MISO <= s_ReadData_Reg[7];
	end


	assign s_ReadData_Reg = s_DataBufer[s_BuferCounter];

	assign s_NewByte	= (s_BitCounter == 3'd0) ?	1'b1 : 1'b0;

	assign o_MISO		= (s_BitCounter == 3'd0) ?	i_WriteData[7] : s_MISO;
	assign o_ReadData	= s_ReadData_Reg;

endmodule

