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

int max_lat;
int min_lat;
vector<int> total_lat;

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

	min_lat=10000;
	max_lat=-10000;
	total_lat.clear();

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
				if (time-create<min_lat)
					min_lat=time-create;
				if (time-create>max_lat)
					max_lat=time-create;
				total_lat.push_back(time-create);
				latency[dst_dim1*RTR_PER_DIM+dst_dim2].lat[src_dim1*RTR_PER_DIM+src_dim2].push_back(time-create);
			}
		} else if (line=="dst:"){
			input>>src_dim1>>src_dim2>>pkt_num>>dst_dim1>>dst_dim2;
			latency[src_dim1*RTR_PER_DIM+src_dim2].dst.push_back(dst_dim1*RTR_PER_DIM+dst_dim2);
			if (latency[src_dim1*RTR_PER_DIM+src_dim2].dst.size()!=(pkt_num+1)){
				cout<<"number dismatch occur when update dest"<<endl;
			}
		} else if (line=="measuring..."){
			warmup=false;
			cout<<"start to measuring latency."<<endl;
		}
	}	
	
	input.close();

	cout<<"max packet latency: "<<max_lat<<endl;
	cout<<"min packet latency: "<<min_lat<<endl;

	int lat=0;
	for (int i=0;i<total_lat.size();i++){
		lat+=total_lat[i];
	}

	cout<<"total average packet latency is: "<<(1.0*lat)/(total_lat.size())<<endl;

	for (int i=0;i<RTR_CNT;i++){
		cout<<"average packet latency arrived at "<<i<<":"<<endl;
		for (int j=0;j<RTR_CNT;j++){
			lat=0;
			for (int k=0;k<latency[i].lat[j].size();k++){
				lat+=latency[i].lat[j].at(k);
			}
			cout<<setw(7)<<(1.0*lat)/(latency[i].lat[j].size())<<"	";
		}
		cout<<endl;
	}

	return 0;
}
