class mem_normal_seq extends uvm_sequence #(axi_sequence_item);
  `uvm_object_utils(mem_normal_seq)
  function new(string name="mem_normal_seq");
    super.new(name);
  endfunction
  reg_block reg_model;
  virtual task body();
    int transferred_bytes = 0;
    int sent_burst_bytes;
    int total_length;
    axi_sequence_item req, rsp;
     `uvm_info(get_type_name(),
          "Sequence started",
          UVM_LOW)
    total_length = reg_model.length_reg_rm.length.get_mirrored_value();
    while(transferred_bytes < total_length) begin
      req = axi_sequence_item::type_id::create("req");
       `uvm_info(get_type_name(),
            "Before start_item",
            UVM_LOW)
      start_item(req);
       `uvm_info(get_type_name(),
            "After start_item",
            UVM_LOW)

      req.delay=0;
      finish_item(req);
      `uvm_info(get_type_name(),
            "After finish_item",
            UVM_LOW)
      get_response(rsp);
      sent_burst_bytes = (rsp.len + 1) * (1 << rsp.size);
      transferred_bytes += sent_burst_bytes;
    end
  endtask
endclass
