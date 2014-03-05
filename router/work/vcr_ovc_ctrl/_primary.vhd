library verilog;
use verilog.vl_types.all;
entity vcr_ovc_ctrl is
    generic(
        num_vcs         : integer := 4;
        num_ports       : integer := 5;
        sw_alloc_spec   : integer := 1;
        elig_mask       : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        vc_active       : in     vl_logic;
        vc_gnt          : in     vl_logic;
        vc_sel_ip       : in     vl_logic_vector;
        vc_sel_ivc      : in     vl_logic_vector;
        sw_active       : in     vl_logic;
        sw_gnt          : in     vl_logic;
        sw_sel_ip       : in     vl_logic_vector;
        sw_sel_ivc      : in     vl_logic_vector;
        flit_valid      : in     vl_logic;
        flit_tail       : in     vl_logic;
        flit_sel        : out    vl_logic;
        elig            : out    vl_logic;
        full            : in     vl_logic;
        full_prev       : in     vl_logic;
        empty           : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of sw_alloc_spec : constant is 1;
    attribute mti_svvh_generic_type of elig_mask : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end vcr_ovc_ctrl;
