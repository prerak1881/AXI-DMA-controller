interface axi_interface(input bit ACLK, ARESETn);
  // ---------------- Correction 1 ----------------
  // AXI address bus is 32 bits, not 1 bit.
  logic [31:0] ARADDR;
  logic ARVALID;
  // ---------------- Correction 2 ----------------
  // ARLEN is 8 bits according to AXI4 specification.
  logic [7:0] ARLEN;
  // ---------------- Correction 3 ----------------
  // ARSIZE is 3 bits according to AXI4 specification.
  logic [2:0] ARSIZE;
  logic ARREADY;
  // ---------------- Correction 4 ----------------
  // RDATA should be a 32-bit data bus.
  logic [31:0] RDATA;
  logic RLAST;
  logic RVALID;
  logic RREADY;
endinterface
