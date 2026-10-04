class dma_reg_confg extends uvm_sequence #(axi_lite_sequence_item);
  `uvm_object_utils(dma_reg_confg)
  function new(string name="dma_reg_confg");
    super.new(name);
  endfunction
  uvm_status_e status;
  reg_block reg_model;
  // Local variables to randomize
  bit [31:0] src_addr;
  bit [31:0] dma_length;
  virtual task body();
  `uvm_info(get_type_name(),
          "Sequence started",
          UVM_LOW)
    // ---------------- Source Address ----------------
    if(!std::randomize(src_addr) with {
      src_addr[1:0] == 2'b00;
    }) begin
      `uvm_fatal("RAND_FAILED","Source address randomization failed")
    end
    `uvm_info(get_type_name(),
            "Before start_item_sa",
            UVM_LOW)
    reg_model.source_addr_reg_rm.source_addr.set(src_addr);
    reg_model.source_addr_reg_rm.update(status);
    if(status != UVM_IS_OK) begin
      `uvm_fatal("UPDATE_FAILED","Source address register update failed")
    end
    `uvm_info(get_type_name(),
            "After start_item_sa",
            UVM_LOW)
    reg_model.source_addr_reg_rm.mirror(status, UVM_CHECK);
    // ---------------- DMA Length ----------------
    `uvm_info(get_type_name(),
            "Before start_item_len",
            UVM_LOW)
    if(!std::randomize(dma_length) with {
      dma_length inside {[1:10000]};
    }) begin
      `uvm_fatal("RAND_FAILED","Length randomization failed")
    end
    reg_model.length_reg_rm.length.set(dma_length);
    reg_model.length_reg_rm.update(status);
    if(status != UVM_IS_OK) begin
      `uvm_fatal("UPDATE_FAILED","Length register update failed")
    end
    `uvm_info(get_type_name(),
            "After finish_item_la",
            UVM_LOW)
    reg_model.length_reg_rm.mirror(status, UVM_CHECK);
    // Configure control register
    `uvm_info(get_type_name(),
            "Before start_item_control",
            UVM_LOW)
    reg_model.control_reg_rm.write(status, 32'h0000_1001);
    if(status != UVM_IS_OK) begin
      `uvm_fatal("WRITE_FAILED","control_reg write failed")
    end
    reg_model.control_reg_rm.mirror(status, UVM_CHECK);
    `uvm_info(get_type_name(),
            "After start_item_control",
            UVM_LOW)
  endtask
endclass
