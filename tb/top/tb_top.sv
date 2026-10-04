module tb_top();
import uvm_pkg::*;
import dma_pkg::*;
`include "uvm_macros.svh"

logic ACLK;
logic APRESETn;

initial begin
ACLK = 0;
forever #5 ACLK = ~ACLK;   // 100 MHz
end

initial begin
APRESETn = 0;
#50;
APRESETn = 1;
end

axi_lite_interface   axil_if(ACLK, APRESETn);
axi_interface        axi_if(ACLK, APRESETn);
axi_stream_interface axis_if(ACLK, APRESETn);
register   reg_if();

top dut(.reg_if(reg_if),
.axil_if(axil_if),
.axis_if(axis_if),
.axi_if(axi_if),
.ACLK(ACLK),
.APRESETn(APRESETn));

initial begin
uvm_config_db#(virtual axi_lite_interface)::set(null,"*","axil_if",axil_if);
uvm_config_db#(virtual axi_interface)::set(null,"*","axi_if",axi_if);
uvm_config_db#(virtual axi_stream_interface)::set(null,"*","axis_if",axis_if);
run_test("dma_test");
end
endmodule
