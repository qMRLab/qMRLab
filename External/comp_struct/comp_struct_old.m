function [df, match, er1, er2] = comp_struct(s1,s2,prt,pse,tol,n1,n2,wbf)
% check two structures for differances - i.e. see if strucutre s1 == structure s2
% function [match, er1, er2, erc, erv] = comp_struct(s1,s2,prt,pse,tol,n1,n2,wbf)
%
% inputs  8 - 7 optional
% s1      structure one                              class structure
% s2      structure two                              class structure - optional
% prt     print test results (0 / 1 / 2 / 3)         class integer - optional
% pse     pause flag (0 / 1 / 2)                     class integer - optional
% tol     tol default tolerance (real numbers)       class integer - optional
% n1      first structure name (variable name)       class char - optional
% n2      second structure name (variable name)      class char - optional
% wbf     waitbar flag (0 / 1) default is 1          class integer - optional
%
% outputs 4 - 4 optional
% df      mis-matched fields with contents           class cell - optional
% match   matching fields                            class cell - optional
% er1     non-matching feilds for structure one      class cell - optional
% er2     non-matching feilds for structure two      class cell - optional
%
% prt:
%	0 --> no print
%	1 --> summary
%	2 --> print erros
%	3 --> print errors and matches
% pse:
%	1 --> pause for major erros
%	2 --> pause for all errors
%
% example:	[match, er1, er2] = comp_struct(data1,data2,1,1,1e-6,'data1','data2')
% michael arant - may 27, 2013
%
% updated - aug 22, 2013
%
% hint:
% passing just one structure causes the program to copy the structure
% and compare the two.  This is an easy way to list the structure

if nargin < 1; help comp_struct; error('I / O error'); end
if nargin < 2; s2 = s1; prt = 3; end
if nargin < 3 || isempty(prt); prt = 1; end
if nargin < 4 || isempty(pse); pse = 0; elseif pse ~= 1 && prt == 0; pse = 0; end
if nargin < 5 || isempty(tol); tol = 1e-6; end
if nargin < 6 || isempty(s1); n1 = 's1'; end
if nargin < 7 || isempty(s2); n2 = 's2'; end
if nargin < 8 || isempty(wbf); wbf = 1; end
if pse > prt, pse = prt; end

% solve
[match, er1, er2] = comp_struct_loop(s1,s2,prt,pse,tol,n1,n2,wbf);

% populate the error values
eval([char(n1) ' = s1;']);
eval([char(n2) ' = s2;']);

% size outputs
ner1 = numel(er1); ner2 = numel(er2);
% check that same number of errors were listed in each cell
if ner1 ~= ner2
	error(char('Something went very wrong in capturing errors.', ...
		'If possible, please email the two structures to moarant@gmail.com'));
else
	n = ner1;
end

% populate the error list
df = cell(n,3);
% loop the error lists
for ii = 1:n
	% capture the error text list
	temp1 = er1{ii}; temp2 = er2{ii};
	
	% see if the second structure exists
	if isempty(regexp(temp2,'is missing', 'once'))
		% record text error
		df{ii,1} = temp2;
		% see if matching structure 1 is missing (struture 2 listed as unique)
		if isempty(regexp(temp2,'is unique', 'once'))
			% unique to structure 2 - record value
			junk = regexp(temp2,' ','once');
			df{ii,3} = eval(temp2(1:junk-1));
		else
			% exists in 1 and 2 - evaluate types
			junk = regexp(temp2,' ','once'); temp2(junk:end) = [];
			junk = strfind(temp2,'.'); trash = temp2(junk+1:end); temp2(junk:end) = [];
			% if trash is empty, the field is a sub structure - list sub fields
			if isempty(trash)
				df{ii,3} = eval(['fieldnames(' temp2 ')'])';
			else
				% if numel(temp2) is > 1, then this is an indexed field
				% list the number if indexes and the type
				if (numel(eval(temp2)) - 1)
					df{ii,3} = sprintf('%s(#%g).%s is class %s', ...
						temp2,numel(eval(temp2)),trash,class(eval([temp2 '.' trash])));
				else
					% list the contents of the field
					df{ii,3} = eval([temp2 '.' trash]);
				end
			end
		end
	end
	if isempty(regexp(temp1,'is missing', 'once'))
		% record text error
		df{ii,1} = temp1;
		% see if matching structure 1 is missing (struture 2 listed as unique)
		if isempty(regexp(temp1,'is unique', 'once'))
			% unique to structure 2 - record value
			junk = regexp(temp1,' ','once');
			df{ii,2} = eval([temp1(1:junk-1)]);
		else
			% exists in 1 and 2 - evaluate types
			junk = regexp(temp1,' ','once'); temp1(junk:end) = [];
			junk = strfind(temp1,'.'); trash = temp1(junk+1:end); temp1(junk:end) = [];
			% if trash is empty, the field is a sub structure - list sub fields
			if isempty(trash)
				df{ii,2} = eval(['fieldnames(' temp1 ')'])';
			else
				% if numel(temp2) is > 1, then this is an indexed field
				% list the number if indexes and the type
				if (numel(eval(temp1)) - 1)
					df{ii,2} = sprintf('%s(#%g).%s is class %s', ...
						temp1,numel(eval(temp1)),trash,class(eval([temp1 '.' trash])));
				else
					% list the contents of the field
					df{ii,2} = eval([temp1 '.' trash]);
				end
			end
		end
	end
end

% optional text output
if prt
	fprintf('\n Error table\n');
	for ii = 1:n
		fprintf('\n%s    \n',df{ii,1});
		fprintf('Structure 1:  ');
		if isempty(df{ii,2}); fprintf('\n'); else; disp(df{ii,2}); end
		fprintf('Structure 2:  ');
		if isempty(df{ii,3}); fprintf('\n'); else; disp(df{ii,3}); end	
	end
	fprintf('\n\n\n\n\n');
end



%% recursive loop
function [match, er1, er2] = comp_struct_loop(s1,s2,prt,pse,tol,n1,n2,wbf)

% init outputs
match = {}; er1 = {}; er2 = {}; 

% test to see if both are structures
if isstruct(s1) && isstruct(s2)
	% both structures - get the field names for each structure
	fn1 = fieldnames(s1);
	fn2 = fieldnames(s2);
	% missing fields? get the common fields
	temp1 = ismember(fn1,fn2);
	temp2 = ismember(fn2,fn1);
	% missing fields in set 1
	for ii = find(~temp2)'
		er1{end+1} = sprintf('%s is missing field %s',n1,fn2{ii});
		er2{end+1} = sprintf('%s.%s is unique',n2,fn2{ii});
% 		er2{end+1} = s2.(fn2{ii});
		if prt > 1; fprintf('%s\n',er1{end}); end; if pse; pause; end
	end
	% missing fields in set 2
	for ii = find(~temp1)'
		er2{end+1} = sprintf('%s is missing field %s',n2,fn1{ii});
		er1{end+1} = sprintf('%s.%s is unique',n1,fn1{ii});
% 		er1{end+1} = s1.(fn1{ii});
		if prt > 1; fprintf('%s\n',er2{end}); end; if pse; pause; end
	end
	% index sizes match?  i.e. do both structures have the same # of indexes?
	inda = numel(s1); indb = numel(s2); inder = inda-indb;
	if inder < 0
		% struct 1 is smaller
		for ii = inda+1:indb
			er1{end+1} = sprintf('%s(%g) is missing',n1,ii);
			er2{end+1} = sprintf('%s(%g) is unique',n2,ii);
			if prt > 1; fprintf('%s\n',er1{end}); end; if pse; pause; end
		end
	elseif inder > 0
		% index 2 is smaller
		for ii = indb+1:inda
			er2{end+1} = sprintf('%s(%g) is missing',n2,ii);
			er1{end+1} = sprintf('%s(%g) is unique',n1,ii);
			if prt > 1; fprintf('%s\n',er2{end}); end; if pse; pause; end
		end
	end
	% get common fields
	fn = fn1(temp1); fnn = numel(fn); 
	% loop through structure 1 and match to structure 2
	ind = min([inda indb]); cnt = 0; 
	if wbf; wb = waitbar(0,'Comparing ....'); end
	for ii = 1:ind
		% loop each index
		for jj = 1:fnn
			% loop common field names
			if wbf; cnt = cnt + 1; waitbar(cnt/(ind*fnn),wb); drawnow; end
			% add index and field name to the structure name
			n1p = sprintf('%s(%g).%s',n1,ii,fn{jj});
			n2p = sprintf('%s(%g).%s',n2,ii,fn{jj});
			% recurse - run the program again on the sub-set of the structure
			[m e1 e2] = comp_struct_loop(s1(ii).(fn{jj}),s2(ii).(fn{jj}),prt,pse, ...
				tol,n1p,n2p,wbf);
			% add the sub-set (field name) results to the total results
			match = [match m']; 
			if ~isempty(e1) || ~isempty(e2)
				er1 = [er1 e1']; er2 = [er2 e2'];
			end
		end
	end
	if wbf;	close(wb); end
else
	% both are non-structures - compare
	% get the varable class and test
	c1 = class(s1); c2 = class(s2);
	if strcmp(c1,c2);
		% both are the same class
		if isequal(s1,s2)
			% results are equal
			match{end+1} = sprintf('%s and %s match',n1,n2);
			if prt == 3; fprintf('%s\n',match{end}); end
		else
			% same class but not equal
			% calculate error if type is single or double
			% test for function type match if function handle
			switch c1
				case {'single', 'double'}, 
					if numel(s1) ~= numel(s2) || size(s1,1) ~= size(s2,1)
						er = 1;
					else
						er = norm(s1-s2);
					end
				case {'function_handle'},
					s1f = functions(s1); s2f = functions(s2);
					if strcmp(s1f.function,s2f.function)
						% same function with different values - record deviation and exit
						er = 0;
						er1{end+1} = sprintf('%s and %s are both %s but have different values', ...
							n1,n2,char(s1));
						er2{end+1} = er1{end};
						if prt > 1; fprintf('%s\n',er1{end}); end;
						if pse > 1; pause; end
					else
						er = 1;
					end
				otherwise, er = 1;
			end
			% test error - error will be 0 (no error) or 1 (error) for all
			% classes except double and single.  double and single are the 
			% actual error which is tested against the tolerance
			% this was done for cases where structures are run on different 
			% platforms and numerical precision errors are observed
			if er > tol
				% sets do not match
				er1{end+1} = sprintf('%s and %s do not match',n1,n2);
				er2{end+1} = sprintf('%s and %s do not match',n2,n1);
				if prt > 1; fprintf('%s\n',er1{end}); end;
				if pse > 1; pause; end
			else
				% sets are a tolerance match
				match{end+1} = sprintf('%s and %s are tolerance match',n1,n2);
				if prt > 2; fprintf('%s\n',match{end}); end
			end
		end
	else
		% fields are different classes
		er1{end+1} = sprintf('%s is class %s, %s is class %s',n1,c1,n2,c2);
		er2{end+1} = sprintf('%s is class %s, %s is class %s',n2,c2,n1,c1);
		if prt > 1; fprintf('%s\n',er1{end}); end
		if pse; pause; end
	end
end

% transpose outputs
match = match'; er1 = er1'; er2 = er2';
