class dma_env extends uvm_env;
  `uvm_component_utils(dma_env)
  function new(string name="dma_env", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  axil_agent a_l;
  axi_agent  a;
  axis_agent a_s;
  dma_scoreboard sb;
  reg_block reg_model;
  axi_lite_adapter adapt;
  uvm_reg_predictor #(axi_lite_sequence_item) pred;
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_l = axil_agent::type_id::create("a_l", this);
    a   = axi_agent::type_id::create("a", this);
    a_s = axis_agent::type_id::create("a_s", this);
    sb = dma_scoreboard::type_id::create("sb", this);
    reg_model = reg_block::type_id::create("reg_model", this);
    reg_model.build();
    reg_model.lock_model();
    reg_model.reset();
    adapt = axi_lite_adapter::type_id::create("adapt", this);
    pred = uvm_reg_predictor#(axi_lite_sequence_item)::type_id::create("pred", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Scoreboard connections
    a_l.mon.ap.connect(sb.imp_lite);
    a.mon.ap.connect(sb.imp_mem);
    a_s.mon.ap.connect(sb.imp_stream);
    // RAL connections
    reg_model.default_map.set_sequencer(a_l.sqr, adapt);
    a_l.mon.ap.connect(pred.bus_in);
    pred.map = reg_model.default_map;
    pred.adapter     = adapt;
  endfunction
endclass