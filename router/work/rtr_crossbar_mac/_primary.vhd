library verilog;
use verilog.vl_types.all;
entity rtr_crossbar_mac is
    generic(
        num_ports       : integer := 5;
        width           : integer := 32;
        crossbar_type   : integer := 1
    );
    port(
        ctrl_in_op_ip   : in     vl_logic_vector;
        data_in_ip      : in     vl_logic_vector;
        data_out_op     : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of crossbar_type : constant is 1;
end rtr_crossbar_mac;
