// register interface.
interface register;
logic [31:0] MM2S_DMACR,MM2S_DMASR,MM2S_SA,MM2S_LENGTH;
modport c_fsm(output MM2S_DMASR,
input MM2S_DMACR,MM2S_LENGTH,MM2S_SA);
modport top(output MM2S_DMACR,MM2S_SA,MM2S_LENGTH,
input MM2S_DMASR );
endinterface