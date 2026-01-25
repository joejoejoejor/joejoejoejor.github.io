<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fixed Income Assignment Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
        }
        h1, h2, h3 {
            color: #333;
        }
        code {
            background-color: #f4f4f4;
            padding: 2px 4px;
            border-radius: 4px;
        }
        pre {
            background-color: #f4f4f4;
            padding: 10px;
            border-radius: 4px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
    </style>
</head>
<body>
    <h1>Fixed Income Assignment Report</h1>

    <h2>Introduction</h2>
    <p>The goal of this project was to replicate the three-step BDT short-rate tree provided in the Excel example and to estimate smooth yield and volatility term structures using the Nelson–Siegel model. Both tasks involve nonlinear calibration using fminsearch() and observed market inputs. The general approach is to construct model-implied bond prices and fitted yield/volatilities to adjust model parameters until the model matches the data as closely as possible.</p>

    <h2>1a) Replicating the BDT excel example in Matlab</h2>
    <p>The idea of this subtask was to construct a short rate tree from observed bond prices and volatilities on the market using a binominal bond pricing model based on yields and volatility of rates. The model price and volatility need to match the observed data, after which we can extract the yield and volatility of the bond tree and build the short rate tree.</p>
    <p>In a first step, all parameters were set, such as timesteps and observed market data. In a second step, the short rate for the shortest timespan was calculated using a simple fminsearch for the price from which the yield, respectively the rate can be inferred.</p>
    <p>For further timespans, volatility and base rate (lowest short rate) needed to be calculated using a loop function and calibration of both parameters at the same time. This was done by constructing a placeholder bond tree with corresponding size which was induced/calculated by discounting backwards using placeholder rates for the calibration year and already set rates for the prior years. The placeholder rates were then chosen by fminsearch such that the difference to the observed market data is minimized (they should be equal). From that, the short base rate and volatility can be calculated, and the short rate tree can be completed (see visual 1 below).</p>
    
    <h3>Visual 1: resulting short rate tree</h3>
    <img src="visual1.png" alt="Resulting short rate tree">

    <h2>1b) Estimating Yield and Volatility Term Structures</h2>
    <p>The idea of this subtask was to apply the Nelson Siegel YIELD function to an incomplete (in terms of maturities) set of market yields and volatilities as a preparation to create a short rate tree from the data to value complex securities such as mortgage backed security, where changes in the short rate have a big influence on the value of the security (through prepayment option and discounting). In the first step, a squared error function was set up calculating the residual of true and fitted values of the Nelson Siegel curve using placeholder parameters. In the second step, the placeholder parameters were optimized using the fminsearch function to minimize the squared error. This was done twice, once for the yield curve and once for the volatility curve. Afterwards, the data is plotted to visualize the curves and fitted values (see visual 2 below).</p>
    <p>We see that the volatility curve fits very well while the yield curve does not seem to visually fit as well as the volatility curve. This could be overcome by using more complicated smoother functions but might also introduce overfitting.</p>

    <h3>Visual 2: fitted data table and yield/volatility curve plots</h3>
    <img src="visual2.png" alt="Fitted data table and yield/volatility curve plots">

    <h2>2a) Fit the BDT Tree</h2>
    <p>When fitting the short rate tree to our observed data, we fit it to the Nelson-Siegel interpolated estimates. We can see that the short rate tree explodes very fast as seen in visual 3 (in log-scale). However, the most extreme outcomes are very unlikely due to the tree's 360 step binominal distribution and do not impact the pricing of the MBS a lot.</p>

    <h3>Visual 3: log-scaled short rate tree</h3>
    <img src="visual3.png" alt="Log-scaled short rate tree">

    <h2>2b) Value a 30-year mortgage-backed security</h2>
    <p>To value a 30-year mortgage-backed security (in this example identical mortgages with a face value of 100M) we first need to construct a table in which all mortgage payments for the 360 periods are listed as well as their split into principal, interest and the outstanding loan balance. Based on this, two new trees are created, one without a prepayment option mortgage and one with a prepayment option mortgage. The trees contain the value of the mortgages at the timesteps under a given short rate tree. For the mortgage with a prepayment option, the option value for the lender at a given time and rate is the minimum of the continuation value at the mortgage rate and the outstanding principal in case the mortgage was being paid off at this time. This is because if the borrower can refinance the outstanding loan balance cheaper than the current mortgage (lower rate) he will pay off his mortgage and refinance it.</p>

    <h3>Visual 4: Outputs for the mortgage with the initial short tree</h3>
    <img src="visual4.png" alt="Outputs for the mortgage with the initial short tree">

    <p>The value of the mortgage was then tested under different shifted short rate tree scenarios. In particular, the Nelson-Siegel fitted tree was just scaled up or down. This is a useful scenario evaluation as it shows the difference between the two options. Assessing the value of the mortgages in visual 5, we see that the no prepayment mortgage can rise above 100% of the face value when rates are very low and the lender profits from the high interest payment on the mortgage rate. With the prepayment option, the value is never above 100% of the face value because as soon as the rate of the mortgage becomes too high, the borrower will refinance the mortgage.</p>
    <p>Duration measures the price sensitivity to an interest rate change. A duration of 5 means that when rates rise by 1%, the price of the security will fall by 5%. For the non-prepayment MBS, the curve is decreasing but positive meaning that increasing rates have a negative influence on the price/value but this effect decreases as interest rates become large. For the with-prepayment MBS the curve is 0 for a long time. This can be interpreted that if interest rates rise, the chance prepayment is during period 1 is 100%. At some point we see a slow rise of the curve meaning that there is a chance people will start prepaying during later periods (for the lower paths of the short rate tree). As the rate increases further, the interest rates are only low enough for later timesteps which makes the prepayment more unlikely. This means that the effect of the prepayment option loses its stabilizing impact on the value and the value/price strongly decreases when rates increase. As rates go higher and higher, the two durations converge.</p>
    <p>From this, we can conclude that the 'with' MBS has less risk as its duration is lower than the 'no' MBS. However, this is upside risk which we usually want. This is therefore only fair if the 'with' option is priced into the mortgage either by a fee or an adapted interest rate. If we think of the risk more of actual duration/maturity risk, the risk means that the 'with' MBS also introduces the risk as an investor to get prepaid at times when reinvesting rates are a lot down.</p>
    <p>In terms of downside risk, the 'no' option would only have more downside risk if we would have an inverted derivative on the security, for example a short position in the MBS and rates fall.</p>
    <p>Looking at the convexity, we see a downwards spike for the 'with' MBS at around 4%. This can be explained by the strong rise in duration explained above, meaning that at around 4% the security strongly reacts to interest rate changes.</p>
    
    <h3>Visual 5: value, duration and convexity of with and no prepayment MBS</h3>
    <img src="visual5.png" alt="Value, duration and convexity of with and no prepayment MBS">

    <h2>MATLAB Code</h2>
<pre><code>
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
thisPrice=observedData.price(i);
thisMaturity=observedData.m(i)

%No volatility matching for first node
thisError=@(r) (1*exp(-r*thisMaturity)-thisPrice)^2;
thisR=fminsearch(thisError,startR);
shortTree(i,1)=thisR;


%% Moving on in the tree
for i = 2:N
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
</code></pre>

</body>
</html>