


%% import data for the treasury yield curve
%par vector contains, respectively, beta0, beta1, beta2, and tau
yieldData=readtable('yieldAndVolatility2000.csv');

% Set start parameters
startPar = [1, 1, 1, 1];  % beta0 ~ level, beta1 ~ slope, beta2 ~ curvature, tau ~ 1 to 3 years


%% Alias the error function with observed data and parameters.

errorNelsonSiegelYield=@(par) (sum((yieldData.y-( ...
    par(1)+ ...
    (par(2)+par(3)).*(1-exp(-yieldData.m./par(4)))./(yieldData.m./par(4))- ...
    par(3).*exp(-yieldData.m./par(4)) ...
    )).^2));

errorNelsonSiegelVol=@(par) (sum((yieldData.vol-( ...
    par(1)+ ...
    (par(2)+par(3)).*(1-exp(-yieldData.m./par(4)))./(yieldData.m./par(4))- ...
    par(3).*exp(-yieldData.m./par(4)) ...
    )).^2));

%Run optimization
[parMinYield,errorMinYield] = fminsearch(errorNelsonSiegelYield, startPar);
[parMinVol,errorMinVol]   = fminsearch(errorNelsonSiegelVol, startPar);


%% Alias new function fittedYield that takes as input some maturity m and 
%returns fitted yields at the estimated parameters

fittedFunctionYield= @(m) ( ...
    parMinYield(1)+ ...
    (parMinYield(2)+parMinYield(3)).*(1-exp(-m./parMinYield(4)))./(m./parMinYield(4))- ...
    parMinYield(3).*exp(-m./parMinYield(4)) ...
    );
fittedFunctionVol= @(m) ( ...
    parMinVol(1)+ ...
    (parMinVol(2)+parMinVol(3)).*(1-exp(-m./parMinVol(4)))./(m./parMinVol(4))- ...
    parMinVol(3).*exp(-m./parMinVol(4)) ...
    );

yieldData.nelsonSiegelYield= fittedFunctionYield(yieldData.m);
yieldData.nelsonSiegelVol= fittedFunctionVol(yieldData.m);

disp('======================================================================')
disp('The fitted data table is:')
disp(yieldData)


%% plot the results
subplot(2,1,1)
plot(yieldData.m,yieldData.y,'*',yieldData.m,yieldData.nelsonSiegelYield);
legend('Observed Yields','Nelson Siegel Fitted Yields')
subplot(2,1,2)
plot(yieldData.m,yieldData.vol,'*',yieldData.m,yieldData.nelsonSiegelVol);
legend('Observed Vols','Nelson Siegel Fitted Vols')


%% MBS Part (ii) a): Fit the BDT Tree

% Import data
yieldData=readtable('yieldAndVolatility2000.csv');
% Set start parameters
startPar = [1, 1, 1, 1];

% Alias the error function with observed data and parameters.

errorNelsonSiegelYield=@(par) (sum((yieldData.y-( ...
    par(1)+ ...
    (par(2)+par(3)).*(1-exp(-yieldData.m./par(4)))./(yieldData.m./par(4))- ...
    par(3).*exp(-yieldData.m./par(4)) ...
    )).^2));

errorNelsonSiegelVol=@(par) (sum((yieldData.vol-( ...
    par(1)+ ...
    (par(2)+par(3)).*(1-exp(-yieldData.m./par(4)))./(yieldData.m./par(4))- ...
    par(3).*exp(-yieldData.m./par(4)) ...
    )).^2));

%Run optimization
[parMinYield,errorMinYield] = fminsearch(errorNelsonSiegelYield, startPar);
[parMinVol,errorMinVol]   = fminsearch(errorNelsonSiegelVol, startPar);

% Alias new function fittedYield that takes as input some maturity m and 
%returns fitted yields at the estimated parameters

fittedFunctionYield= @(m) ( ...
    parMinYield(1)+ ...
    (parMinYield(2)+parMinYield(3)).*(1-exp(-m./parMinYield(4)))./(m./parMinYield(4))- ...
    parMinYield(3).*exp(-m./parMinYield(4)) ...
    );
fittedFunctionVol= @(m) ( ...
    parMinVol(1)+ ...
    (parMinVol(2)+parMinVol(3)).*(1-exp(-m./parMinVol(4)))./(m./parMinVol(4))- ...
    parMinVol(3).*exp(-m./parMinVol(4)) ...
    );

% Generate new vector including all maturities
month=(1:360)';
m=month./12;
% Calculate fitted yields and volatilities for all 360 maturities
nelsonSiegelYields = fittedFunctionYield(m);
nelsonSiegelVols = fittedFunctionVol(m);

% Create table from results
fittedData=table(month, m, nelsonSiegelYields, nelsonSiegelVols, VariableNames={'Month','Maturity','nelsonSiegelYield','nelsonSiegelVol'});

%Display results
disp('======================================================================')
disp('The fitted Nelson-Siegel data table is:')
disp(fittedData)
disp('======================================================================')
%% Fitting the short rate tree

%End date, in years
T=fittedData.Maturity(end);

%Number of steps in the binomial tree
N=fittedData.Month(end);

%set time step size
dt=T/N;

%m for vector of maturities
m=(dt:dt:T)';

observedData=table(m);
% column 1: 'm' maturity, column 2: 'y' yield, column 3: 'vol' volatility

% EXCEL REPLICATION

% Using continuous discounting for the observed price
observedData.price = exp(-fittedData.nelsonSiegelYield.*fittedData.Maturity);
% Using semianually discounting for the observed price
% observedData.price=(1+observedData.yield/2).^(-2*m);
observedData.volatility = fittedData.nelsonSiegelVol;


%Create empty tree. the (i,j) node represents time i and node j of the
%short rate tree
shortTree=NaN(N,N);

%Starting Guesses for fminsearch
startR=.01;
startParam=[.01,.01];
thisParam=startParam;

% Create first node in tree
i=1;
disp('Percentage of total steps completed:')
disp(i/N)
thisPrice=observedData.price(i);
thisMaturity=observedData.m(i)

%No volatility matching for first node
thisError=@(r) (1*exp(-r*thisMaturity)-thisPrice)^2;
thisR=fminsearch(thisError,startR);
shortTree(i,1)=thisR;


%% Moving on in the tree
for i = 2:N
        disp('Percentage of total steps completed:')
        disp(i/N)
        % Use previous params for new iteration
        startParam=thisParam;
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

%% Visualize the short rate tree (log scale, light grey shading)

figure;
hold on;

% Preallocate min and max paths for shading
minRates = NaN(N,1);
maxRates = NaN(N,1);

for i = 1:N
    % Get all nodes at this time step
    nodes = shortTree(i,1:i);
    
    % Store min and max for shading
    minRates(i) = min(nodes);
    maxRates(i) = max(nodes);
    
    % Plot each node in LIGHT grey, still visible
    plot(i*ones(1,i), nodes, '.', ...
        'Color', [0.7 0.7 0.7], 'MarkerSize', 8);
end

% Very light shading between min and max
x = 1:N;
fill([x fliplr(x)], [minRates' fliplr(maxRates')], ...
     [0.92 0.92 0.92], 'FaceAlpha', 0.25, 'EdgeColor','none');

% Plot min and max paths with high contrast
plot(1:N, minRates, 'b-', 'LineWidth', 2.5);
plot(1:N, maxRates, 'r-', 'LineWidth', 2.5);

% Log scale
set(gca, 'YScale', 'log');

xlabel('Time Step');
ylabel('Short Rate (log scale)');
title('Short Rate Tree with Min/Max Paths (Log Scale)');
grid on;
hold off;

%% MBS Part (ii) b): Value a 30-year mortgage backed security 
mortgageRate=0.07; %continuous compounding 
amortizationYears=30; 
OlbZero=100000000;%100,000,000 

% Calculate monthly rate 
monthlyRate=(exp(mortgageRate/12)-1); 

% Convert continuous compounding to monthly rate 
monthlyPayment=OlbZero*(monthlyRate*(1+monthlyRate)^(amortizationYears*12))/((1+monthlyRate)^(amortizationYears*12)-1); 
paymentsVector=ones(amortizationYears*12,1).*monthlyPayment; emptyVector=NaN(amortizationYears*12,1); 

% Create table for mortgage payments over time 
mortgage=table(paymentsVector, emptyVector, emptyVector, emptyVector, VariableNames={'payment','outstandingOLB','interest', 'principal'});

% Fill table for month 1 
mortgage.interest(1)=OlbZero*monthlyRate; 
mortgage.principal(1)=mortgage.payment(1)-mortgage.interest(1); 
mortgage.outstandingOLB(1)=OlbZero-mortgage.principal(1); 

% Fill in for all other months 
for i=2:amortizationYears*12 
    mortgage.interest(i) = mortgage.outstandingOLB(i-1) * monthlyRate; 
    mortgage.principal(i) = mortgage.payment(i) - mortgage.interest(i); 
    mortgage.outstandingOLB(i) = mortgage.outstandingOLB(i-1)-mortgage.principal(i); 
end

%% Values for mortgages with the initial shortTree
output=mortgageValue(amortizationYears,monthlyPayment,mortgage,shortTree,dt);
display('==================================================================')
display('Outputs for the mortgage with the initial short tree:')
display(' ')
display(['The monthly rate based on the continuous compounding rate of ', num2str(mortgageRate), ' is ', num2str(monthlyRate),'.'])
display(['The monthly payment for the mortgage with OLB0 is ', num2str(monthlyPayment),'.'])
display(['The mortgage value without prepayment is ', num2str(output(1)),' and the mortgage value with prepayment is ',num2str(output(2)), ', so the option value is ',num2str(output(1)-output(2)),'.'])
display('==================================================================')
%% Values for range of shifted shortTrees
TreeMultiplierVector = (0.1:0.02:2)';
n = numel(TreeMultiplierVector);
interestDependentValues = table(TreeMultiplierVector, nan(n,1), nan(n,1), nan(n,1),nan(n,1),nan(n,1),nan(n,1),nan(n,1),'VariableNames', {'TreeMultiplier','shortRateTreeStartingRate','valueNoPrepayment','valueWithPrepayment','durationNoPrepayment','durationWithPrepayment','convexityNoPrepayment','convexityWithPrepayment'});

for k = 1:n
    multiplier = interestDependentValues.TreeMultiplier(k);
    % calculate shifted tree
    shiftedTree = shortTree .* multiplier;
    % store starting short rate for this shifted tree
    interestDependentValues.shortRateTreeStartingRate(k) = shortTree(1,1) * multiplier;
    % evaluate mortgage values for the shifted tree
    shiftedTreeValues = mortgageValue(amortizationYears, monthlyPayment, mortgage, shiftedTree, dt);
    interestDependentValues.valueNoPrepayment(k)   = shiftedTreeValues(1);
    interestDependentValues.valueWithPrepayment(k) = shiftedTreeValues(2);
    
    %calculate duration and convexity
    ru=shiftedTree(2,2);
    rd=shiftedTree(2,1);
    ruu=shiftedTree(3,3);
    rud=shiftedTree(3,2);
    rdd=shiftedTree(3,1);
    puNo=shiftedTreeValues(3);
    pdNo=shiftedTreeValues(4);
    puuNo=shiftedTreeValues(5);
    pudNo=shiftedTreeValues(6);
    pddNo=shiftedTreeValues(7);
    puWith=shiftedTreeValues(8);
    pdWith=shiftedTreeValues(9);
    puuWith=shiftedTreeValues(10);
    pudWith=shiftedTreeValues(11);
    pddWith=shiftedTreeValues(12);

    interestDependentValues.durationNoPrepayment(k)=-1/shiftedTreeValues(1)*((puNo-pdNo)/(ru-rd));
    DuNo=-1/puNo*((puuNo-pudNo)/(ruu-rud));
    DdNo=-1/pdNo*((pudNo-pddNo)/(rud-rdd));
    interestDependentValues.convexityNoPrepayment(k)=interestDependentValues.durationNoPrepayment(k)^2-((DuNo-DdNo)/(ru-rd));
    % same for with prepayment mortgage
    interestDependentValues.durationWithPrepayment(k)=-1/shiftedTreeValues(1)*((puWith-pdWith)/(ru-rd));
    DuWith=-1/puWith*((puuWith-pudWith)/(ruu-rud));
    DdWith=-1/pdWith*((pudWith-pddWith)/(rud-rdd));
    interestDependentValues.convexityWithPrepayment(k)=interestDependentValues.durationWithPrepayment(k)^2-((DuWith-DdWith)/(ru-rd));
    
end

%% Plot value, duration, and convexity against starting short rate

figure;

% --- Plot 1: Value ---
subplot(1,3,1);
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.valueNoPrepayment, '-', 'LineWidth', 1.5); 
hold on;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.valueWithPrepayment, '-', 'LineWidth', 1.5);
grid on;
xlabel('Starting Short Rate (r_{0,0})');
ylabel('MBS Value');
title('Value');
legend('No Prepayment','With Prepayment','Location','best');


% --- Plot 2: Duration ---
subplot(1,3,2);
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.durationNoPrepayment, '-', 'LineWidth', 1.5);
hold on;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.durationWithPrepayment, '-', 'LineWidth', 1.5);
grid on;
xlabel('Starting Short Rate (r_{0,0})');
ylabel('Duration');
title('Duration');
legend('No Prepayment','With Prepayment','Location','best');


% --- Plot 3: Convexity ---
subplot(1,3,3);
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.convexityNoPrepayment, '-', 'LineWidth', 1.5);
hold on;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.convexityWithPrepayment, '-', 'LineWidth', 1.5);
grid on;
xlabel('Starting Short Rate (r_{0,0})');
ylabel('Convexity');
title('Convexity');
legend('No Prepayment','With Prepayment','Location','best');

%% Functions

function [out] = bondTree(params,t,dt,shortTree)

%bondTree function:
%   builds a bond tree for given shorttree

% construct the vector from params for the short tree start guesses
shortRow=NaN(1,t+1);
for i=1:t
    shortRow(i)=params(1)*exp(2*(i-1)*params(2)*sqrt(dt));
end



% construct empty tree with last row all 1
bTree=NaN(t+1,t+1);
bTree(t+1,:)=1;

% complete second last row with shortTreeT data
for b=1:t 
    bTree(t,b)=(0.5*bTree(t+1,b)+0.5*bTree(t+1, b+1))*exp(-shortRow(b)*dt);
end

% complete rest of rows with shortTree data
for a=1:t-1 %row
    r=t-a;
    for b=1:r %column
        bTree(r,b)=(0.5*bTree(r+1,b)+0.5*bTree(r+1,b+1))*exp(-shortTree(r,b)*dt);
    end
end


outPrice=bTree(1,1);
highyield=-1/dt*log(bTree(2,2));
lowyield=-1/dt*log(bTree(2,1));
outVol=1/(2*sqrt(dt))*log(highyield/lowyield);
out=[outPrice,outVol];
end

function [out] = mortgageValue(amortizationYears,monthlyPayment,mortgage,shortTree, dt)

%mortgageValue function:
%   calculates the values of (non-)prepayment mortgages for given shortTree
%   and mortgage data

% Calculate value of non-prepayment mortgage
mortgageTree=NaN(amortizationYears*12, amortizationYears*12);
mortgageTree(end,:)=monthlyPayment*exp(-shortTree(end,:)*dt);
for a=1:amortizationYears*12-1
    for b=1:amortizationYears*12-1
        mortgageTree(end-a,b)=(0.5*mortgageTree(end-a+1,b)+0.5*mortgageTree(end-a+1,b+1))*exp(-shortTree(end-a,b)*dt)+monthlyPayment;
    end
end
mortgageTree(1,1)=(0.5*mortgageTree(2,1)+0.5*mortgageTree(2,2))*exp(-shortTree(1,1)*dt);
valueMortgageNoPrepayment=mortgageTree(1,1);
puNo=mortgageTree(2,2);
pdNo=mortgageTree(2,1);
puuNo=mortgageTree(3,3);
pudNo=mortgageTree(3,2);
pddNo=mortgageTree(3,1);

% Calculate value of prepayment mortgage
mortgageTreeWithPrepayment=NaN(amortizationYears*12, amortizationYears*12);
for c=1:amortizationYears*12
    mortgageTreeWithPrepayment(end,c)=min(mortgage.outstandingOLB(end),mortgageTree(end,c));
end
eend=amortizationYears*12-1;
for d=2:amortizationYears*12-1
    for e=1:eend
        mortgageTreeWithPrepayment(end-d,e)=min(mortgage.outstandingOLB(end-d),(0.5*mortgageTreeWithPrepayment(end-d+1,e)+0.5*mortgageTreeWithPrepayment(end-d+1,e+1))*exp(-shortTree(end-d,e)*dt)+monthlyPayment);
        eend=amortizationYears*12-d;
    end
end
valueMortgageWithPrepayment=mortgageTreeWithPrepayment(1,1);

puWith=mortgageTreeWithPrepayment(2,2);
pdWith=mortgageTreeWithPrepayment(2,1);
puuWith=mortgageTreeWithPrepayment(3,3);
pudWith=mortgageTreeWithPrepayment(3,2);
pddWith=mortgageTreeWithPrepayment(3,1);

out=[valueMortgageNoPrepayment,valueMortgageWithPrepayment,puNo,pdNo,puuNo,pudNo,pddNo,puWith,pdWith,puuWith,pudWith,pddWith];
end