library verilog;
use verilog.vl_types.all;
entity whr_alloc_mac is
    generic(
        num_ports       : integer := 5;
        precomp_ip_sel  : integer := 1;
        arbiter_type    : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        route_ip_op     : in     vl_logic_vector;
        req_ip          : in     vl_logic_vector;
        req_head_ip     : in     vl_logic_vector;
        req_tail_ip     : in     vl_logic_vector;
        gnt_ip          : out    vl_logic_vector;
        flit_valid_op   : out    vl_logic_vector;
        flit_head_op    : out    vl_logic_vector;
        flit_tail_op    : out    vl_logic_vector;
        xbr_ctrl_op_ip  : out    vl_logic_vector;
        elig_op         : in     vl_logic_vector;
        full_op         : in     vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of precomp_ip_sel : constant is 1;
    attribute mti_svvh_generic_type of arbiter_type : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end whr_alloc_mac;
