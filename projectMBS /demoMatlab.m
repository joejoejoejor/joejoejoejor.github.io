%%Welcome to this MATLAB tutorial.

% "%" marks the beggining of a "comment". Anything following "%"
% on a line will be ignored by MATLAB. Always comment your
% code...it's like a diary. Commenting helps others understand
% and build on your cod. It also makes it much easier for you to
% come back to your code later and recycle it for other project.

%%Introduction----
% Matlab is just a fancy calculator: Your input will be
% "evaluated" according to certain rules (Something goes in,
% something comes out.) 

%-Try entering "1+1" in the command window

% A matlab script is a place to keep a bunch of these
% "commands". Highlighting something in your script and hitting
% <F9> (<SHIFT>+F7 for Macs) is the same as entering it in your
% console. 

%Try:
1+1
1+2

% "()" groups these expressions together. Everything within
% brackets will be evaluated first. E.g.:
2*3+1
2*(3+1)

3*2^2+1-4/5



%You may mark the end of a line with ";". Lines ending in ";"
%are executed in the backgroun, but the results are not
%automatically printed to the screen. Try runing the following
%line.
2+1;1+1




%% Variables

% You may store the results into a "variable". think of a name
% and use the "assign" symbol: "="
a=1;
b=2+3;
a+b

% -Note that "=" does not mean "equals" (more on this later).
% Variable names must start with a letter. Matlab pre-assigns
% values to certain variables names such as "ans", "pi", "true",
% "i"...etc, but these could be overwritten (so use with
% caution). These pre-sets can be reset with the <clear>
% command.
pi
r=2
area=pi*r^2
pi=0
area=pi*r^2
clear % this clears all variables that have been defined so far, even those that are not predefined by matlab
r =2
area=pi*r^2


%Everything on the right hand side is evaluated before the
%assignment, so you can also do this:
a=1
a=a+1

a=a^2


%% Functions
ret=0.1;
logReturn=log(1+ret);
% log --> ln in this case

%% Type of Variables

% There are a few different things you may store in a variable:

% Boolean aka "logical"
a=true
b=false
a==b % comparison
a==true
1<2
2<1
%true has the value 1 by default...until you change it.
true=false
a==true
clear

% An expression such as (3>2) will return a boolean, which can
% be stored.
a=(3>2)
a


%More examples
(4==4)
(3~=2)
(5<6)
~false
(6>=6)
(7<=9)

(2>1&3>4) %and

(2>1|3>4) %or

% Numeric aka "double"
a=1
b=2
c=a+b
%you can coerce a boolean variable into a numeric variable. true
%is evaluated to be 1, and false is 0. E.g.:



%String
a='Hello';
b='World!';
greeting=[a ' ' b];
disp(greeting)

%string comparisons
a='Hello';
c='World';
a==c
a==a
strcmp(a,c)
strcmp(a,a)


%% Vectors and Matricese
%You may store arrays of these variables in vectors, matrices,
%or datasets

%To create a vector:
student=[1;2;3;4]
student(2)

score=[85;60;75;100]
score(4)

%to create a string vector
gender=['f';'m';'f';'m']


%to create a string array
studentName={'Alice';'Bob';'Charlie';'David'}
studentName(3)

%Access elements of a matrix, dataset, or  vector with "()"
score
score(2)


% Standard operations +,-,*,/,%% maybe used on vectors. e.g.:
x=[1,5,4,2,6,2] %a row vector
y=[2,5,1,2,3,5]
x
x

y+x

%Transpose
x'

%Matrix operation
X=x'*y
x*y'


%Element by element multiplication
c=x .* y
%here c(i)=x(i)*y(i)

%similarly
x./y


%Note that with square matrices A, B, A/B actually calculates 
% A*inv(B), and A\B calculates inv(A) * B


% Naming your variables:

% -The name should indicate the purpose of the variable -by
% convention, no spaces or punctuations, capitalize first letter
% of every word except the first -Avoids confusion and helps you
% remember your varialbes: numberOfShares is better than n1 -If
% it's not 0 or 1, you should give it a name to facilitate
% recycling your code. Working is hard. Be lazy! -It might not
% be a good idea to use names such as x1,a,b,c...etc



%% Vector Functions
a=[1 2; 3 4; 5 6];

doc size

[n k]=size(a);
n
k


%% Tables

%Tables help better organize your data
grades=table(student,studentName,score)

%Optionally, you may rename the columns
grades=table(student,studentName,gender,score,'VariableNames',{'studentID','name','gender','score'})


%You can access, change, or add columns with "." or "()"
grades.name(2)
grades.name(2)={'Bobbie'}
grades(2,3)

%Subsetting with logical vectors:

(grades.score>80) %Tells you which rows have a score of greater than 80

%To select those rows, the 3 following lines are equivalent:
grades(grades.score>80,2)
grades(grades.score>80,'name') 
grades.name(grades.score>80)


%Alternatively... to answer "Who got and above average grade?"
mean(grades.score)
grades.name(grades.score>=mean(grades.score))
grades(grades.score>=mean(grades.score),2)

% ":" indicates that all columns should be selected
grades(grades.score>=mean(grades.score),:)

%% For loops


for i = 1:100
    test(i) = i^2;
end

%% if statements
if pi>3
    disp('yes it is');
end

%% if else statements
%% if statements
if pi>4
    disp('yes it is');
else
    disp('no it is not') 
end

%% exercise: for loops and logical indexing
% 1) with a for loop create a vector of normally ditributed random nummbers
% N(0,1)
% 2) with a for loop and a nested if statement, create an index variable
% called pos1 that takes on the value 1 if a random number is positive and zero
% otherwise. 
% 3) create an identical variable pos2 using neither for loop nor if
% statement

%% Using functions
%Sometimes as codes get more involved it is useful to create functions. The
%first kind we will discuss is where the function is embedded in a separate
%file / script. Then Matlab will give this function the same status as any
%of the built in functions.  

% Create a function called weirdfunction that returns f(x) = 3/45 * x^(4/3)

x = 1:10;
y = weirdfunction(x);


%% my comments

% cmd 'clear' clears all variables up to this point, even before the
% section
% cmd 'clearvars a b;' clears only variables a and b
% cmd 'clearvars -except c;' clears all variables except c

% comparison: > >= == <= < 
% opposite/not: ~
% and: &, or: |

% boolean : 'true'/'false', can also stored as a number 1/0

% concacenating strings a='Hello';
% a='Hello'
% b='World!'
% greeting=[a ' ' b];
% print(greeting)
% comparing strings: 'strcmp()' --> compares whole string, 'a==b' compares
% letter by letter (a and b need to have equal character length

a=[1,2,3] %bottomdown column vector
b=[4;5;6] %rightleft row vector
c=b*a