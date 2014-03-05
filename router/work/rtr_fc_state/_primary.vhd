library verilog;
use verilog.vl_types.all;
entity rtr_fc_state is
    generic(
        num_vcs         : integer := 4;
        buffer_size     : integer := 16;
        flow_ctrl_type  : integer := 0;
        flow_ctrl_bypass: integer := 1;
        mgmt_type       : integer := 0;
        fast_almost_empty: integer := 0;
        disable_static_reservations: integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        flit_valid      : in     vl_logic;
        flit_head       : in     vl_logic;
        flit_tail       : in     vl_logic;
        flit_sel_ovc    : in     vl_logic_vector;
        fc_event_valid  : in     vl_logic;
        fc_event_sel_ovc: in     vl_logic_vector;
        fc_active       : out    vl_logic;
        empty_ovc       : out    vl_logic_vector;
        almost_full_ovc : out    vl_logic_vector;
        full_ovc        : out    vl_logic_vector;
        full_prev_ovc   : out    vl_logic_vector;
        errors_ovc      : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of buffer_size : constant is 1;
    attribute mti_svvh_generic_type of flow_ctrl_type : constant is 1;
    attribute mti_svvh_generic_type of flow_ctrl_bypass : constant is 1;
    attribute mti_svvh_generic_type of mgmt_type : constant is 1;
    attribute mti_svvh_generic_type of fast_almost_empty : constant is 1;
    attribute mti_svvh_generic_type of disable_static_reservations : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_fc_state;
