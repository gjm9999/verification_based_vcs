`ifndef PKT_DATA_SV
`define PKT_DATA_SV

class pkt_data;

	int      id_q[$];
	rand int data_id;
	
	constraint pkt_len_cons{
		//data_id inside id_q;
        data_id == this.id_q[0];
	};
	
	extern function new();
    extern function void post_randomize();
	
endclass

function pkt_data::new();

    for(int i=0; i < 1000; i++)begin
        this.id_q.push_back(i);
    end
    this.id_q.shuffle();

endfunction

function void pkt_data::post_randomize();
    this.id_q.shuffle();
endfunction

`endif
