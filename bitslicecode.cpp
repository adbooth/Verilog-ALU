#include <iostream>
using namespace std;

int main(){
    for(int i = 0; i < 32; i++)
        cout << "    bitSlice bs" << i << "(out[" << i << "], bit" << i << "Set, bit" << i << "Cout, a[" << i << "], b[" << i << "], bit" << i-1 << "Cout, 0, op);" << endl;
}
