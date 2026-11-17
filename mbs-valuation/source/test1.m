%% Quantitative Finance: MBS Valuation using Nelson-Siegel & BDT Tree
%
% *Project Overview*
%
% The goal of this project is to estimate smooth yield and volatility term structures 
% using the Nelson–Siegel model and to replicate a Black-Derman-Toy (BDT) short-rate tree. 
% Finally, these models are used to value a Mortgage-Backed Security (MBS) with and without 
% prepayment options.
%
% Both tasks involve nonlinear calibration using |fminsearch()| and observed market inputs. 
% The general approach is to construct model-implied bond prices and fitted yield/volatilities 
% to adjust model parameters until the model matches the data as closely as possible.


%% 1. Estimating Yield and Volatility Term Structures (Nelson-Siegel)
% The idea of this subtask is to apply the Nelson-Siegel function to an incomplete 
% (in terms of maturities) set of market yields and volatilities. This prepares the data 
% needed to create a short rate tree.
%
% The Nelson-Siegel model defines the yield curve $y(\tau)$ as:
% 
% $y(\tau) = \beta_0 + \beta_1 \left( \frac{1-e^{-\lambda \tau}}{\lambda \tau} \right) + \beta_2 \left( \frac{1-e^{-\lambda \tau}}{\lambda \tau} - e^{-\lambda \tau} \right)$
%
% *Interpretation:*
% In the first step, a squared error function was set up to calculate the residual of true 
% and fitted values. We optimize the parameters $\beta_0, \beta_1, \beta_2, \lambda$ 
% to minimize this error for both Yield and Volatility.

% --- Import Data ---
% par vector contains: beta0, beta1, beta2, and tau (lambda)
yieldData = readtable('yieldAndVolatility2000.csv');

% --- Optimization Setup ---
startPar = [1, 1, 1, 1]; 

% Error functions (Squared Error)
errorNelsonSiegelYield = @(par) (sum((yieldData.y - ( ...
    par(1) + ...
    (par(2)+par(3)).*(1-exp(-yieldData.m./par(4)))./(yieldData.m./par(4)) - ...
    par(3).*exp(-yieldData.m./par(4)) ...
    )).^2));

errorNelsonSiegelVol = @(par) (sum((yieldData.vol - ( ...
    par(1) + ...
    (par(2)+par(3)).*(1-exp(-yieldData.m./par(4)))./(yieldData.m./par(4)) - ...
    par(3).*exp(-yieldData.m./par(4)) ...
    )).^2));

% Run optimization
options = optimset('Display', 'off'); % Suppress fminsearch output
[parMinYield, ~] = fminsearch(errorNelsonSiegelYield, startPar, options);
[parMinVol, ~]   = fminsearch(errorNelsonSiegelVol, startPar, options);

% --- Fit Results ---
fittedFunctionYield = @(m) ( ...
    parMinYield(1) + ...
    (parMinYield(2)+parMinYield(3)).*(1-exp(-m./parMinYield(4)))./(m./parMinYield(4)) - ...
    parMinYield(3).*exp(-m./parMinYield(4)) ...
    );

fittedFunctionVol = @(m) ( ...
    parMinVol(1) + ...
    (parMinVol(2)+parMinVol(3)).*(1-exp(-m./parMinVol(4)))./(m./parMinVol(4)) - ...
    parMinVol(3).*exp(-m./parMinVol(4)) ...
    );

% Generate smooth curves for 30 years (360 months)
month = (1:360)';
m_smooth = month./12; 
nelsonSiegelYields = fittedFunctionYield(m_smooth);
nelsonSiegelVols = fittedFunctionVol(m_smooth);

% Store fitted data
fittedData = table(month, m_smooth, nelsonSiegelYields, nelsonSiegelVols, ...
    'VariableNames', {'Month','Maturity','nelsonSiegelYield','nelsonSiegelVol'});

% Add fitted points to original data for comparison
yieldData.nelsonSiegelYield = fittedFunctionYield(yieldData.m);
yieldData.nelsonSiegelVol = fittedFunctionVol(yieldData.m);

% --- Visualization ---
figure('Position', [100, 100, 800, 600]);
subplot(2,1,1)
plot(yieldData.m, yieldData.y, 'ko', 'MarkerFaceColor', 'k'); hold on;
plot(m_smooth, nelsonSiegelYields, 'b-', 'LineWidth', 1.5);
title('Yield Curve Calibration');
legend('Observed Yields','Nelson-Siegel Fit','Location','best');
grid on; xlabel('Maturity (Years)'); ylabel('Yield');

subplot(2,1,2)
plot(yieldData.m, yieldData.vol, 'ko', 'MarkerFaceColor', 'k'); hold on;
plot(m_smooth, nelsonSiegelVols, 'r-', 'LineWidth', 1.5);
title('Volatility Curve Calibration');
legend('Observed Vols','Nelson-Siegel Fit','Location','best');
grid on; xlabel('Maturity (Years)'); ylabel('Volatility');

% *Observation:*
% We see that the volatility curve fits very well, while the yield curve shows some deviations. 
% This is a trade-off: using more complex functions could improve the fit but might introduce overfitting.

%% 2. Calibrating the BDT Short Rate Tree
% The goal is to construct a 360-step short rate tree consistent with the smoothed market data.
% We use a binomial bond pricing model where model price and volatility must match the 
% Nelson-Siegel inputs.
%
% *Calibration Logic:*
% 1. *First Node:* Solved using a simple search to match the short-term bond price.
% 2. *Subsequent Nodes:* We calibrate the base rate ($r_{d}$) and volatility parameter ($\sigma$)
% simultaneously. We construct a helper tree to find parameters such that the model price 
% matches the market price.

% --- Tree Initialization ---
T = fittedData.Maturity(end);
N = fittedData.Month(end);
dt = T/N;
m_vec = (dt:dt:T)';

% Prepare target data from NS-Fit
observedData = table(m_vec);
observedData.price = exp(-fittedData.nelsonSiegelYield .* fittedData.Maturity);
observedData.volatility = fittedData.nelsonSiegelVol;

% Initialize Tree (NaNs)
shortTree = NaN(N,N);

% --- Step 1: First Node Calibration ---
i = 1;
thisPrice = observedData.price(i);
thisMaturity = m_vec(i);
startR = 0.05;

% Objective: Match Zero Coupon Bond Price: P = exp(-r * dt)
thisError = @(r) (exp(-r * dt) - thisPrice)^2;
thisR = fminsearch(thisError, startR, options);
shortTree(i,1) = thisR;

% --- Step 2: Forward Induction Loop ---
startParam = [0.05, 0.1]; % Initial guess for [rate, sigma]
thisParam = startParam;

for i = 2:N
    thisPrice = observedData.price(i);
    thisVolatility = observedData.volatility(i);
    target = [thisPrice, thisVolatility];
    
    % Optimization to find [r_base, sigma] for this time step
    calibError = @(p) sum((target - bondTree(p, i, dt, shortTree)).^2);
    
    thisParam = fminsearch(calibError, thisParam, options);
    
    % Populate the tree at step i
    thisBottomR = thisParam(1);
    thisSigma = thisParam(2);
    
    % BDT relationship: r_{i,j} = r_{i,1} * exp(2 * sigma * (j-1) * sqrt(dt))
    % (Note: Simplified BDT often uses this log-normal spacing)
    for j = 1:i
        shortTree(i,j) = thisBottomR * exp(2 * (j-1) * thisSigma * sqrt(dt));
    end
end

% --- Visualization: The Short Rate Tree ---
figure('Position', [100, 100, 800, 500]);
hold on;
minRates = min(shortTree, [], 2, 'omitnan');
maxRates = max(shortTree, [], 2, 'omitnan');

% Shade the range
x_fill = 1:N;
fill([x_fill fliplr(x_fill)], [minRates' fliplr(maxRates')], ...
     [0.9, 0.9, 0.95], 'EdgeColor','none');

% Plot bounds
plot(1:N, minRates, 'b-', 'LineWidth', 1.5);
plot(1:N, maxRates, 'r-', 'LineWidth', 1.5);

set(gca, 'YScale', 'log');
xlabel('Time Step (Months)'); ylabel('Short Rate (Log Scale)');
title('Calibrated BDT Short Rate Tree (Log Scale)');
legend('Tree Range', 'Min Path', 'Max Path', 'Location', 'best');
grid on; hold off;

% *Observation:*
% As seen in the log-scale plot, the tree expands significantly. 
% The most extreme outcomes (high interest rate and rate basically zero) are theoretically possible 
% but statistically unlikely given the binomial distribution.

%% 3. Valuing a 30-Year Mortgage-Backed Security (MBS)
% We now value a mortgage with a face value of 100M. 
%
% * *No Prepayment:* The mortgages are without the option for prepayment. 
% The cash flows are fixed. The value can exceed the OLB at time zero (100M) 
% if rates drop, as the lender locks in high interest payments.
% * *With Prepayment:* The borrower has the option for prepayment and therewith refinancing if rates drop. 
% The value of the mortgage to the lender is capped because the borrower will pay 
% off the loan when it is advantageous to them.
%
% $$V_{prepay}(t) = \min( V_{continuation}, Principal_{outstanding})$$


% --- Mortgage Specs ---
mortgageRate = 0.07; % continuous
amortizationYears = 30;
OlbZero = 100e6; 

% Monthly Payment Calculation
monthlyRate = exp(mortgageRate/12) - 1; 
n_payments = amortizationYears * 12;
monthlyPayment = OlbZero * (monthlyRate * (1+monthlyRate)^n_payments) / ...
                 ((1+monthlyRate)^n_payments - 1);

% Generate Amortization Schedule
paymentsVector = ones(n_payments, 1) * monthlyPayment;
mortgage = table(paymentsVector, NaN(n_payments,1), NaN(n_payments,1), NaN(n_payments,1), ...
    'VariableNames', {'payment','outstandingOLB','interest', 'principal'});

% Initial period
mortgage.interest(1) = OlbZero * monthlyRate;
mortgage.principal(1) = mortgage.payment(1) - mortgage.interest(1);
mortgage.outstandingOLB(1) = OlbZero - mortgage.principal(1);

% Subsequent periods
for i = 2:n_payments
    mortgage.interest(i) = mortgage.outstandingOLB(i-1) * monthlyRate;
    mortgage.principal(i) = mortgage.payment(i) - mortgage.interest(i);
    mortgage.outstandingOLB(i) = mortgage.outstandingOLB(i-1) - mortgage.principal(i);
end

% --- Valuation ---
output = mortgageValue(amortizationYears, monthlyPayment, mortgage, shortTree, dt);
val_NoPrepay = output(1);
val_WithPrepay = output(2);
optionValue = val_NoPrepay - val_WithPrepay;

% Display Results
fprintf('<strong>MBS Valuation Results:</strong>\n');
fprintf('Monthly Payment: $%.2f\n', monthlyPayment);
fprintf('Value (No Prepayment):   $%.2f\n', val_NoPrepay);
fprintf('Value (With Prepayment): $%.2f\n', val_WithPrepay);
fprintf('Value of Prepayment Option: $%.2f\n', optionValue);

%% 4. Duration and Convexity Analysis
% To understand risk, we shift the entire short rate tree up and down (by scaling it) 
% and observe how the MBS price changes.
%
% * *Duration:* Sensitivity of price to rate changes.
% * *Convexity:* Rate of change of duration.
%
% We interpret the results as follows:
% * *No Prepayment:* Behaves like a standard bond (positive duration, positive convexity).
% * *With Prepayment:* Exhibits *negative convexity* in certain regions. As rates fall, 
% price appreciation is limited (price compression) due to prepayment risk.

% Values for range of shifted shortTrees
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

figure('Position',[100 100 1400 400]);

tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

% --- Plot 1: Value ---
nexttile;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.valueNoPrepayment, 'b-', 'LineWidth', 1.8);
hold on;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.valueWithPrepayment, 'r-', 'LineWidth', 1.8);
grid on;
xlabel('Starting Short Rate (r_{0,0})');
ylabel('MBS Value');
title('Value');
legend('No Prepayment','With Prepayment','Location','best');

% --- Plot 2: Duration ---
nexttile;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.durationNoPrepayment, 'b-', 'LineWidth', 1.8);
hold on;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.durationWithPrepayment, 'r-', 'LineWidth', 1.8);
grid on;
xlabel('Starting Short Rate (r_{0,0})');
ylabel('Duration');
title('Duration');
legend('No Prepayment','With Prepayment','Location','best');

% --- Plot 3: Convexity ---
nexttile;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.convexityNoPrepayment, 'b-', 'LineWidth', 1.8);
hold on;
plot(interestDependentValues.shortRateTreeStartingRate, ...
     interestDependentValues.convexityWithPrepayment, 'r-', 'LineWidth', 1.8);
grid on;
xlabel('Starting Short Rate (r_{0,0})');
ylabel('Convexity');
title('Convexity');
legend('No Prepayment','With Prepayment','Location','best');




%% Summary of Findings
%
% A central result of the MBS valuation is the distinctly different interest rate sensitivity of securities with and without a prepayment option. 
% The most prominent feature of the MBS with prepayment is negative convexity as interest rates decline. 
% When rates fall, borrowers have an incentive to refinance, which caps the upside potential of the security from the lender's perspective. 
% Unlike a non-callable bond, whose price continues to rise as discount rates decrease, the value of a prepayable mortgage is bounded above by the outstanding principal. 
% As a result, price appreciation slows and convexity turns negative in low-rate environments.
%
% A second important observation is the convergence of risk measures at high interest rate levels. 
% As interest rates rise, prepayment becomes increasingly unlikely, rendering the embedded option effectively irrelevant. 
% In this regime, the MBS with prepayment behaves similarly to the non-prepayable MBS, and both duration and convexity converge. 
% This highlights the state-dependent nature of prepayment risk, which is most relevant in low to intermediate interest rate environments.
%
% The duration profiles further illustrate this asymmetry. 
% The non-prepayable MBS exhibits a positive but decreasing duration, reflecting diminishing sensitivity as rates rise. 
% In contrast, the duration of the prepayable MBS remains close to zero over a wide range of rising interest rates, indicating a high probability of early prepayment in favorable refinancing scenarios. 
% Only at sufficiently high rates does duration begin to increase again, as prepayment is delayed or becomes unlikely. 
% As rates rise further, the stabilizing effect of the prepayment option diminishes and the duration of both securities converges.
%
% From a risk perspective, the lower duration of the prepayable MBS reflects reduced upside potential rather than protection against downside risk. 
% Investors forgo price appreciation in falling-rate environments and face reinvestment risk when prepayments occur, as principal must be reinvested at lower prevailing yields. 
% This loss of upside should be compensated through higher mortgage rates or explicit option pricing.
%
% The convexity results support this interpretation. 
% The pronounced downward spike in convexity for the prepayable MBS at intermediate interest rates reflects a region where duration changes rapidly. 
% Small interest rate movements in this range significantly affect borrower behavior and expected cash flows, leading to heightened price sensitivity. 
% This behavior is characteristic of mortgage-backed securities and distinguishes them from standard fixed-income instruments.

%% Model Limitations and Possible Enhancements
% While the analysis captures the core economic mechanisms, several extensions could improve realism:
% 
% # *Short-rate dynamics* 
% The calibrated short-rate tree may generate extremely low or negative rates. 
% In practice, negative rates are often constrained or behave differently. 
% This could be addressed by imposing a lower bound or by using alternative models such as shifted Hull–White or shadow-rate frameworks.
% # *Prepayment behavior*
% Prepayment is modeled as fully rational and instantaneous. 
% Empirical evidence suggests that borrower behavior is often delayed or suboptimal due to transaction costs, credit constraints, and behavioral frictions. 
% More realistic approaches use stochastic prepayment intensities or hazard-rate models that depend on interest rates, seasoning, and burnout effects (e.g., Stanton, 1995).
% # *Yield curve modeling*
% The Nelson–Siegel model provides a parsimonious and smooth approximation of yields and volatilities, making it suitable for this application. 
% However, it may lack flexibility in capturing complex curve shapes. 
% Extensions such as the Nelson–Siegel–Svensson model or spline-based methods could improve fit quality at the cost of additional complexity.

%% Helper Functions
% These functions are used for calibration and valuation.

function [out] = bondTree(params, t, dt, shortTree)
    % Builds a temporary bond tree to calibrate parameters at time t
    % params: [base_rate, sigma]
    
    r_base = params(1);
    sigma = params(2);
    
    % Construct rates for the current time step t
    currentRates = NaN(t, 1);
    for j = 1:t
        currentRates(j) = r_base * exp(2 * (j-1) * sigma * sqrt(dt));
    end
    
    % Initialize Bond Tree at maturity (t+1)
    % Value is 1 at maturity
    bTree = NaN(t+1, t+1);
    bTree(t+1, :) = 1;
    
    % Backward induction for ONE step (from t+1 to t)
    % We are pricing a bond that matures at t+1, seeing its price at time 0
    
    % Step t
    for b = 1:t
       bTree(t,b) = (0.5 * bTree(t+1, b) + 0.5 * bTree(t+1, b+1)) * exp(-currentRates(b) * dt);
    end
    
    % Discount back to time 0 using the EXISTING shortTree
    for step = t-1:-1:1
        for b = 1:step
             rate = shortTree(step, b);
             bTree(step, b) = (0.5 * bTree(step+1, b) + 0.5 * bTree(step+1, b+1)) * exp(-rate * dt);
        end
    end
    
    outPrice = bTree(1,1);
    
    % Calculate Implied Volatility (BDT specific metric)
    % Using yields at step 2 to infer vol
    if t >= 2
        % This is a simplified proxy for BDT volatility matching
        % Real BDT usually matches Cap prices or similar
        % Here we use the log ratio of yields at step 2 if t allows, or just return price match
        % For the loop structure in main code, we return [Price, Vol]
        
        % Note: In the user's original logic, they calculated yields at node 2 
        % derived from the bond ending at t.
        
        % Forward approximation of yields at step 2
        % Re-simulate tree forward logic if needed, but here we stick to pricing
        % To strictly follow original code's intent:
        
        highyield = -1/dt * log(bTree(2,2));
        lowyield  = -1/dt * log(bTree(2,1));
        outVol = 1/(2*sqrt(dt)) * log(highyield/lowyield);
    else
        outVol = 0;
    end
    
    out = [outPrice, outVol];
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