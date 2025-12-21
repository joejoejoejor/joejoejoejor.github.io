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