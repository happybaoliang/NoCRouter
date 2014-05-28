#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>

using namespace std;

#define RTR_PER_DIM	3
#define RTR_CNT	RTR_PER_DIM*RTR_PER_DIM
 
struct stat{
	vector<int> dst;
	vector<int> crt;
	vector<int> lat[RTR_CNT];
};

struct stat latency[RTR_CNT];

int main(int argc,char* argv[]){
	
	int time;
	int create;
	int pkt_num;
	string line;
	int stat_cnt;
	ifstream input;
	int src_dim1,src_dim2;
	int dst_dim1,dst_dim2;

	input.open("stat.db",ios::in);
	
	for (int i=0;i<RTR_CNT;i++){
		latency[i].dst.clear();
		latency[i].crt.clear();
		for (int j=0;j<RTR_CNT;j++){
			latency[i].lat[j].clear();
		}
	}

	bool warmup=true;
	
	while(!input.eof()){
		getline(input,line);
		if (line=="gen:"){
			input>>src_dim1>>src_dim2>>pkt_num>>time;
			latency[src_dim1*RTR_PER_DIM+src_dim2].crt.push_back(time);
			if (latency[src_dim1*RTR_PER_DIM+src_dim2].crt.size()!=(pkt_num+1))
				cout<<"number dismatch occur when update create"<<endl;
		} else if (line=="rev:"){
			input>>dst_dim1>>dst_dim2>>src_dim1>>src_dim2>>pkt_num>>time;
			create=latency[src_dim1*RTR_PER_DIM+src_dim2].crt[pkt_num];
			if (!warmup){
				latency[dst_dim1*RTR_PER_DIM+dst_dim2].lat[src_dim1*RTR_PER_DIM+src_dim2].push_back(time-create);
			}
		} else if (line=="dst:"){
			input>>src_dim1>>src_dim2>>pkt_num>>dst_dim1>>dst_dim2;
			latency[src_dim1*RTR_PER_DIM+src_dim2].dst.push_back(dst_dim1*RTR_PER_DIM+dst_dim2);
			if (latency[src_dim1*RTR_PER_DIM+src_dim2].dst.size()!=(pkt_num+1))
				cout<<"number dismatch occur when update dest"<<endl;
		} else if (line=="measuring..."){
			warmup=false;
			cout<<"start to measuring latency."<<endl;
		}
	}	
	
	input.close();

	for (int i=0;i<RTR_CNT;i++){
		cout<<"average packet latency arrived at "<<i<<":"<<endl;
		for (int j=0;j<RTR_CNT;j++){
			int lat=0;
			for (int k=0;k<latency[i].lat[j].size();k++){
				lat+=latency[i].lat[j].at(k);
			}
			cout<<setw(7)<<(1.0*lat)/(latency[i].lat[j].size())<<"	";
		}
		cout<<endl;
	}

	return 0;
}
