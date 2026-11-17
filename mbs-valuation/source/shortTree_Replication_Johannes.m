
% JE & EZ - fits BDT tree in Excel Example file

clear all
clc


%% Set parameters

%End date, in years
T=3;

%Number of steps in the binomial tree
N=3;

%set time step size
dt=T/N;


%m for vector of maturities
m=(dt:dt:T)';


observedData=table(m);
% column 1: 'm' maturity, column 2: 'y' yield, column 3: 'vol' volatility


%% EXCEL REPLICATION

%Commented out sections below to replicating excel results here.
observedData.price = [0.9091; 0.8116; 0.7118];
observedData.volatility = [0; 0.19; 0.18];

%Create empty tree. the (i,j) node represents time i and node j of the
%short rate tree

shortTree=NaN(N,N);

%Starting Guesses for fminsearch
startR=.01;
startParam=[.01,.01];


%% Create first node in tree

i=1;
disp('Percentage of total steps completed:')
disp(i/N)
thisPrice=observedData.price(i);
thisMaturity=observedData.m(i);

%No volatility matching for first node
thisError=@(r) (1*exp(-r*thisMaturity)-thisPrice)^2;

thisR=fminsearch(thisError,startR);

shortTree(i,1)=thisR;


%% Moving on in the tree

for i = 2:N
        disp('Percentage of total steps completed:')
        disp(i/N)

        thisPrice=observedData.price(i);
        thisMaturity=observedData.m(i);
        thisVolatility=observedData.volatility(i);

        thisPriceAndVol=[thisPrice,thisVolatility];

        params=NaN(2,1);
        thisError=@(params) sum((thisPriceAndVol-bondTree(params,i,dt,shortTree)).^2);
        thisParam=fminsearch(thisError,startParam);

        %Build next step in tree with the right parameters
        thisBottomR=thisParam(1);
        thisSigma=thisParam(2);

        treeStep=exp(2*thisSigma);

        %populate next step in shortTree
        shortTree(i,1)=thisBottomR;
        for j=2:(i)
            shortTree(i,j)=thisBottomR*exp(2*(j-1)*thisSigma*sqrt(dt));
        end
end


%% displaying short tree

disp('====================================')
disp('The short tree is:')
disp(shortTree)










