library verilog;
use verilog.vl_types.all;
entity whr_op_ctrl_mac is
    generic(
        buffer_size     : integer := 8;
        num_routers_per_dim: integer := 4;
        num_ports       : integer := 5;
        packet_format   : integer := 2;
        flow_ctrl_type  : integer := 0;
        flow_ctrl_bypass: integer := 1;
        elig_mask       : integer := 0;
        max_payload_length: integer := 4;
        min_payload_length: integer := 1;
        enable_link_pm  : integer := 1;
        flit_data_width : integer := 64;
        error_capture_mode: integer := 1;
        port_id         : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        flow_ctrl_in    : in     vl_logic_vector;
        flit_valid_in   : in     vl_logic;
        flit_head_in    : in     vl_logic;
        flit_tail_in    : in     vl_logic;
        flit_data_in    : in     vl_logic_vector;
        channel_out     : out    vl_logic_vector;
        elig            : out    vl_logic;
        full            : out    vl_logic;
        error           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of buffer_size : constant is 1;
    attribute mti_svvh_generic_type of num_routers_per_dim : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of packet_format : constant is 1;
    attribute mti_svvh_generic_type of flow_ctrl_type : constant is 1;
    attribute mti_svvh_generic_type of flow_ctrl_bypass : constant is 1;
    attribute mti_svvh_generic_type of elig_mask : constant is 1;
    attribute mti_svvh_generic_type of max_payload_length : constant is 1;
    attribute mti_svvh_generic_type of min_payload_length : constant is 1;
    attribute mti_svvh_generic_type of enable_link_pm : constant is 1;
    attribute mti_svvh_generic_type of flit_data_width : constant is 1;
    attribute mti_svvh_generic_type of error_capture_mode : constant is 1;
    attribute mti_svvh_generic_type of port_id : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end whr_op_ctrl_mac;
