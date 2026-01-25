function [historicReturn] = getMomentum(thisPermno, thisYear, thisMonth, crsp)

%getMomentum function:
%   Gets the return from a year ago up to a month ago

% get the multiplier date
thisMultiplierDate = thisMonth + thisYear*12;

% Filter for PERMNO
crspFiltered = crsp(crsp.PERMNO==thisPermno,:);

% get multiplier date column
crspFiltered.multiplierDate = crspFiltered.month + crspFiltered.year*12;

% calculate start and end price
startPrice = crspFiltered.adjustedPrice(crspFiltered.multiplierDate == thisMultiplierDate-12);
endPrice   = crspFiltered.adjustedPrice(crspFiltered.multiplierDate == thisMultiplierDate-1);

% Ensure startPrice and endPrice are valid
if isempty(startPrice) || isempty(endPrice) || isnan(startPrice) || isnan(endPrice)
    historicReturn = NaN;
else
    historicReturn = (endPrice / startPrice) - 1;
end

end
