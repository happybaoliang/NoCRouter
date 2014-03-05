library verilog;
use verilog.vl_types.all;
entity vcr_vc_alloc_sep_of is
    generic(
        num_message_classes: integer := 2;
        num_resource_classes: integer := 2;
        num_vcs_per_class: integer := 1;
        num_ports       : integer := 5;
        arbiter_type    : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active_ip       : in     vl_logic_vector;
        active_op       : in     vl_logic_vector;
        route_ip_ivc_op : in     vl_logic_vector;
        route_ip_ivc_orc: in     vl_logic_vector;
        elig_op_ovc     : in     vl_logic_vector;
        req_ip_ivc      : in     vl_logic_vector;
        gnt_ip_ivc      : out    vl_logic_vector;
        sel_ip_ivc_ovc  : out    vl_logic_vector;
        gnt_op_ovc      : out    vl_logic_vector;
        sel_op_ovc_ip   : out    vl_logic_vector;
        sel_op_ovc_ivc  : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_message_classes : constant is 1;
    attribute mti_svvh_generic_type of num_resource_classes : constant is 1;
    attribute mti_svvh_generic_type of num_vcs_per_class : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of arbiter_type : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end vcr_vc_alloc_sep_of;
