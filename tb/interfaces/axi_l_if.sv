//---------------------------------------------------------------------------
// AXI-Lite Interface
//---------------------------------------------------------------------------
interface axi_lite_interface(input logic ACLK, APRESET);
  logic [31:0] AWADDR, ARADDR;
  logic [31:0] WDATA, RDATA;
  logic AWREADY, AWVALID;
  logic ARREADY, ARVALID;
  logic WREADY, WVALID;
  logic RREADY, RVALID;
  logic BREADY, BVALID;
  logic [1:0] BRESP, RRESP;
endinterface