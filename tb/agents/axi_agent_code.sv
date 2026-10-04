//------------------------------------------------------------------------------
// AXI Read Interface
//------------------------------------------------------------------------------
/*interface axi_interface(input bit ACLK, ARESETn);
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
endinterface*/
class axi_sequence_item extends uvm_sequence_item;
  // ---------------- Correction 5 ----------------
  // Factory registration macro should not use quotes.
  `uvm_object_utils(axi_sequence_item)
  logic [31:0] start_addr;
  logic [2:0]  size;
  logic [7:0]  len;
  rand logic [31:0] data[];
  rand logic [2:0] delay;
  function new(string name="axi_sequence_item");
    super.new(name);
  endfunction
endclass
//--------------------------------------------
//AXI_SLAVE_DRIVER.
//--------------------------------------------
class axi_slave_driver extends uvm_driver #(axi_sequence_item);
  `uvm_component_utils(axi_slave_driver)
  function new(string name="axi_slave_driver",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  virtual axi_interface axi_if;
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual axi_interface)::get(this,"","axi_if",axi_if))
      `uvm_fatal("DRV","Could not get AXI Interface");
  endfunction
  virtual task run_phase(uvm_phase phase);
    axi_sequence_item rsp;
    axi_if.ARREADY <= 1'b1;
    axi_if.RVALID  <= 1'b0;
    axi_if.RLAST   <= 1'b0;
     `uvm_info(get_type_name(),"Driver started",UVM_LOW)
    forever begin
      @(posedge axi_if.ACLK);
      if(axi_if.ARVALID && axi_if.ARREADY) begin
        //------------------------------
        // Get transaction from sequence
        //------------------------------
        `uvm_info(get_type_name(),"Waiting for item",UVM_LOW)
        seq_item_port.get_next_item(req);
        //------------------------------
        // Capture DUT burst information
        //------------------------------
        $display("Time=%0t", $time);
        $display("ARVALID=%0b ARREADY=%0b", axi_if.ARVALID, axi_if.ARREADY);
        $display("ARADDR=%h", axi_if.ARADDR);
        $display("ARLEN=%h (%0d)", axi_if.ARLEN, axi_if.ARLEN);
        req.start_addr = axi_if.ARADDR;
        req.size       = axi_if.ARSIZE;
        req.len        = axi_if.ARLEN;
        axi_if.ARREADY <= 1'b0;
        //------------------------------
        // Allocate memory
        //------------------------------
        req.data = new[req.len+1];
        if(!std::randomize(req.data))
          `uvm_fatal("DRV","Randomization Failed");
        //------------------------------
        // Send Read Data
        //------------------------------
        for(int i=0;i<=req.len;i++) begin
          repeat(req.delay)
            @(posedge axi_if.ACLK);
          axi_if.RDATA  <= req.data[i];
          axi_if.RVALID <= 1'b1;
          axi_if.RLAST  <= (i==req.len);
          do begin
            //axi_if.RVALID<='0;
            @(posedge axi_if.ACLK);
          end
          while(!axi_if.RREADY);
          axi_if.RVALID<='0;
        end
        //------------------------------
        // Deassert signals
        //------------------------------
        axi_if.RVALID  <= 0;
        axi_if.RLAST   <= 0;
        axi_if.ARREADY <= 1;
        //------------------------------
        // Create response
        //------------------------------
        rsp = axi_sequence_item::type_id::create("rsp");
        rsp.set_id_info(req);
        rsp.start_addr = req.start_addr;
        rsp.size       = req.size;
        rsp.len        = req.len;
        rsp.data = new[req.data.size()];
        rsp.data = req.data;
        rsp.delay = req.delay;
        //------------------------------
        // Return transaction
        //------------------------------
        seq_item_port.item_done(rsp);
        `uvm_info(get_type_name(),"Received item",UVM_LOW)
      end
    end
  endtask
endclass
class axi_slave_monitor extends uvm_monitor;
  `uvm_component_utils(axi_slave_monitor)
  function new(string name="axi_slave_monitor",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  virtual axi_interface axi_if;
  uvm_analysis_port #(axi_sequence_item) ap;
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual axi_interface)::get(this,"","axi_if",axi_if))
      `uvm_fatal("MON","Could not get AXI interface");
    ap = new("ap",this);
  endfunction
  virtual task run_phase(uvm_phase phase);
    axi_sequence_item item;

    int beat_count;
    `uvm_info(get_type_name(),"Driver started",UVM_LOW)

    forever begin
      //---------------------------------------------------
      // Wait Address Handshake
      //---------------------------------------------------
      @(posedge axi_if.ACLK);
      if(axi_if.ARVALID && axi_if.ARREADY) begin
        item = axi_sequence_item::type_id::create("item");
        item.start_addr = axi_if.ARADDR;
        item.size       = axi_if.ARSIZE;
        item.len        = axi_if.ARLEN;
        if ($isunknown(item.len)) begin
    `uvm_fatal("MON",
        $sformatf("ARLEN contains X/Z! ARLEN=%b", item.len))
end
$display("ARLEN = %0d (0x%0h)", item.len, item.len);
        //---------------------------------------------------
        // Correction 1
        // Allocate dynamic array
        //---------------------------------------------------
        item.data = new[item.len+1];
        beat_count = 0;
        //---------------------------------------------------
        // Collect Read Burst
        //---------------------------------------------------
        forever begin
          @(posedge axi_if.ACLK);
          if(axi_if.RVALID && axi_if.RREADY) begin
            //---------------------------------------------------
            // Correction 2
            // Sample immediately
            //---------------------------------------------------
            $display("[%0t] Beat %0d  RLAST=%0b",
             $time, beat_count, axi_if.RLAST);
            item.data[beat_count] = axi_if.RDATA;
            beat_count++;
            //---------------------------------------------------
            // Correction 3
            // Exit only after LAST handshake
            //---------------------------------------------------
            if(axi_if.RLAST)begin
              $display("Saw RLAST");
              $display("RLAST received at time %0t", $time);
              break;
            end
          end
        end
        $display("Publishing AXI transaction");
$display("beats=%0d", item.data.size());
$display("Monitor_axi published");
        ap.write(item);
        //---------------------------------------------------
        // Transaction Complete
        //---------------------------------------------------
      end
    end
  endtask
endclass
class axi_sequencer extends uvm_sequencer #(axi_sequence_item);
  `uvm_component_utils(axi_sequencer)
  function new(string name="axi_sequencer",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
endclass

class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)
  function new(string name="axi_agent",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  axi_slave_driver drv;
  axi_slave_monitor mon;
  axi_sequencer seqr;
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(get_is_active()==UVM_ACTIVE) begin
      drv  = axi_slave_driver::type_id::create("drv",this);
      seqr = axi_sequencer::type_id::create("seqr",this);
    end
    mon = axi_slave_monitor::type_id::create("mon",this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active()==UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

