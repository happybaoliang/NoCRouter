library verilog;
use verilog.vl_types.all;
entity rtr_flit_buffer is
    generic(
        num_vcs         : integer := 4;
        buffer_size     : integer := 32;
        flit_data_width : integer := 64;
        header_info_width: integer := 8;
        regfile_type    : integer := 0;
        explicit_pipeline_register: integer := 1;
        gate_buffer_write: integer := 0;
        mgmt_type       : integer := 0;
        fast_peek       : integer := 1;
        atomic_vc_allocation: integer := 1;
        enable_bypass   : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        push_active     : in     vl_logic;
        push_valid      : in     vl_logic;
        push_head       : in     vl_logic;
        push_tail       : in     vl_logic;
        push_sel_ivc    : in     vl_logic_vector;
        push_data       : in     vl_logic_vector;
        pop_active      : in     vl_logic;
        pop_valid       : in     vl_logic;
        pop_sel_ivc     : in     vl_logic_vector;
        pop_data        : out    vl_logic_vector;
        pop_tail_ivc    : out    vl_logic_vector;
        pop_next_header_info: out    vl_logic_vector;
        almost_empty_ivc: out    vl_logic_vector;
        empty_ivc       : out    vl_logic_vector;
        full            : out    vl_logic;
        errors_ivc      : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of buffer_size : constant is 1;
    attribute mti_svvh_generic_type of flit_data_width : constant is 1;
    attribute mti_svvh_generic_type of header_info_width : constant is 1;
    attribute mti_svvh_generic_type of regfile_type : constant is 1;
    attribute mti_svvh_generic_type of explicit_pipeline_register : constant is 1;
    attribute mti_svvh_generic_type of gate_buffer_write : constant is 1;
    attribute mti_svvh_generic_type of mgmt_type : constant is 1;
    attribute mti_svvh_generic_type of fast_peek : constant is 1;
    attribute mti_svvh_generic_type of atomic_vc_allocation : constant is 1;
    attribute mti_svvh_generic_type of enable_bypass : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_flit_buffer;
