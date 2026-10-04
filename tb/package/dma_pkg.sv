package dma_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
//agents
`include "../agents/axi_agent_code.sv"
`include "../agents/axil_agent_code.sv"
`include "../agents/axis_agent.sv"
//RAL
`include "../ral/RAL_code.sv"
//scoreboard
`include "../scoreboard/scoreboard.sv"
//environment
`include "../env/dma_env.sv"
//sequences
`include "../sequences/dma_confg_seq.sv"
`include "../sequences/normal_mem_seq.sv"
`include "../sequences/stream_always_ready_seq.sv"
//tests
`include "../tests/dma_test.sv"
endpackage
