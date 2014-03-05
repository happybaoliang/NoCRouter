library verilog;
use verilog.vl_types.all;
entity c_regfile is
    generic(
        depth           : integer := 8;
        width           : integer := 64;
        num_write_ports : integer := 1;
        num_read_ports  : integer := 1;
        regfile_type    : integer := 0
    );
    port(
        clk             : in     vl_logic;
        write_active    : in     vl_logic;
        write_enable    : in     vl_logic_vector;
        write_address   : in     vl_logic_vector;
        write_data      : in     vl_logic_vector;
        read_address    : in     vl_logic_vector;
        read_data       : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of depth : constant is 1;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of num_write_ports : constant is 1;
    attribute mti_svvh_generic_type of num_read_ports : constant is 1;
    attribute mti_svvh_generic_type of regfile_type : constant is 1;
end c_regfile;
