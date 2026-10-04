class dma_test extends uvm_test;
`uvm_component_utils(dma_test)
function new(string name="dma_test",uvm_component parent=null);
super.new(name,parent);
endfunction

dma_env env;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
env=dma_env::type_id::create("env", this);
endfunction

function void end_of_elaboration_phase(uvm_phase phase);
super.end_of_elaboration_phase(phase);
uvm_top.print_topology();
endfunction

virtual task run_phase(uvm_phase phase);

dma_reg_confg d_c_s;
stream_always_ready_seq s_a_r_s;
mem_normal_seq n_m_s;

super.run_phase(phase);

d_c_s=dma_reg_confg::type_id::create("d_c_s");
s_a_r_s=stream_always_ready_seq::type_id::create("s_a_r_s");
n_m_s=mem_normal_seq::type_id::create("n_m_s");

phase.raise_objection(this);
d_c_s.reg_model=env.reg_model;
d_c_s.start(env.a_l.sqr);
s_a_r_s.reg_model=env.reg_model;
n_m_s.reg_model=env.reg_model;

fork
     n_m_s.start(env.a.seqr);
    s_a_r_s.start(env.a_s.seqr);
join
phase.drop_objection(this);
endtask
endclass
