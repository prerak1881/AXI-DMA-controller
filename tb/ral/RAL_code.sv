// Code your testbench here
// or browse Examples
//------------------------------------------------------
//control register
class control_reg extends uvm_reg;
  `uvm_object_utils(control_reg)
  uvm_reg_field RS;
  uvm_reg_field reset;
  uvm_reg_field IOC_irqen;
  function new(string name="control_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction
  function void build();
    RS = uvm_reg_field::type_id::create("RS");
    reset = uvm_reg_field::type_id::create("reset");
    IOC_irqen = uvm_reg_field::type_id::create("IOC_irqen");
    RS.configure(this,1,0,"RW",0,1'h0,1,1,1);
    reset.configure(this,1,1,"RW",0,1'h0,1,1,1);
    IOC_irqen.configure(this,1,12,"RW",0,1'h0,1,1,1);
  endfunction
endclass
//status register
class status_reg extends uvm_reg;
`uvm_object_utils(status_reg)
uvm_reg_field IOC_irq;
uvm_reg_field idle;
function new(string name="status_reg");
 super.new(name,32,UVM_NO_COVERAGE);
endfunction
function void build();
idle=uvm_reg_field::type_id::create("idle");
IOC_irq=uvm_reg_field::type_id::create("IOC_irq");
idle.configure(this,1,1,"RO",0,0,1,1,1);
IOC_irq.configure(this,1,12,"RO",0,0,1,1,1);
endfunction
endclass
//source address register
class source_addr_reg extends uvm_reg;
`uvm_object_utils(source_addr_reg)
uvm_reg_field source_addr;
function new(string name="source_addr_reg");
super.new(name,32,UVM_NO_COVERAGE);
endfunction
function void build();
source_addr=uvm_reg_field::type_id::create("source_addr");
source_addr.configure(this,32,0,"RW",0,0,1,1,1);
endfunction
endclass
//length register
class length_reg extends uvm_reg;
  `uvm_object_utils(length_reg)
  uvm_reg_field length;
  function new(string name="length_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction
  function void build();
    length=uvm_reg_field::type_id::create("length");
    length.configure(this,26,0,"RW",0,1'h0,1,1,1);
  endfunction
endclass
// reg block
class reg_block extends uvm_reg_block;
  `uvm_object_utils(reg_block);
  control_reg control_reg_rm;
  status_reg status_reg_rm;
  source_addr_reg source_addr_reg_rm;
  length_reg length_reg_rm;
  function new(string name="reg_block");
    super.new(name,UVM_NO_COVERAGE);
  endfunction
  function void build();
default_map=create_map("",0,4,UVM_LITTLE_ENDIAN,0);
control_reg_rm=control_reg::type_id::create("control_reg_rm");
status_reg_rm=status_reg::type_id::create("status_reg_rm");
source_addr_reg_rm=source_addr_reg::type_id::create("source_addr_reg_rm");
length_reg_rm=length_reg::type_id::create("length_reg_rm");
//------------------------------------------
control_reg_rm.configure(this,null,"");
status_reg_rm.configure(this,null,"");
source_addr_reg_rm.configure(this,null,"");
length_reg_rm.configure(this,null,"");
//-------------------------------------------
control_reg_rm.build();
status_reg_rm.build();
source_addr_reg_rm.build();
length_reg_rm.build();
//-------------------------------------------
default_map.add_reg(control_reg_rm,'h40000000,"RW");
default_map.add_reg(status_reg_rm,'h40000004,"RO");
default_map.add_reg(source_addr_reg_rm,'h40000018,"RW");
default_map.add_reg(length_reg_rm,'h40000028,"RW");
lock_model();
endfunction
endclass
//adapter creation
class axi_lite_adapter extends uvm_reg_adapter;
  `uvm_object_utils(axi_lite_adapter);
  function new(string name="axi_lite_adapter");
    super.new(name);
    supports_byte_enable=0;
    provides_responses=0;
  endfunction
  virtual function uvm_sequence_item reg2bus(
 const ref uvm_reg_bus_op rw
);
axi_lite_sequence_item item;
item=axi_lite_sequence_item::type_id::create("item");
item.write_req=(rw.kind==UVM_WRITE);
item.addr=rw.addr;
item.data=rw.data;
return item;
endfunction
  virtual function void bus2reg(
uvm_sequence_item bus_item,
 ref uvm_reg_bus_op rw
);
axi_lite_sequence_item item;
if(!$cast(item,bus_item))
begin
 `uvm_fatal("ADAPTER","Cast failed")
end
rw.kind = item.write_req ? UVM_WRITE : UVM_READ;
rw.addr=item.addr;
rw.data=item.data;
rw.status=UVM_IS_OK;
endfunction
endclass
