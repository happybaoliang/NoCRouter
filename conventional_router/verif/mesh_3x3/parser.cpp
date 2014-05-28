#include <iostream>
#include <fstream>

using namespace std;

int main(int argc,char* argv[]){
	int time;
	int pkt_num;
	string line;
	ifstream input;
	int src_dim1,src_dim2;
	int dst_dim1,dst_dim2;

	input.open("stat.txt",ios::in);
	
	while(!input.eof()){
		getline(input,line);
		if (line=="gen:"){
			input>>src_dim1>>src_dim2>>pkt_num>>time;
			std::cout<<"["<<src_dim1<<","<<src_dim2<<"] generates No."<<pkt_num<<" packet at "<<time<<endl;
		} else if (line=="rev:"){
			input>>dst_dim1>>dst_dim2>>src_dim1>>src_dim2>>pkt_num>>time;
			std::cout<<"["<<dst_dim1<<","<<dst_dim2<<"] receives No."<<pkt_num;
			std::cout<<" packet injected from ["<<src_dim1<<","<<src_dim2<<"] at time "<<time<<endl;
		} else if (line=="dst:"){
			input>>src_dim1>>src_dim2>>pkt_num>>dst_dim1>>dst_dim2;
			std::cout<<"["<<src_dim1<<","<<src_dim2<<"] updates the destination of No.";
			std::cout<<pkt_num<<" packet to ["<<dst_dim1<<","<<dst_dim2<<"]"<<endl;
		}
	}	
	
	input.close();

	return 0;
}
