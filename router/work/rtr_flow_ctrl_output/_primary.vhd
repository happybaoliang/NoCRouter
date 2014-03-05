library verilog;
use verilog.vl_types.all;
entity rtr_flow_ctrl_output is
    generic(
        num_vcs         : integer := 4;
        flow_ctrl_type  : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        fc_event_valid_in: in     vl_logic;
        fc_event_sel_in_ivc: in     vl_logic_vector;
        flow_ctrl_out   : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of flow_ctrl_type : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_flow_ctrl_output;
