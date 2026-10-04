
// ---------------------------------------------------------------------------
// AXI Stream Sequence Item
// ---------------------------------------------------------------------------
class axi_stream_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(axi_stream_sequence_item)
  // Random delay to generate backpressure
  rand logic [2:0] delay;
  // Data observed during handshake
  logic [31:0] tdata;
  logic        tlast;
  logic [3:0]  tkeep;
  function new(string name="axi_stream_sequence_item");
    super.new(name);
  endfunction
endclass
// ---------------------------------------------------------------------------
// AXI Stream Slave Driver
// ---------------------------------------------------------------------------

class axis_slave_driver extends uvm_driver #(axi_stream_sequence_item);
  `uvm_component_utils(axis_slave_driver)
  virtual axi_stream_interface axis_if;
  function new(string name="axis_slave_driver",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_stream_interface)::get
       (this,"*","axis_if",axis_if)) begin
      `uvm_fatal("DRV",
                 "Could not get AXI Stream interface from config db")
    end
  endfunction
  int i=0;
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    axis_if.TREADY = 1'b0;
     `uvm_info(get_type_name(),
            "Driver started",
            UVM_LOW)
    forever begin
      // Initially slave is not ready
      //axis_if.TREADY = 1'b0;
      // Get backpressure requirement from sequence
       $display("[%0t] Before get_next_item",$time);
      seq_item_port.get_next_item(req);
      // Introduce random delay
       $display("[%0t] Got item",$time);
      repeat(req.delay) begin
        @(posedge axis_if.ACLK);
      end
      // Slave ready to accept data
      axis_if.TREADY = 1'b1;
      $display("[%0t] Assert TREADY", $time);
      // Wait until AXI Stream handshake happens
      while(!(axis_if.TVALID && axis_if.TREADY)) begin
        @(posedge axis_if.ACLK);
        /*$display("[%0t] Driver sees TVALID=%0b TREADY=%0b",
             $time,
             axis_if.TVALID,
             axis_if.TREADY);*/
      end
      $display("[%0t] Handshake, count=%d",$time,i++);
      seq_item_port.item_done();
      $display("[%0t] Item done",$time);
    end
  endtask
endclass
// ---------------------------------------------------------------------------
// AXI Stream Slave Monitor
// ---------------------------------------------------------------------------
class axis_slave_monitor extends uvm_monitor;
  `uvm_component_utils(axis_slave_monitor)
  virtual axi_stream_interface axis_if;
  uvm_analysis_port #(axi_stream_sequence_item) ap;
  function new(string name="axis_slave_monitor",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_stream_interface)::get
       (this,"*","axis_if",axis_if)) begin
      `uvm_fatal("MON",
                 "Could not get AXI Stream interface from config db")
    end
    ap = new("ap",this);
  endfunction
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      @(posedge axis_if.ACLK);
      // Capture only valid AXI Stream transfers
      if(axis_if.TVALID && axis_if.TREADY) begin
        axi_stream_sequence_item item;
        item = axi_stream_sequence_item::type_id::create
               ("item",this);
        item.tdata = axis_if.TDATA;
        item.tkeep = axis_if.TKEEP;
        item.tlast = axis_if.TLAST;
        $display("Monitor_stream published");
        ap.write(item);
      end
    end
  endtask
endclass
// ---------------------------------------------------------------------------
// AXI Stream Agent
// ---------------------------------------------------------------------------
class axis_agent extends uvm_agent;
  `uvm_component_utils(axis_agent)
  uvm_sequencer #(axi_stream_sequence_item) seqr;
  axis_slave_driver   drv;
  axis_slave_monitor  mon;
  function new(string name="axis_agent",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Monitor is always present
    mon = axis_slave_monitor::type_id::create("mon",this);
    // Driver and sequencer only for active agent
    if(get_is_active()==UVM_ACTIVE) begin
      seqr = uvm_sequencer#(axi_stream_sequence_item)::type_id::create
             ("seqr",this);
      drv = axis_slave_driver::type_id::create
            ("drv",this);
    end
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active()==UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass