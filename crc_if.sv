//======================================================================
//
// simple CRC block interface. 
// ---------------------------
//
//======================================================================

  interface crc_if();
  //----------------------------------------------------------------
  // Register , wire & variable declarations.
  //----------------------------------------------------------------			       
  logic    		clk;       //  clock signal
  logic    		rst;       // reset signal  
  logic [31:0] 	addr;      // device address
  logic [31:0] 	data_wr;   // write data
  logic        	rw;        // read = 0 write = 1
  logic        	sel;       // device is selected
  logic [31:0] 	data_rd;   // read data

  //----------------------------------------------------------------
  // clocking block declaration
  //----------------------------------------------------------------  
  clocking cb @(posedge(clk));
	input addr,data_wr,rw,Sel;
	output data_rd;
  endclocking : cb

  //----------------------------------------------------------------
  // modport declaration.
  //----------------------------------------------------------------
  modport m(input clk, input rst, input addr, input rw, input sel,
	input data_wr, output data_rd);

  endinterface : crc_if //  crc_if