//======================================================================
//
// CRC block code for NXP MKW2xD_CRC
// ---------------------------------
//
//======================================================================

  module crc (crc_if m);

  //----------------------------------------------------------------
  // Register , wire & variable declarations.
  //----------------------------------------------------------------			     
  reg  	[31:0] 	CRC_DATA;           // reset value = FFFF_FFFF   register address = 4003_2000 hex
  reg  	[31:0] 	CRC_GPOLY;          // reset value = 0000_1021   register address = 4003_2004 hex
  reg  	[31:0] 	CRC_CTRL;           // reset value = 0000_0000   register address = 4003_2008 hex
  reg   [31:0] 	SEED;               // reset value = 0000_0000 STORES SEED VALUE
  reg   [31:0] 	SEED_T;             // reset value = 0000_0000 STORES TRANSPOSED SEED VALUE    
  reg  	[31:0] 	DATA;               // reset value = 0000_0000 STORES DATA VALUE
  reg   [31:0] 	DATA_1;             // reset value = 0000_0000 STORES DATA VALUE USED BY CRC ENGINE     
  reg   [31:0] 	DATA_T;             // reset value = 0000_0000 STORES TRANSPOSED DATA VALUE  
  reg   [31:0] 	CRC;                // reset value = 0000_0000 STORES SEED VALUE USED BY CRC ENGINE
  reg   [31:0] 	CRC_out;            // reset value = 0000_0000 STORES A COPY OF FINAL CRC VALUE RESULT
  reg   [31:0] 	CRC_N;              // reset value = 0000_0000 STORES INVERTED CRC VALUE (FROM RESULT OF CRC ENGINE)
  reg   [31:0] 	CRC_T;              // reset value = 0000_0000 STORES TRANSPOSED CRC VALUE (FROM RESULT OF CRC_N     
  wire 	[1:0] 	TOT;                // CRC_CTRL : TOT   Type Of Transpose For Writes
  wire 	[1:0] 	TOTR;               // CRC_CTRL : TOTR  Type Of Transpose For Read
  wire 			FXOR;				// CRC_CTRL : FXOR  Complement Read Of CRC Data Register
  wire 			WAS;                // CRC_CTRL : WAS   Write CRC Data Register as Seed       WAS = 1 : SEED       WAS = 0 : DATA
  wire 			TCRC;               // CRC_CTRL : TCRC  Width of CRC protocol                       
  integer 		i;

  //----------------------------------------------------------------
  // Concurrent connectivity for output ports.
  //----------------------------------------------------------------
  assign TOT  =  CRC_CTRL[31:30];
  assign TOTR =  CRC_CTRL[29:28];
  assign FXOR =  CRC_CTRL[26];
  assign WAS  =  CRC_CTRL[25];
  assign TCRC =  CRC_CTRL[24];

  //----------------------------------------------------------------
  // Logic for controlled inversion on CRC read (TCRC) 
  //----------------------------------------------------------------
  always@ (*)  
  begin : crc_inv
	if (m.rst)     
        CRC_N = 32'h0000_0000;
    else
        if (TCRC)
           if  (FXOR) CRC_N = ~CRC_out; else CRC_N = CRC_out;
        else 
           if  (FXOR)         
                case (TOTR)
                    2'b00    : CRC_N = CRC_out ^ 32'h0000_FFFF;
                    2'b01    : CRC_N = CRC_out ^ 32'h0000_FFFF;
                    2'b10    : CRC_N = CRC_out ^ 32'hFFFF_0000;
                    2'b11    : CRC_N = CRC_out ^ 32'hFFFF_0000;                    
                    default  : CRC_N = CRC_out; 
                endcase
           else  CRC_N = CRC_out; 
  end //  crc_inv
  
  //----------------------------------------------------------------
  // Logic for writing to registers 
  //----------------------------------------------------------------  
  always@ (posedge m.clk)  
  begin : crc_reg_wr
            DATA        = ((m.rst == 1) ? 32'hFFFF_FFFF : ((m.Sel == 1 && m.RW == 1 && WAS == 0)  ? DATA_T  : (DATA)));
            SEED        = ((m.rst == 1) ? 32'hFFFF_FFFF : ((m.Sel == 1 && m.addr == 32'h4003_2000 && m.RW == 1 && WAS == 1)  ? SEED_T  : (CRC)));  // ORIGINAL VALUE IS TRANSPOSED ONCE & LATCHED VALUE IS CRC VALUE
            CRC_DATA    = ((m.rst == 1) ? 32'hFFFF_FFFF : ((m.Sel == 1 && m.addr == 32'h4003_2000 && m.RW == 1)  ? m.data_wr  : (CRC_DATA)));
            CRC_GPOLY   = ((m.rst == 1) ? 32'h0000_1021 : ((m.Sel == 1 && m.addr == 32'h4003_2004 && m.RW == 1)  ? m.data_wr  : (CRC_GPOLY)));
            CRC_CTRL    = ((m.rst == 1) ? 32'h0000_0000 : ((m.Sel == 1 && m.addr == 32'h4003_2008 && m.RW == 1)  ? m.data_wr  : (CRC_CTRL)));
  end // crc_reg_wr
  
  //----------------------------------------------------------------
  // Logic for reading registers 
  //----------------------------------------------------------------  
  always@ (negedge m.clk)  
  begin : crc_reg_rd
    if (m.rst)     
        m.data_rd = 32'h0000_0000;
    else
        begin
        case (m.addr)
            32'h4003_2000   : if (m.Sel == 1 && m.RW == 0) m.data_rd = CRC_T;  // Using CRC_out ONLY when reading , CRC is used elsewhere within logic ****DO NOT TOUCH THIS****
            32'h4003_2004   : if (m.Sel == 1 && m.RW == 0) m.data_rd = CRC_GPOLY;                           
            32'h4003_2008   : if (m.Sel == 1 && m.RW == 0) m.data_rd = CRC_CTRL;
            default         :     m.data_rd = CRC_CTRL;
        endcase
        end
  end // crc_reg_rd

  //----------------------------------------------------------------  
  // Logic for Transpose on SEED write (TOT) 
  //----------------------------------------------------------------  
  always@ (negedge m.clk)                 
  begin : crc_seed_transpose_tot
	if (m.rst == 1)     
        begin
            SEED_T <= 32'hFFFF_FFFF;
        end
    else
        if (m.Sel == 1 && m.addr == 32'h4003_2000 && m.RW == 1 && WAS == 1)
        begin
        case (TOT)
            2'b00   :   
                            SEED_T <= m.data_wr;
            2'b01   :   
                            SEED_T <=                                                                                                                           
                                    {m.data_wr[24],m.data_wr[25],m.data_wr[26],m.data_wr[27],m.data_wr[28],m.data_wr[29],m.data_wr[30],m.data_wr[31],
                                    m.data_wr[16],m.data_wr[17],m.data_wr[18],m.data_wr[19],m.data_wr[20],m.data_wr[21],m.data_wr[22],m.data_wr[23],
                                    m.data_wr[8],m.data_wr[9],m.data_wr[10],m.data_wr[11],m.data_wr[12],m.data_wr[13],m.data_wr[14],m.data_wr[15],
                                    m.data_wr[0],m.data_wr[1],m.data_wr[2],m.data_wr[3],m.data_wr[4],m.data_wr[5],m.data_wr[6],m.data_wr[7]};
            2'b10   :   
                            SEED_T <=
                                    {m.data_wr[0],m.data_wr[1],m.data_wr[2],m.data_wr[3],m.data_wr[4],m.data_wr[5],m.data_wr[6],m.data_wr[7],
                                    m.data_wr[8],m.data_wr[9],m.data_wr[10],m.data_wr[11],m.data_wr[12],m.data_wr[13],m.data_wr[14],m.data_wr[15],
                                    m.data_wr[16],m.data_wr[17],m.data_wr[18],m.data_wr[19],m.data_wr[20],m.data_wr[21],m.data_wr[22],m.data_wr[23],
                                    m.data_wr[24],m.data_wr[25],m.data_wr[26],m.data_wr[27],m.data_wr[28],m.data_wr[29],m.data_wr[30],m.data_wr[31]};
            2'b11   :   
                            SEED_T <=                                         
                                    {m.data_wr[7],m.data_wr[6],m.data_wr[5],m.data_wr[4],m.data_wr[3],m.data_wr[2],m.data_wr[1],m.data_wr[0],
                                    m.data_wr[15],m.data_wr[14],m.data_wr[13],m.data_wr[12],m.data_wr[11],m.data_wr[10],m.data_wr[9],m.data_wr[8],
                                    m.data_wr[23],m.data_wr[22],m.data_wr[21],m.data_wr[20],m.data_wr[19],m.data_wr[18],m.data_wr[17],m.data_wr[16],
                                    m.data_wr[31],m.data_wr[30],m.data_wr[29],m.data_wr[28],m.data_wr[27],m.data_wr[26],m.data_wr[25],m.data_wr[24]};
            default :   begin
                            SEED_T <= m.data_wr;  
                        end
        endcase
        end
  end // crc_seed_transpose_tot

  //----------------------------------------------------------------  
  // Logic for Transpose on CRC read (TOTR) 
  //----------------------------------------------------------------  
  always@ (*)                 
  begin : crc_seed_transpose_totr
    if (m.rst == 1)     
       CRC_T = 32'hFFFF_FFFF;
    else
        begin
        case (TOTR)
            2'b00   : CRC_T =       CRC_N;
            
            2'b01   : CRC_T =       {CRC_N[24],CRC_N[25],CRC_N[26],CRC_N[27],CRC_N[28],CRC_N[29],CRC_N[30],CRC_N[31],
                                     CRC_N[16],CRC_N[17],CRC_N[18],CRC_N[19],CRC_N[20],CRC_N[21],CRC_N[22],CRC_N[23],
                                     CRC_N[8] ,CRC_N[9] ,CRC_N[10],CRC_N[11],CRC_N[12],CRC_N[13],CRC_N[14],CRC_N[15],
                                     CRC_N[0] ,CRC_N[1] ,CRC_N[2] ,CRC_N[3] ,CRC_N[4] ,CRC_N[5] ,CRC_N[6] ,CRC_N[7]};
            
            2'b10   : CRC_T =       {CRC_N[0],CRC_N[1],CRC_N[2],CRC_N[3],CRC_N[4],CRC_N[5],CRC_N[6],CRC_N[7],
                                    CRC_N[8],CRC_N[9],CRC_N[10],CRC_N[11],CRC_N[12],CRC_N[13],CRC_N[14],CRC_N[15],
                                    CRC_N[16],CRC_N[17],CRC_N[18],CRC_N[19],CRC_N[20],CRC_N[21],CRC_N[22],CRC_N[23],
                                    CRC_N[24],CRC_N[25],CRC_N[26],CRC_N[27],CRC_N[28],CRC_N[29],CRC_N[30],CRC_N[31]};

            2'b11   : CRC_T =       {CRC_N[7],CRC_N[6],CRC_N[5],CRC_N[4],CRC_N[3],CRC_N[2],CRC_N[1],CRC_N[0],
                                    CRC_N[15],CRC_N[14],CRC_N[13],CRC_N[12],CRC_N[11],CRC_N[10],CRC_N[9],CRC_N[8],
                                    CRC_N[23],CRC_N[22],CRC_N[21],CRC_N[20],CRC_N[19],CRC_N[18],CRC_N[17],CRC_N[16],
                                    CRC_N[31],CRC_N[30],CRC_N[29],CRC_N[28],CRC_N[27],CRC_N[26],CRC_N[25],CRC_N[24]};                            
            default : CRC_T = CRC_N;  
        endcase
        end
  end // crc_seed_transpose_totr

  //----------------------------------------------------------------  
  // Logic for Transpose on DATA write (TOT) 
  //----------------------------------------------------------------  
  always@ (negedge m.clk)                 
  begin : crc_data_transpose_tot
    if (m.rst == 1)     
       DATA_T = 32'hFFFF_FFFF;
    else
        if (m.Sel == 1 && m.addr == 32'h4003_2000 && m.RW == 1 && WAS == 0)    
        begin
        case (TOT)
            2'b00   : DATA_T =      m.data_wr;

            2'b01   : DATA_T =      
                                    {m.data_wr[24],m.data_wr[25],m.data_wr[26],m.data_wr[27],m.data_wr[28],m.data_wr[29],m.data_wr[30],m.data_wr[31],
                                    m.data_wr[16],m.data_wr[17],m.data_wr[18],m.data_wr[19],m.data_wr[20],m.data_wr[21],m.data_wr[22],m.data_wr[23],
                                    m.data_wr[8],m.data_wr[9],m.data_wr[10],m.data_wr[11],m.data_wr[12],m.data_wr[13],m.data_wr[14],m.data_wr[15],
                                    m.data_wr[0],m.data_wr[1],m.data_wr[2],m.data_wr[3],m.data_wr[4],m.data_wr[5],m.data_wr[6],m.data_wr[7]};
            2'b10   : DATA_T =      
                                    {m.data_wr[0],m.data_wr[1],m.data_wr[2],m.data_wr[3],m.data_wr[4],m.data_wr[5],m.data_wr[6],m.data_wr[7],
                                    m.data_wr[8],m.data_wr[9],m.data_wr[10],m.data_wr[11],m.data_wr[12],m.data_wr[13],m.data_wr[14],m.data_wr[15],
                                    m.data_wr[16],m.data_wr[17],m.data_wr[18],m.data_wr[19],m.data_wr[20],m.data_wr[21],m.data_wr[22],m.data_wr[23],
                                    m.data_wr[24],m.data_wr[25],m.data_wr[26],m.data_wr[27],m.data_wr[28],m.data_wr[29],m.data_wr[30],m.data_wr[31]};

            2'b11   : DATA_T =      
                                    {m.data_wr[7],m.data_wr[6],m.data_wr[5],m.data_wr[4],m.data_wr[3],m.data_wr[2],m.data_wr[1],m.data_wr[0],
                                    m.data_wr[15],m.data_wr[14],m.data_wr[13],m.data_wr[12],m.data_wr[11],m.data_wr[10],m.data_wr[9],m.data_wr[8],
                                    m.data_wr[23],m.data_wr[22],m.data_wr[21],m.data_wr[20],m.data_wr[19],m.data_wr[18],m.data_wr[17],m.data_wr[16],
                                    m.data_wr[31],m.data_wr[30],m.data_wr[29],m.data_wr[28],m.data_wr[27],m.data_wr[26],m.data_wr[25],m.data_wr[24]};

            default : DATA_T =      m.data_wr;  

        endcase
        end
  end // crc_data_transpose_tot

  //----------------------------------------------------------------  
  // Logic for generating CRC 
  //----------------------------------------------------------------  
  always@( posedge m.clk or posedge m.rst )
  begin : core_crc_logic
        if (m.rst == 1)
        begin
            CRC         = 32'hFFFF_FFFF;
            CRC_out     = 32'hFFFF_FFFF;
            DATA_1      = 32'hFFFF_FFFF;
        end  
        else
            begin
                CRC = SEED;               // copying once before computation, doing this to avoid multiple drivers issue during synthesis
                DATA_1 = DATA;            // copying once before computation, doing this to avoid multiple drivers issue during synthesis                
            if (m.addr == 32'h4003_2000 && m.Sel == 1 && m.RW == 1 && WAS == 0 && TCRC == 1)   // WAS is 0 & DATA is written and 32 bit CRC mode
                                    begin
                                        for(i=0; i<=31; i = i+1)
                                        begin
                                                    if (CRC[31]) begin  
                                                                        CRC = ({CRC[30:0],DATA_1[31-i]})^CRC_GPOLY;
                                                                        CRC_out = CRC;
                                                                 end                                                                 
                                                    else         begin
                                                                        CRC = {CRC[30:0],DATA_1[31-i]};
																		CRC_out = CRC;
																 end
                                        end
                                    end

            else if (m.addr == 32'h4003_2000 && m.Sel == 1 && m.RW == 1 && WAS == 0 && TCRC == 0)   // WAS is 0 & DATA is written and 16 bit CRC mode
                                    begin
                                        for(i=0; i<=31; i = i+1)
                                        begin
                                                    if (CRC[15]) begin  
                                                                        CRC = ({CRC[14:0],DATA_1[31-i]})^CRC_GPOLY[15:0];
                                                                        CRC_out = CRC;                                                                        
                                                                 end
                                                                 
                                                    else        begin
                                                                        CRC = {CRC[14:0],DATA_1[31-i]};
																		CRC_out = CRC;
																end
                                        end
                                    end
                                   
            end                

  end // core_crc_logic

  endmodule //  crc
