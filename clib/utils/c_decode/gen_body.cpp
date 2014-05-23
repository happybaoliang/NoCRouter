#include <iostream>
#include <cstdlib>
#include <cmath>

int main(int argc, char ** argv) {
  int min = (argc > 1) ? atoi(argv[1]) : 2;
  int max = (argc > 2) ? atoi(argv[2]) : std::max(min, 64);
  std::cout
    << "      // synopsys translate_off\n"
    << "      if(num_ports < " << min << ")\n"
    << "	begin\n"
    << "	   initial\n"
    << "	     begin\n"
    << "		$display({\"ERROR: Decoder module %m needs at least "
    << min << " outputs.\"});\n"
    << "		$stop;\n"
    << "	     end\n"
    << "	end\n"
    << "      else if(num_ports > " << max << ")\n"
    << "	begin\n"
    << "	   initial\n"
    << "	     begin\n"
    << "		$display({\"ERROR: Decoder module %m supports at most "
    << max << " outputs.\"});\n"
    << "		$stop;\n"
    << "	     end\n"
    << "	end\n"
    << "      // synopsys translate_on\n"
    << "      \n";
  for(int size = min; size <= max; ++size) {
    int width = (int)ceil(log2(size));
      std::cout
	<< "      ";
    if(size > min) {
      std::cout << "else ";
    }
    std::cout << "if(num_ports == " << size << ")\n"
      << "        always@(data_in)\n"
      << "          begin\n"
      << "             case(data_in)\n";
    for(int pos = 0; pos < size; ++pos) {
      std::cout
	<< "               ((" << pos << " + offset) % " << size << "):\n"
	<< "                 data_out = {";
      if(pos > 0) {
	std::cout << "{" << pos << "{1'b0}}, ";
      }
      std::cout << "1'b1";
      if(pos + 1 < size) {
	std::cout << ", {" << (size - pos - 1) << "{fillchar}}";
      }
      std::cout << "};\n";
    }
    std::cout
      << "               default:\n"
      << "                 data_out = {" << size << "{1'bx}};\n"
      << "             endcase\n"
      << "          end\n";
  }
}
