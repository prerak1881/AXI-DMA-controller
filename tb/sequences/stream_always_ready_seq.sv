class stream_always_ready_seq extends uvm_sequence #(axi_stream_sequence_item);
  `uvm_object_utils(stream_always_ready_seq)
  function new(string name = "stream_always_ready_seq");
    super.new(name);
  endfunction
  axi_stream_sequence_item req;
  reg_block reg_model;
  int total_length;
  int i;
  virtual task body();
  `uvm_info(get_type_name(),
          "Sequence started",
          UVM_LOW)
    req = axi_stream_sequence_item::type_id::create("req");
    if (reg_model == null)
      `uvm_fatal(get_type_name(), "reg_model is null")
    total_length = reg_model.length_reg_rm.length.get_mirrored_value();
    i = 0;
    while (i < total_length) begin
      `uvm_info(get_type_name(),
            "Before start_item",
            UVM_LOW)
      start_item(req);
       `uvm_info(get_type_name(),
            "After start_item",
            UVM_LOW)
      // No randomization needed since the sequence only controls backpressure
      req.delay = 0;
      finish_item(req);
      `uvm_info(get_type_name(),
            "After finish_item",
            UVM_LOW)
      i += 4;
    end
  endtask
endclass
