// ---------------------------------------------------------------------------
// AXI Stream Interface
// ---------------------------------------------------------------------------
interface axi_stream_interface 
(input logic ACLK,input logic APRESETn);
  logic [31:0] TDATA;
  logic        TVALID;
  logic        TREADY;
  logic        TLAST;
  logic [3:0]  TKEEP;
endinterface