library verilog;
use verilog.vl_types.all;
entity c_crossbar is
    generic(
        num_in_ports    : integer := 5;
        num_out_ports   : integer := 5;
        width           : integer := 32;
        crossbar_type   : integer := 1
    );
    port(
        ctrl_ip_op      : in     vl_logic_vector;
        data_in_ip      : in     vl_logic_vector;
        data_out_op     : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_in_ports : constant is 1;
    attribute mti_svvh_generic_type of num_out_ports : constant is 1;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of crossbar_type : constant is 1;
end c_crossbar;
