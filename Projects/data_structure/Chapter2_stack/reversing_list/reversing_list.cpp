#include <stack>
#include "utilities.h"

using namespace std;

int main()
/*Pre: The user inputs an integer n and n decimal numbers
  Post: The numbers are printed in reverse order
  Uses: STL class stack*/
{
	int n;
	double item;
	stack<double>numbers;
	cout<<"Type in an integer n followed by n decimal numbers:"<<endl;
	cout<<"The numbers will be printed in reverse order."<<endl;
	cin>>n;
	for(int i=0; i<n; i++){
		cin>>item;
		numbers.push(item);
	}
	cout<<endl<<endl;
	while(!numbers.empty()){
		cout<<numbers.top()<<" ";
		numbers.pop();
	}
	cout<<endl;
}