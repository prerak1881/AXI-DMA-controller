//---------------------------------------------------------------------------
// AXI-Lite Interface
//---------------------------------------------------------------------------
/*interface axi_lite_interface(input logic ACLK, APRESET);
  logic [31:0] AWADDR, ARADDR;
  logic [31:0] WDATA, RDATA;
  logic AWREADY, AWVALID;
  logic ARREADY, ARVALID;
  logic WREADY, WVALID;
  logic RREADY, RVALID;
  logic BREADY, BVALID;
  logic [1:0] BRESP, RRESP;
endinterface*/
//---------------------------------------------------------------------------
// Sequence Item
//---------------------------------------------------------------------------
class axi_lite_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(axi_lite_sequence_item)
  rand logic [31:0] addr;
  rand logic [31:0] data;
  rand logic write_req;
  // FIX-1 : Response should be 2 bits
  logic [1:0] resp;
  function new(string name="axi_lite_sequence_item");
    super.new(name);
  endfunction
endclass
//---------------------------------------------------------------------------
// Driver
//---------------------------------------------------------------------------
class axil_master_driver extends uvm_driver #(axi_lite_sequence_item);
  `uvm_component_utils(axil_master_driver)
  virtual axi_lite_interface axil_if;
  function new(string name="axil_master_driver",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  //-------------------------------------------------------
  // Build Phase
  //-------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_lite_interface)::get(
        this,"","axil_if",axil_if))
      `uvm_fatal("DRV","Could not get virtual interface")
  endfunction
  //-------------------------------------------------------
  // Run Phase
  //-------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // Initialize outputs
    axil_if.AWVALID <= 0;
    axil_if.WVALID  <= 0;
    axil_if.ARVALID <= 0;

    axil_if.BREADY  <= 0;
    axil_if.RREADY  <= 0;
    // Requested Fix #5
    axil_if.AWADDR  <= 0;
    axil_if.ARADDR  <= 0;
    axil_if.WDATA   <= 0;
    `uvm_info(get_type_name(),
            "Driver started",
            UVM_LOW)
    forever begin
       `uvm_info(get_type_name(),
              "Waiting for item",
              UVM_LOW)
      seq_item_port.get_next_item(req);
      // Requested Fix #15
      fork
        begin
          if(req.write_req)
            write_task(req);
          else
            read_task(req);
        end
        begin
          @(negedge axil_if.APRESET);
          `uvm_error("DRV","Reset asserted during transaction")
          axil_if.AWVALID <= 0;
          axil_if.WVALID  <= 0;
          axil_if.ARVALID <= 0;

          axil_if.BREADY  <= 0;
          axil_if.RREADY  <= 0;
        end
      join_any
      disable fork;
      seq_item_port.item_done();
      `uvm_info(get_type_name(),
              "Received item",
              UVM_LOW)
    end
  endtask
  //-------------------------------------------------------
  // WRITE TASK
  //-------------------------------------------------------
  task write_task(axi_lite_sequence_item item);
    @(posedge axil_if.ACLK);
    axil_if.AWADDR  <= item.addr;
    axil_if.AWVALID <= 1;
    axil_if.WDATA   <= item.data;
    axil_if.WVALID  <= 1;
    axil_if.BREADY  <= 1;
    fork
      begin
        // Requested Fix #6
        do
          @(posedge axil_if.ACLK);
        while(!axil_if.AWREADY);
        axil_if.AWVALID <= 0;
      end
      begin
        // Requested Fix #6
        do
          @(posedge axil_if.ACLK);
        while(!axil_if.WREADY);
        axil_if.WVALID <= 0;
      end
    join
    while(!axil_if.BVALID)
      @(posedge axil_if.ACLK);
    item.resp = axil_if.BRESP;
    @(posedge axil_if.ACLK);
    axil_if.BREADY <= 0;
  endtask
  //-------------------------------------------------------
  // READ TASK
  //-------------------------------------------------------
  task read_task(axi_lite_sequence_item item);
    @(posedge axil_if.ACLK);
    axil_if.ARADDR  <= item.addr;
    axil_if.ARVALID <= 1;
    axil_if.RREADY  <= 1;
    while(!axil_if.ARREADY)
     @(posedge axil_if.ACLK);
    axil_if.ARVALID <= 0;
    while(!axil_if.RVALID)
      @(posedge axil_if.ACLK);
    // Requested Fix #1
    // Slave drives RDATA, driver samples it.
    @(posedge axil_if.ACLK);
    item.data = axil_if.RDATA;
    item.resp = axil_if.RRESP;
    axil_if.RREADY <= 0;
  endtask
endclass
//---------------------------------------------------------------------------
// AXI-Lite Monitor
//---------------------------------------------------------------------------
class axil_master_monitor extends uvm_monitor;
  `uvm_component_utils(axil_master_monitor)
  virtual axi_lite_interface axil_if;
  uvm_analysis_port #(axi_lite_sequence_item) ap;
  function new(string name="axil_master_monitor",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  //-------------------------------------------------------
  // Build Phase
  //-------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_lite_interface)::get(
        this,"","axil_if",axil_if))
      `uvm_fatal("MON","Could not get virtual interface")
    ap = new("ap",this);
  endfunction
  //-------------------------------------------------------
  // Run Phase
  //-------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    fork
      write_data_req();
      read_data_req();
    join

  endtask
  //-------------------------------------------------------
  // WRITE MONITOR
  //-------------------------------------------------------
  task write_data_req();
    axi_lite_sequence_item item;
    forever begin
      // ---------- Fix #7 ----------
      @(posedge axil_if.ACLK);
      if(axil_if.AWVALID && axil_if.AWREADY) begin
        `uvm_info("MON","AW handshake",UVM_LOW)

        // ---------- Fix #2 ----------
        item = axi_lite_sequence_item::type_id::create("item");
        item.write_req = 1;
        item.addr      = axil_if.AWADDR;
        while(!(axil_if.WVALID && axil_if.WREADY))
          @(posedge axil_if.ACLK);
        `uvm_info("MON","W handshake",UVM_LOW)
        item.data = axil_if.WDATA;
        while(!(axil_if.BVALID && axil_if.BREADY))
          @(posedge axil_if.ACLK);
        `uvm_info("MON","B handshake",UVM_LOW)
        item.resp = axil_if.BRESP;
        ap.write(item);
        `uvm_info("MON","Transaction published",UVM_LOW)
      end
    end
  endtask
  //-------------------------------------------------------
  // READ MONITOR
  //-------------------------------------------------------
  task read_data_req();
    axi_lite_sequence_item item;
    forever begin
      // ---------- Fix #7 ----------
      @(posedge axil_if.ACLK);
      if(axil_if.ARVALID && axil_if.ARREADY) begin
        // ---------- Fix #2 ----------
        item = axi_lite_sequence_item::type_id::create("item");
        item.write_req = 0;
        item.addr      = axil_if.ARADDR;
        // ---------- Fix #3 ----------
        while(!(axil_if.RVALID && axil_if.RREADY))
          @(posedge axil_if.ACLK);
        item.data = axil_if.RDATA;
        item.resp = axil_if.RRESP;
        $display("Monitor_lite published");
        ap.write(item);
      end
    end
  endtask
endclass
//---------------------------------------------------------------------------
// AXI-Lite Agent
//---------------------------------------------------------------------------
class axil_agent extends uvm_agent;
  `uvm_component_utils(axil_agent)
  uvm_sequencer #(axi_lite_sequence_item) sqr;
  axil_master_driver  drv;
  axil_master_monitor mon;
  function new(string name="axil_agent",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  //-------------------------------------------------------
  // Build Phase
  //-------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = axil_master_monitor::type_id::create("mon",this);
    if(get_is_active()==UVM_ACTIVE) begin
      sqr = uvm_sequencer#(axi_lite_sequence_item)::type_id::create("sqr",this);
      drv = axil_master_driver::type_id::create("drv",this);
    end
  endfunction
  //-------------------------------------------------------
  // Connect Phase
  //-------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active()==UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);

  endfunction
endclass
