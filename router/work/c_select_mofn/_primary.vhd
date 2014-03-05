library verilog;
use verilog.vl_types.all;
entity c_select_mofn is
    generic(
        num_ports       : integer := 4;
        width           : integer := 32;
        prod_op         : integer := 0;
        sum_op          : integer := 2
    );
    port(
        \select\        : in     vl_logic_vector;
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of prod_op : constant is 1;
    attribute mti_svvh_generic_type of sum_op : constant is 1;
end c_select_mofn;
