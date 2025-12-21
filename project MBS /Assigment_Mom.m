%% 1 – Import data

% readtable
%crsp=readtable('testData.csv');
crsp=readtable('crsp20042008.csv');

%% 2 – Add datenum, year and month

% add crsp.datenum
crsp.datenum = datenum(num2str(crsp.DateOfObservation), 'yyyymmdd');
crsp.year = year(crsp.datenum);
crsp.month = month(crsp.datenum);

%% 3 – Write functions for momentum

% see function file getMomentum

%% 4 – Calculate momentum

for i = 1:height(crsp)
    crsp.momentum(i)=getMomentum(crsp.PERMNO(i), crsp.year(i), crsp.month(i), crsp);
end

%% 5 – Calculate momentum returns

% Initialize containers
uDates=unique(crsp.DateOfObservation);
mom1=zeros(length(uDates),1);
mom10=zeros(length(uDates),1);
momentum = table(uDates, mom1, mom10, ...
    'VariableNames', {'DateOfObservation', 'mom1','mom10'});

% Loop over each unique date
for k = 1:length(uDates)
    currentDate = uDates(k);
    
    % Subset CRSP for that date
    crsp2 = crsp(crsp.DateOfObservation == currentDate, :);

    % Compute decile cutoffs
    q1  = quantile(crsp2.momentum, 0.1);
    q10 = quantile(crsp2.momentum, 0.9);

    % Compute bottom/top decile means
    if isnan(mean(crsp2.Returns(crsp2.momentum<=q1)));
        momentum.mom1(k)=0;
    else 
        momentum.mom1(k)=mean(crsp2.Returns(crsp2.momentum<=q1));
    end

    if isnan(mean(crsp2.Returns(crsp2.momentum>=q10)));
        momentum.mom10(k)=0;
    else 
        momentum.mom10(k)=mean(crsp2.Returns(crsp2.momentum>=q10));
    end
end

momentum.mom=momentum.mom10-momentum.mom1;


%% 6 – Calculate cumulative momentum returns

momentum.cumulativeRetMom1=cumprod(momentum.mom1+1);
momentum.cumulativeRetMom10=cumprod(momentum.mom10+1);
momentum.cumulativeRetMom=cumprod(momentum.mom+1);
