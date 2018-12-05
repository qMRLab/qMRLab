function out=range_intersection(first,second)
% Purpose: Range/interval intersection
%
% A and B two ranges of closed intervals written 
% as vectors [lowerbound1 upperbound1 lowerbound2 upperbound2] 
% or as matrix [lowerbound1, lowerbound2, lowerboundn; 
%               upperbound1, upperbound2, upperboundn]
% A and B have to be sorted in ascending order
%
% out is the mathematical intersection A n B
%
%
% EXAMPLE USAGE:
%   >> out=range_intersection([1 3 5 9],[2 9])
%   	out =  [2 3 5 9]
%   >> out=range_intersection([40 44 55 58], [42 49 50 52])
%   	out =  [42 44]
%
% Author: Xavier Beudaert <xavier.beudaert@gmail.com>
% Original: 10-June-2011
% Major modification and bug fixing 30-May-2012
% Allocate, as we don't know yet the size, we assume the largest case
out1(1:(numel(second)+(numel(first)-2)))=0;
k=1;
while isempty(first)==0 && isempty(second)==0
    % make sure that first is ahead second
    if first(1)>second(1)        
        temp=second;
        second=first;
        first=temp;
    end
    if first(2)<second(1)
        first=first(3:end);
        continue;
    elseif first(2)==second(1)
        out1(k)=second(1);
        out1(k+1)=second(1);
        k=k+2;
        
        first=first(3:end);
        continue;
    else        
        if first(2)==second(2)        
            out1(k)=second(1);
            out1(k+1)=second(2);
            k=k+2; 
            
            first=first(3:end);
            second=second(3:end);
                
        elseif first(2)<second(2)
            out1(k)=second(1);
            out1(k+1)=first(2);
            k=k+2;
            
            first=first(3:end);
        else
            out1(k)=second(1);
            out1(k+1)=second(2);
            k=k+2;
            
            second=second(3:end);
        end
    end
end
% Remove the tails
out=out1(1:k-1);
