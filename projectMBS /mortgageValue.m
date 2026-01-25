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