library verilog;
use verilog.vl_types.all;
entity vcr_alloc_mac is
    generic(
        num_message_classes: integer := 2;
        num_resource_classes: integer := 2;
        num_vcs_per_class: integer := 1;
        num_ports       : integer := 5;
        vc_allocator_type: integer := 0;
        vc_arbiter_type : integer := 0;
        sw_allocator_type: integer := 0;
        sw_arbiter_type : integer := 0;
        spec_type       : integer := 1;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        route_ip_ivc_op : in     vl_logic_vector;
        route_ip_ivc_orc: in     vl_logic_vector;
        allocated_ip_ivc: in     vl_logic_vector;
        flit_valid_ip_ivc: in     vl_logic_vector;
        flit_head_ip_ivc: in     vl_logic_vector;
        flit_tail_ip_ivc: in     vl_logic_vector;
        elig_op_ovc     : in     vl_logic_vector;
        free_nonspec_ip_ivc: in     vl_logic_vector;
        vc_active_op    : out    vl_logic_vector;
        vc_gnt_ip_ivc   : out    vl_logic_vector;
        vc_sel_ip_ivc_ovc: out    vl_logic_vector;
        vc_gnt_op_ovc   : out    vl_logic_vector;
        vc_sel_op_ovc_ip: out    vl_logic_vector;
        vc_sel_op_ovc_ivc: out    vl_logic_vector;
        sw_active_op    : out    vl_logic_vector;
        sw_gnt_ip       : out    vl_logic_vector;
        sw_sel_ip_ivc   : out    vl_logic_vector;
        sw_gnt_op       : out    vl_logic_vector;
        sw_sel_op_ip    : out    vl_logic_vector;
        sw_sel_op_ivc   : out    vl_logic_vector;
        flit_head_op    : out    vl_logic_vector;
        flit_tail_op    : out    vl_logic_vector;
        xbr_ctrl_op_ip  : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_message_classes : constant is 1;
    attribute mti_svvh_generic_type of num_resource_classes : constant is 1;
    attribute mti_svvh_generic_type of num_vcs_per_class : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of vc_allocator_type : constant is 1;
    attribute mti_svvh_generic_type of vc_arbiter_type : constant is 1;
    attribute mti_svvh_generic_type of sw_allocator_type : constant is 1;
    attribute mti_svvh_generic_type of sw_arbiter_type : constant is 1;
    attribute mti_svvh_generic_type of spec_type : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end vcr_alloc_mac;
