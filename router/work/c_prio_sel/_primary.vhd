library verilog;
use verilog.vl_types.all;
entity c_prio_sel is
    generic(
        num_ports       : integer := 32;
        num_priorities  : integer := 16
    );
    port(
        priorities      : in     vl_logic_vector;
        enable          : in     vl_logic_vector;
        \select\        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of num_priorities : constant is 1;
end c_prio_sel;
