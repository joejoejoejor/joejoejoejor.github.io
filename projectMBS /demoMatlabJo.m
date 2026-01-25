% for comment

1+2

% assign a variable with 
a=2;
b=1;
c=2*a+b

c=a^b

%% functions
ret=0.1
logreturn=log(1+ret)
% this is to get the continously compounded rate

% Calculate the exponential of the continuously compounded rate
expReturn = exp(logreturn)-1;

expReturn-ret<0.0000001
% note that this might be sensitive to small small differrences
% make sure to check this in a right way

%% more logical stuff

(4~=3)

(2<1|3<4)

% and & or |

%% strings

a='Hello'
b='World'
a==b
~strcmp(a,b)


%% vectors

% create row vector left right with comma
x=[1,2,3,4]
% create column vector top bottom with ;
y = [5; 6; 7; 8]
% transpose vector by using '
yt=y'

% create 1*1 matrix (sumproduct)
z=x*y

% create 4*4 matrix (matrix multiplication)
z=y*x

% create vector by doing element wise multiplication
z=x'.*y
% note that both vectors must either be row or column for this to work
% transpose one if necessary to make it work

% get size of matrix 
[n k]=size(x)

%% tables

%creating table
dataframe=table(y, y.*2, y.^4, 'VariableNames',{'idnumber', 'age', 'postcode'})
% note that you need column vector, top to bottom multiple*1 vectors

% select rows
dataframe(dataframe.idnumber>6,:)
% table(table.column and condition, select which columns)

dataframe(dataframe.age>=mean(dataframe.age),:)

%% for loop
for i = 1:10
    disp(i)
end

%% if statement
[n k]=size(dataframe)

if n>2
    print(n big)
else 
    print(n small)
end



%% exercise: for loops and logical indexing
% 1) with a for loop create a vector of normally ditributed random nummbers
% N(0,1)
% 2) with a for loop and a nested if statement, create an index variable
% called pos1 that takes on the value 1 if a random number is positive and zero
% otherwise. 
% 3) create an identical variable pos2 using neither for loop nor if
% statement

for i=1:100
    x(i)=randn(1);
end
 
x2=randn(100,1);
pos2=(x2>=0);

for i=1:100
    if x(i)>=0
        pos1(i)=1
    else
        pos1(i) = 0;
    end
end

decbase=((x')>x2);
mean(decbase)

