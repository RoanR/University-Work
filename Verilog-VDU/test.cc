#include <vector>
#include <iostream>

using namespace std;
class test {
    private:
        vector<vector<int>> lineContainer;
    public:
        test(int n){
            lineContainer.push_back({010});
            for (int i=1; i<n; i++){
                vector<int> current  = newline(lineContainer[i-1].size()-1, lineContainer[i-1]);
                lineContainer.push_back(current);
            }
        }

        vector<int> newline(int n, vector<int> previous){
            vector<int> line;
            for (int i = 0; i <= n+2; i++){
                int current = 0;
                if (i == 0){current = 1;}
                else if (i == n+2){current = 1;}
                else if (i == 1){current = rules({0,previous[0], previous[1]});}
                else if (i == n+1){current = rules({previous[n-1], previous[n], 0});}
                else {current = rules({previous[i-2], previous[i-1], previous[i]});}
                cout<<current;
                line.push_back(current);
            }
            cout<<"\n";
            return line; 
        }

        int rules(vector<int> previous){
            int L = previous[0];
            int M = previous[1];
            int R = previous[2];

            if      ((L)&&(M)&&(R)){return 0;}   //111 -> 0
            else if ((L)&&(M)&&(!R)){return 1;}  //110 -> 1
            else if ((L)&&(!M)&&(R)){return 0;}  //101 -> 0
            else if ((!L)&&(M)&&(R)){return 0;}  //011 -> 0
            else if ((L)&&(!M)&&(!R)){return 1;} //100 -> 1
            else if ((!L)&&(M)&&(!R)){return 1;} //010 -> 1
            else if ((!L)&&(!M)&&(R)){return 1;} //001 -> 1
            else if ((!L)&&(!M)&&(!R)){return 0;}//000 -> 0
            return 0;
        }
};

int main(int argc, char const *argv[]){
    test driver(10);
    return 0;
}



