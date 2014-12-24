#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>

using namespace std;


int main(int argc,char* argv[]){
	
	int cycles;
	string line;
	ifstream input;
	ofstream output;
	
	bool flag=false;

	input.open("stat.db",ios::in);
	output.open(argv[1],ios::out);

	while(!input.eof()){
		getline(input,line);
		if (line.find("simulation")==0){
			flag=true;
			line.erase(0,22);
			cycles=atoi(line.c_str());
			getline(input,line);
		} else if (line.find("$finish")==0){
			flag=false;
		} else if (flag){
			output<<line<<endl;
		}
	}	

	output<<"router=router00+router01+router02+router03+router04+router05+router06+router07+router08+router09+router10+router11+router12+router13+router14+router15;"<<endl;

	output<<"P=5;"<<endl;
	
	output<<"V="<<argv[2]<<";"<<endl;

	output<<"N=16;"<<endl;

	output<<"rho=sum(sum(router))/(P*V*N*"<<cycles<<")"<<endl;
	
	input.close();
	output.close();

	return 0;
}
