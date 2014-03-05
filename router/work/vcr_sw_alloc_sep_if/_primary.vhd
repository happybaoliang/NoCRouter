library verilog;
use verilog.vl_types.all;
entity vcr_sw_alloc_sep_if is
    generic(
        num_vcs         : integer := 4;
        num_ports       : integer := 5;
        arbiter_type    : integer := 0;
        spec_type       : integer := 1;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active_ip       : in     vl_logic_vector;
        active_op       : in     vl_logic_vector;
        route_ip_ivc_op : in     vl_logic_vector;
        req_nonspec_ip_ivc: in     vl_logic_vector;
        req_spec_ip_ivc : in     vl_logic_vector;
        gnt_ip          : out    vl_logic_vector;
        sel_ip_ivc      : out    vl_logic_vector;
        gnt_op          : out    vl_logic_vector;
        sel_op_ip       : out    vl_logic_vector;
        sel_op_ivc      : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of arbiter_type : constant is 1;
    attribute mti_svvh_generic_type of spec_type : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end vcr_sw_alloc_sep_if;
