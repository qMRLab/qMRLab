function [A,ffn,numHeader,repChar,hl,fpos] = txt2mat(varargin)

% TXT2MAT read an ascii file and convert a data table to a matrix
%
% Syntax:
%  A = txt2mat
%  A = txt2mat(fn)
%  [A,ffn,nh,SR,hl,fpos] = txt2mat(fn [,nh,nc,fmt,SR,SX] )
%  [A, ...]              = txt2mat(fn, ... 'param', value, ...)
%  [A, ...]              = txt2mat(fn, instruct)
%
% with
%
% A     output data matrix
% ffn   full file name
% nh    number of header lines
% hl    header lines (as a string)
% fpos  file position of last character read and converted from ascii file
%
% fn    file or path name ('*' is allowed as wildcard in file name)
% nh    number of header lines
% nc    number of data columns
% fmt   format string
% SR    cell array of replacement strings  sr<i>, SR = {sr1,sr2,...}
% SX    cell array of invalid line strings sx<i>, SX = {sx1,sx2,...}
%
% 'param', value    see below for input parameter/value-pairs
%
% instruct          input struct (each field name corresponds to an input
%                   parameter name)
%
% TXT2MAT reads the ascii file <fn> and extracts the values found in a 
% data table with <nc> columns to a matrix, skipping <nh> header lines. 
% When extracting the data, <fmt> is used as format string for each line   
% (see sscanf online doc for details about the format string). 
%
% If <fn> is an existing directory, or contains an asterisk wildcard in the
% file name, or is an empty string, a file selection dialogue is displayed.
%
% Additional strings <sr1>,<sr2>,.. can be supplied within a cell array
% <SR> to perform single character substitution before the data is
% converted: each of the first n-1 characters of an <n> character string is
% replaced by the <n>-th character.
%
% A further optional input argument is a cell array <SX> containing strings
% <sx1>,<sx2>,.. that mark "bad" lines containing invalid data. If every
% line containing invalid data can be caught by the <SX>, TXT2MAT will
% speed up significantly (see EXAMPLE 3a). Any lines that are recognized to
% be invalid are completely ignored (and there is no corresponding row in
% A). 
%
% If the number of header lines <nh> or the number of data columns <nc> are
% not provided, TXT2MAT performs some automatic analysis of the file format.
% This will need the numbers in the file to be decimals (with decimal point
% or comma) and the data arrangement to be more or less regular (see also
% remark 1). 
% If <nc> is negative, TXT2MAT internally initializes the output matrix <A>
% with |<nc>| columns, but allows for expanding <A> if more numeric values
% are found in any line of the file. To this end, TXT2MAT is forced to
% switch to line by line conversion.
%
% If some lines of the data table can not be (fully) converted, the
% corresponding rows in A are padded with NaNs. 
%
% For further options and to facilitate the argument assignment, the
% param/value notation or an input struct can be used instead of the single
% argument syntax txt2mat(ffn,nh,nc,fmt,SR,SX). For usage see EXAMPLE 3a.
% The following table lists the param/value-pairs and their corresponding
% single argument, if existing:
%
%  Param-string      Value type  Example value                  single arg.
%  'NumHeaderLines'  Scalar      13                                      nh
%  'NumColumns'      Scalar      9                                       nc
%  'Format'          String      ['%d.%d.%d' repmat('%f',1,6)]          fmt
%  'ReplaceChar'     Cell        {')Rx ',';: '}                          SR    
%  'BadLineString'   Cell        {'Warng', 'Bad'}                        SX     
%  'GoodLineString'  Cell        {'2009-08-17'}                           -
%  'SelectLineFun'   FunHandle   @(lineNo) rem(lineNo,2) == 0             -
%  'ReplaceStr'      Cell        {{'True','1'},{'#NaN','#Inf','NaN'}}     -
%  'ReplaceRegExpr'  Cell        {{';\s*(?=;)','; NaN'}}                  -
%  'NumericType'     String      'single'                                 -
%  'RowRange'        2x1-vector  [2501 5000]                              -
%  'FilePos'         Scalar      0                                        -
%  'ReadMode'        String      'auto'                                   -
%  'DialogString'    String      'Now choose a log file'                  -
%  'InfoLevel'       Scalar      1                                        -
%  'MemPar'          Scalar      2^17                                     -
%
% The param/value-pairs may follow the usual arguments in any order, e.g.
% txt2mat('file.txt',13,9,'BadLineString',{'Bad'},'Format','%f'). Only the
% single file name argument must be given as the first input.
%
% Param/value-pairs with additional functionality:
%
% · 'GoodLineString': ignore all lines that do not contain at least one of
%   the strings in the cell array (line filtering analogous to
%   'BadLineString'; see EXAMPLE 3b). 
%
% · 'SelectLineFun': a single argument element-wise Boolean function that
%   is applied to the line numbers. If the function returns 'false' for a
%   certain line number, that line is skipped. Line number counting starts
%   with 1 (one) after the header lines. When using this option, the number
%   of header lines should be passed to txt2mat, too. See EXAMPLE 3c.
%
% · The 'ReplaceStr' argument works similar to the 'ReplaceChar' argument.
%   It just replaces character sequences instead of single characters. A
%   cell array containing at least one cell array of strings must be
%   provided. Such a cell array of strings consists of <n> strings, each of
%   the first <n-1> strings is replaced by the <n>-th string. For example,
%   with {{'R1a','R1b, 'S1'}, {'R2a','R2b','R2c', 'S2'}}
%   all the 'R<n>'-strings are replaced by the corresponding 'S<n>' string.
%   In general, replacing whole strings takes more time than 'ReplaceChar',
%   especially if the strings differ in size.
%   Expression replacements are performed before character replacements.
%
% · By the help of the 'ReplaceRegExpr' argument regular expressions can be
%   replaced. The usage is analogous to 'ReplaceStr'. Regular expression
%   replacements are carried out before any other replacement (see 
%   EXAMPLE 4 and EXAMPLE 5).
%
% · 'NumericType' is one of 'int8', 'int16', 'int32', 'int64', 'uint8',
%   'uint16', 'uint32', 'uint64', 'single', or 'double' (default),
%   determining the numeric class of the output matrix A. If the numeric
%   class does not support NaNs, missing elements are padded with zeros
%   instead. Reduce memory  consumption by choosing an appropriate numeric
%   class, if needed. 
% 
% · The 'RowRange' value is a sorted positive integer two element vector
%   defining an interval of data rows to be converted (header lines do not
%   count, but lines that will be recognized as invalid - see above - do). 
%   If the vector's second element exceeds the number of valid data rows in
%   the file, the data is extracted up to the end of the file. Inf is
%   allowed as second element. It may save memory and computation time if
%   only a small part of data has to be extracted from a huge text file. 
% 
% · The 'FilePos' value <fp> is a nonnegative integer scalar. <fp>
%   characters from the beginning of the file will be ignored, i.e. not be
%   read. If you run TXT2MAT with a 'RowRange' argument, you may
%   use the <fpos> output as an 'FilePos' input during the next run in
%   order to continue from where you stopped. By that you can split up the
%   conversion process e.g. when the file is too big to be read as a whole
%   (see EXAMPLE 6). 
% 
% · 'ReadMode':
%   'matrix'  Read and convert sections of multiple lines simultaneously, 
%             requiring each line to contain the same number of values.
%             Finding an improper number of values in such a section will
%             cause an error (see also remark 2).
%   'line'    Read and convert text line by line, allowing different
%             numbers of values per line (slower than 'matrix' mode).
%   'auto'    Try 'matrix' first, continue with 'line' if an error occurs
%             (default). 
%   'block'   Read and convert sections of multiple lines simultaneously
%             and fill up the data matrix regardless of how many values
%             occur in each text line (EXAMPLE 7). Only a warning is issued
%             if a section's number of values is not a multiple of the
%             number of columns of the output data matrix. This is the
%             fastest mode involving numeric conversion.
%   'char'    Do not convert into a numeric array, but return char vector
%             of the contents including omission of the header lines,
%             replacements, line filtering, and file position and row range
%             selection. Useful for reading and manipulating text files
%             with non-numeric contents, see EXAMPLE 3b.
%             With read mode 'char' the file format analysis is disabled.
%   'cell'    Same as 'char', but put each line of text into a separate
%             cell of the output, see EXAMPLE 3b.
%
% · The 'DialogString' argument provides the text shown in the title bar of
%   the file selection dialogue that may appear.
%
% · The 'InfoLevel' argument controls the verbosity of TXT2MAT's outputs in
%   the command window and the message boxes. Currently known values are: 
%   0, 1, 2 (default)
%
% · The 'MemPar' argument provides the minimum amount of characters TXT2MAT
%   will process simultaneously as an internal text section (= a set of
%   text lines). It must be a positive integer. The value does not affect
%   the outputs, but computation time and memory usage. The roughly
%   optimized default is 65536; usually there is no need to change it. 
%
% -------------------------------------------------------------------------
%
% REMARKS
%
% 1) prerequisites for the automatic file format analysis before the
%    numeric conversion (if the number of header lines and data columns is
%    not given): 
%    · header lines can be detected by either non-numeric characters or
%      a strongly deviating number of numeric items in relation to the
%      data section (<10%)
%    · tab, space, slash, comma, colon, and semicolon are accepted as
%      delimiters (e.g. "10/11/2006 08:30 1; 3.3; 0.52" is ok)
%    · after the optional line filtering and user supplied replacements
%      have been carried out, the data section must contain the delimiters
%      and the decimal numbers only (point or comma are accepted as decimal
%      character).
%    Note I: if you do not trigger the internal file format analysis, i.e.
%    you do provide both the number of header lines and the number of data
%    columns, you also have to care for an eventual decimal _comma_ and
%    non-whitespace delimiters. Such a comma can be replaced with a '.',
%    and the whitespaces can either be included into a suitable format
%    string or be replaced with whitespaces (see e.g. the 'ReplaceChar'
%    argument).
%    Note II: if only the number of header lines is given, any character
%    except '+-1234567890aAeEfFiInN.,' (signs, decimals, NaN, Inf, dot, and
%    comma) that is found during file analysis is regarded as a possible
%    separator and therefore replaced by ' ' (space).
%
% 2) In matrix mode, txt2mat checks that the format string is suitable
%    and that the number of values read from a section of the file is the
%    product of the number of text lines and the number of columns. This
%    may be true even if the number of values per line is not uniform and
%    txt2mat may be misled. So using matrix mode you should be sure that
%    all lines that can't be sorted out by a bad line marker string contain
%    the same number of values.
%
% 3) Since txt2mat.m is a comparatively large file, generating a preparsed
%    file txt2mat.p once will speed up the first call during a matlab
%    session. Set the current directory to where you saved txt2mat.m and
%    type
%    >> pcode txt2mat
%    For further information, see the 'pcode' documentation.
%
% =========================================================================
% EXAMPLE 1:        basic usage
% -------------------------------------------------------------------------
%
% A = txt2mat;      % choose a file and let TXT2MAT analyse its format
%                 
% =========================================================================
% EXAMPLE 2:        automatic file format analysis
% -------------------------------------------------------------------------
%
% Supposed your ascii file C:\mydata.log contains the following lines 
% »
% 10 11 2006 08 35.225 1  3.3  0.52
% 31 05 2008 12 12     0  0.0  0.00
%  7 01 2010 15 23.5  -1  3.3  0.535
% «
% type
%
% A = txt2mat('C:\mydata.log',0,8);
%
% or just
%
% A = txt2mat('C:\mydata.log');
%
% Below, TXT2MAT uses its automatic file layout detection as the header
% line and column number is not given. With the file looking like this:
% » 
% some example data
% plus another header line
% 10/11/2006 08:35,225 1; 3,3; 0,52
% 31/05/2008 12:12     0; 0,0; 0,00
% 7/01/2010  15:23,5  -1; 3,3; 0,535
% «
% txt2mat('C:\mydata.log') returns the same output data matrix as above.
%
% =========================================================================
% EXAMPLE 3a:     	line filtering by 'bad' markers; replacements
% -------------------------------------------------------------------------
%
% »
% ;$FILEVERSION=1.1
% ;$STARTTIME=38546.6741619815
% ;---+--   ----+----  --+--  ----+---  +  -+ -- -- -- 
%      3)         7,2  Rx         0300  8  01 A3 58 4D 
%      4)         7,3  Rx         0310  8  06 6E 2B 9F 
%      5)         9,5  Warng  FFFFFFFF  4  00 00 00 08  BUSHEAVY 
%      6)        12,9  Rx         0320  8  02 E1 F6 EF 
% «
% 
% You may specify 
% nh   = 3              % header lines, 
% nc   = 12             % data columns,
% fmt  = '%f %f %x %x %x %x %x %x'  	% as format string for floats
%                                       % and hexadecimals,  
% sr1  = ')Rx '         % as first replacement string to blank the
%                       % characters ')','R', and 'x' (if you don't want to
%                       % include them in the format string), and
% sr2  = ',.'           % to replace the decimal comma with a dot, and
% sx1  = 'Warng'        % as a marker for invalid lines
%
% A = txt2mat('C:\mydata.log', nh, nc, fmt, {sr1,sr2}, {'Warng'});
%
%   A =
% 		3    7.2    768      8      1    163     88     77
% 		4    7.3    784      8      6    110     43    159
% 		6   12.9    800      8      2    225    246    239
% 		...
% 
% If you make use of the param/value-pairs, you can also write more clearly
%
% t2mOpts = {'NumHeaderLines', 3                         , ...
%            'NumColumns'    , 12                        , ...
%            'ReplaceChar'   , {')Rx ',',.'}             , ...
%            'Format'        , '%f %f %x %x %x %x %x %x' , ...
%            'BadLineString' , {'Warng'}                    };
%        
% A = txt2mat('C:\mydata.log', t2mOpts{:});
% 
% ... or you simply use an input struct
%
% t2mIns.NumHeaderLines  = 3;
% t2mIns.NumColumns      = 12;
% t2mIns.ReplaceChar     = {')Rx ',',.'};
% t2mIns.Format          = '%f %f %x %x %x %x %x %x';
% t2mIns.BadLineString   = {'Warng'};
%        
% A = txt2mat('C:\mydata.log', t2mIns);
% 
% Without the {'Warng'} argument, A would have been
%
% 		3    7.2    768      8      1    163     88     77
% 		4    7.3    784      8      6    110     43    159
% 		5    9.5    NaN    NaN    NaN    NaN    NaN    NaN
% 		6   12.9    800      8      2    225    246    239
% 		...
%
% =========================================================================
% EXAMPLE 3b:       line filtering by 'good' markers; return char or cell
% -------------------------------------------------------------------------
%
% »
% Some colours and numbers
% 1 yellow 1 0 0
% 2 green  7 8 10
% 3 red    0 0 0
% 4 green  8 8 9
% 5 green  9 7 7
% 6 yellow 0 2 1
% «
%
% If you only want the data from the lines containing the string 'green':
%
% t2mOpts = {'NumHeaderLines', 1                , ...
%            'NumColumns'    , 4                , ...
%            'Format'        , '%f %*s %f %f %f', ...
%            'GoodLineString', {'green'}           };
%        
% A = txt2mat('C:\mydata.log', t2mOpts{:});
%
%   A =
%       2     7     8    10
%       4     8     8     9
%       5     9     7     7
%
% If you want to obtain those lines as text, use read mode 'char':
%
% t2mOpts = {'NumHeaderLines', 1         , ...
%            'GoodLineString', {'green'} , ...
%            'ReadMode'      , 'char'       };
%
% [A,ffn,nh,SR,hl] = txt2mat('C:\mydata.log', t2mOpts{:});
%
%   A =
%       2 green  7 8 10
%       4 green  8 8 9
%       5 green  9 7 7
%
% whos A
%   Name      Size            Bytes  Class    Attributes
%   A         1x49               98  char
%
% Some examples of what you could do with the char vector A:
%
%     - write it to a new file:
% 
%     fid = fopen('C:\mynewdata.log','w');
%     fwrite(fid, hl);  % write header
%     fwrite(fid, A);   % write data
%     fclose(fid);
% 
%     »
%     Some colours and numbers
%     2 green  7 8 10
%     4 green  8 8 9
%     5 green  9 7 7
%     «
% 
%     - proceed with functions like textscan:
% 
%     C = textscan(A,'%f %s %f %f %f');
% 
%      C = {[2;4;5], {'green';'green';'green'}, [7;8;9], [8;8;7], [10;9;7]}
%
% To put each line into a separate cell of a cell array of strings, use the
% very similar read mode 'cell':
%
% t2mOpts = {'NumHeaderLines', 1         , ...
%            'GoodLineString', {'green'} , ...
%            'ReadMode'      , 'cell'       };
%
% [A,ffn,nh,SR,hl] = txt2mat('C:\mydata.log', t2mOpts{:});
%
%   A = 
%           '2 green  7 8 10'
%           '4 green  8 8 9'
%           '5 green  9 7 7'
%
% =========================================================================
% EXAMPLE 3c:       line filtering by line number
% -------------------------------------------------------------------------
%
% »
% line number and magic
%  1    30    39    48     1    10    19    28
%  2    38    47     7     9    18    27    29
%  3    46     6     8    17    26    35    37
%  4     5    14    16    25    34    36    45
%  5    13    15    24    33    42    44     4
%  6    21    23    32    41    43     3    12
%  7    22    31    40    49     2    11    20
% «
% 
% If you only want to read every 3rd line starting from line 4:
%
% N  = 3;
% n1 = 4;
% selFun  = @(L) rem(L,N)==rem(n1,N) & L>=n1;
%
% fn      = 'C:\mydata.txt';
% t2mOpts = {'NumHeaderLines', 1      , ...
%            'SelectLineFun' , selFun    };
%        
% [A,ffn,nh,SR,hl] = txt2mat(fn, t2mOpts{:});
%
% A =
%      4     5    14    16    25    34    36    45
%      7    22    31    40    49     2    11    20
%
%
% Reading every 2nd line from line 3 to 6:
%
% N  = 2;
% selFun  = @(L) rem(L,N)==1;
% 
% t2mOpts = {'NumHeaderLines', 1       , ...
%            'RowRange'      , [3,6]   , ...
%            'SelectLineFun' , selFun  };
%        
% [A,ffn,nh,SR,hl] = txt2mat_06_56(fn, t2mOpts{:});
%
% A =
%      3    46     6     8    17    26    35    37
%      5    13    15    24    33    42    44     4
%
% =========================================================================
% EXAMPLE 4:        regular expression replacements
% -------------------------------------------------------------------------
%
% Supposed your ascii file C:\mydata.log begins with the following lines:
% »
% datetime	%	ppm	%	ppm	Nm
% datetime	real8	real8	real8	
% 30.10.2006 14:24:06,131	6,4459	478,519	6,5343	
% 30.10.2006 14:24:17,400	6,4093	484,959	6,5343	
% 30.10.2006 14:24:17,499	6,4093	484,959	6,5343	
% «
% you might specify 
% nh   = 2          % header lines, 
% nc   = 9          % data columns,
% fmt  = ['%d.%d.%d' repmat('%f',1,6)] % as format string for
%                                      % integers and hexadecimals,  
% sr1  = ': '       % as first replacement string to blank the ':'
% sr2  = ',.'       % to replace the decimal comma with a dot, and
%
% A = txt2mat('C:\mydata.log', nh, nc, fmt, {sr1,sr2});
%
%   A =
% 		30  10  2006  14  24   6.131  6.4459  478.519  6.5343
% 		30  10  2006  14  24  17.4    6.4093  484.959  6.5343
% 		30  10  2006  14  24  17.499  6.4093  484.959  6.5343
%       ...
% 
% 
% A = txt2mat('C:\mydata.log','ReplaceRegExpr',{{'\.(\d+)\.',' $1 '}});
%
% yields the same result, but uses the built-in file layout analysis to
% determine the number of header lines, the number of columns, the
% delimiters, and the decimal character. You only help TXT2MAT by
% telling it to replace dots surrounding the month number with spaces via
% the regular expression replacement. So you can use the latter command on
% similar files which have a different or previously unknown number of
% header lines etc., too. 
%
% =========================================================================
% EXAMPLE 5:        regular expression replacements
% -------------------------------------------------------------------------
%
% If the data table of your file contains some gaps that can be identified
% by some repeated delimiters (here ;)
% »
% ; 02; 03; 04; 05;
% 11; ; 13; 14; 15;
% 21; ; 23; ;;
% ; 32; 33; 34; 35;
% «
% you can fill them with NaNs by the help of 'ReplaceRegExpr':
%
% A = txt2mat('C:\mydata.log','ReplaceRegExpr',...
%                       {{'((?<=;\s*);)|(^\s*;)','NaN;'}});
%
%   A =
%        NaN     2     3     4     5
%         11   NaN    13    14    15
%         21   NaN    23   NaN   NaN
%        NaN    32    33    34    35
%    
% =========================================================================
% EXAMPLE 6:        processing a file in chunks
% -------------------------------------------------------------------------
% 
% If you want to process the contents of mydata.log step by step,
% converting one million lines at a time:
%
% fp  = 0;          % file position to start with (beginning of file)
% A   = NaN;        % initialize output matrix
% nhl = 12;         % number of header lines for the first call
% 
% while numel(A)>0
%     [A,ffn,nh,SR,hl,fp] = txt2mat('C:\mydata.log','RowRange',[1,1e6], ...
%                                   'FilePos',fp,'NumHeaderLines',nhl);
%     nhl = 0;      % there are no further header lines
%
%     % process intermediate results...
% end
% 
% =========================================================================
% EXAMPLE 7:        read mode 'block' and 'line'
% -------------------------------------------------------------------------
% 
% You can use the read mode 'block' on very large files with a constant
% number of values per line to save some import time compared to the
% 'matrix' mode. Besides, since TXT2MAT then does not check for line breaks
% within the (internally processed) sections of a file, you can use the
% block mode to fill up any output matrix with a fixed number of columns.
% »
%  1  2  3  4  5
%  6  7  8  9 10
%    
% 11 12 13 14 15
% 16 17 18 19 20
% 21 22
% 23 24 25
% 26 27 28 29 30
%
% «
% 
% A = txt2mat('C:\mydata.txt',0,5,'ReadMode','block')
% 
% A =
%      1     2     3     4     5
%      6     7     8     9    10
%     11    12    13    14    15
%     16    17    18    19    20
%     21    22    23    24    25
%     26    27    28    29    30
%
%
% Instead, if you want to preserve the line break information, use the
% (slower) read mode 'line': 
%
% A = txt2mat('C:\mydata.txt',0,5,'ReadMode','line')
%
% or
%
% A = txt2mat('C:\mydata.txt',0,-1)
%
% A =
%      1     2     3     4     5
%      6     7     8     9    10
%    NaN   NaN   NaN   NaN   NaN
%     11    12    13    14    15
%     16    17    18    19    20
%     21    22   NaN   NaN   NaN
%     23    24    25   NaN   NaN
%     26    27    28    29    30
%
% The first command reads up to 5 elements per line, starting from the
% first, and puts them to a Nx5 matrix, whereas the second one
% automatically expands the column size of the output to fit in the maximum
% number of elements occuring in a line. This is effected by the negative
% column number argument that also implies read mode 'line' here.
%  
% =========================================================================
%
%   See also SSCANF


% --- Author: -------------------------------------------------------------
%   Copyright 2005-2014 Andres
%   $Revision: 6.60.0 $  $Date: 2014/03/23 21:52:03 $
% --- E-Mail: -------------------------------------------------------------
% x=-2:3;
% disp(char(round([polyval([-0.32,0.43,1.75,-5.90,-0.95,116],x),...
%                  polyval([-4.44,9.12,29.8,-33.6,-52.9, 98],x)])))
% you may also contact me via the author page
% http://www.mathworks.com/matlabcentral/fileexchange/authors/30255
% --- History -------------------------------------------------------------
% 05.61
%   · fixed bug: possible wrong headerlines output when using 'FilePos'
%   · fixed bug: produced an error if a bad line marker string was already
%     found in the first data line 
%   · corrected user information if sscanf fails in matrix mode
%   · added some more help lines
% 05.62
%   · allow negative NumColumns argument to capture a priori unknown
%     numbers of values per line
% 05.82 beta
%   · support regular expression replacements ('ReplaceRegExpr' argument)
%   · consider user supplied replacements when analysing the file layout
% 05.86 beta
%   · some code clean-up (argincheck subfunction, ...)
% 05.86.1
%   · fixed bug: possibly wrong numeric matlab version number detection
% 05.90
%   · consider skippable lines when analysing the file layout
%   · code rearrangements (subfun for line termination detection, ...)
% 05.96
%   · subfuns to find line breaks / bad-line pos and to initialize output A
%   · better handling of errors and 'degenerate' files, e.g. exit without
%     an error if the file selection dialogue was cancelled 
% 05.97
%   · fixed bug: error in file analysis if first line contains bad line
%     marker
%   · fixed bug: a bad line marker is ignored if the string is split up by
%     two consecutive internal sections
%   · better code readability in findLineBreaks subfunction
% 05.97.1
%   · simplifications by skipping the header when reading from the file;
%     the header is now read separately and is not affected by any
%     replacements
%   · corrected handling of bad line markers that already appear in header
% 05.98
%   · corrected search for long bad line marker strings that could exceed
%     text dimensions
%   · speed-up by improved finding of line break positions
% 06.00
%   · introduction of 'high speed' read mode "block" requiring less line
%     break information
%   · 'MemPar' buffer value changed to scalar
%   · reduced memory demand by translating smaller text portions to char
%   · modified help
% 06.01
%   · fixed bug: possible error message in file analysis when only header
%     line number is given
% 06.04
%   · better handling of replacement strings containing line breaks
%   · allow '*' in file name to use file name as open file dialogue filter
% 06.12
%   · 'good line' filter as requested by Val Schmidt
% 06.17.1
%   · enable 'good line' filtering during automatic file analysis
%   · new read modes 'char' and 'cell' to provide txt2mat's preprocessing
%     features esp. for non-numeric data, too
% 06.17.3
%   · version number workaround for MCR execution (Leonard's remark)
% 06.40
%   · input argument check by inputparser (R2007a), allowing input struct
%   · minor changes in code and documentation
% 06.60
%   · added option to select lines by line number ('SelectLineFun'), e.g. 
%     to skip every n-th line as suggested by Kaare 
%   · reduced memory footprint and improved speed during good/bad line
%     filtering by working in chunks
%
% --- Wish list -----------------------------------------------------------


%% Get input arguments

% check the arguments by argincheck:
arg = argincheck(varargin);
% returns
%       arg.val.(argname)  ->  value of the input
%       arg.has.(argname)  ->  T/F argument was given
%       arg.num.(argname)  ->  number of values for some non-scalar inputs

% some abbreviations
ffn       = arg.val.FileName;
numHeader = arg.val.NumHeaderLines;
numColon  = arg.val.NumColumns;
readMode  = arg.val.ReadMode;
formatStr = arg.val.Format;
repChar   = arg.val.ReplaceChar;
filePos   = arg.val.FilePos;
memPar    = arg.val.MemPar;
numRC     = arg.num.ReplaceChar;
numRS     = arg.num.ReplaceStr;
numRR     = arg.num.ReplaceRegExpr;
numBL     = arg.num.BadLineString;
numGL     = arg.num.GoodLineString;

% ~~~~~ special handling of file name argument arg.val.FileName ~~~~~~~~~~~
% 1) no file or path name is given -> open file dialogue
if ~arg.has.FileName || isempty(ffn)
    [fn,pn] = uigetfile('*.*', arg.val.DialogString);
    ffn = fullfile(pn,fn);
% 2) a path name is given -> open file dialogue with *.* filter spec
elseif exist(ffn,'dir') == 7
    curcd = cd;
    cd(ffn);                   
    [fn,pn] = uigetfile('*.*', arg.val.DialogString);
    ffn = fullfile(pn,fn);
    cd(curcd);
% 3) a valid file name is given -> take it as it is
elseif exist(ffn,'file') 
	[fname,fname,ext] = fileparts(ffn); %#ok<ASGLU>
	fn = [fname,ext];
% 4) an asterisk in the file name -> open file dialogue, use filter spec
%    - OR -
%    nonexisting file -> produce error message and return
else
    [pathstr, fname, ext] = fileparts(ffn);
    doOpenDialog = (isempty(pathstr) || exist(pathstr,'dir')==7) && ...
                   numel(strfind([fname, ext], '*')) > 0;
               
    if doOpenDialog
        if ~isempty(pathstr)
            curcd = cd;
            cd(pathstr)
        end
        
        [fn,pn] = uigetfile({[fname, ext];'*.*'}, arg.val.DialogString);
        ffn = fullfile(pn,fn);
        
        if ~isempty(pathstr)
            cd(curcd);
        end
    else
        % wrong name
        error('txt2mat:invalidFileName','no such file or directory'); 
    end
end

% recheck file name (necessary e.g. after ESC in open file dialogue)
if exist(ffn,'file')~=2
    [A,ffn,numHeader,repChar,hl,fpos] = deal([]);
    if arg.val.InfoLevel>=1
        disp('Exiting txt2mat: No existing file given.')
    end
    return
end

% generate a shortened form of the file name:
if length(fn) < 28
    fnShort = fn;
else
    fnShort = ['...' fn(end-24:end)];
end

arg.val.FileName = ffn;
% ~~~~~ special handling of file name argument arg.val.FileName ~~~~~~~end~

clear varargin

%% Analyze data format

% try some automatic data format analysis if needed (by function anatxt)
doAnalyzeFile = ~all([arg.has.NumHeaderLines, arg.has.NumColumns]); %, is_argin_conv_str]); % commented out as so far anatxt's formatStr is only '%f'
% switch off file analysis if read mode is 'char' or 'cell'
doAnalyzeFile = doAnalyzeFile && ~strcmpi(arg.val.ReadMode,'char') && ~strcmpi(arg.val.ReadMode,'cell');

if doAnalyzeFile 
    % call subfunction anatxt:
    [anaNumHeader, anaNumColon, ~, anaRepChar, anaReadMode, ...
        anaNumAnalyzed, anaHeader, anaFileErr, anaErr] = anatxt(arg); 
    % quit if errors occurred
    if ~isempty(anaErr)
        [A,repChar,fpos,hl] = deal([]);
        numHeader = anaNumHeader;
        if arg.val.InfoLevel>=1
            disp(['Exiting txt2mat: file analysis: ' anaErr])
        end
        return
    end
        
    % accept required results from anatxt:
    if ~arg.has.NumHeaderLines
        numHeader = anaNumHeader;
    end
    if ~arg.has.NumColumns
        numColon = anaNumColon;
    end
    %if ~arg.has.Format      % unused
    %    formatStr = anaFormat;
    %end
    if ~arg.has.ReadMode
        readMode = anaReadMode;
    end
    % add new replacement character strings from anatxt:
    isNewRC	= ~ismember(anaRepChar, repChar);
    numRC   = numRC + sum(isNewRC);
    repChar = [repChar,anaRepChar(isNewRC)];
    % display information:
    if arg.val.InfoLevel >= 1
        disp(repmat('*',1,length(ffn)+2));
        disp(['* ' ffn]);
        if numel(anaFileErr)==0
            sr_display_str = '';
            for idx = 1:numRC;
                sr_display_str = [sr_display_str ' »' repChar{idx} '«']; %#ok<AGROW>
            end
            disp(['* read mode: ' readMode]);
            disp(['* ' num2str(anaNumAnalyzed)        ' data lines analysed' ]);
            disp(['* ' num2str(numHeader)     ' header line(s)']);
            disp(['* ' num2str(abs(numColon)) ' data column(s)']);
            disp(['* ' num2str(numRC)         ' string replacement(s)' sr_display_str]);
        else
            disp(['* fread error: ' anaFileErr '.']);
        end
        disp(repmat('*',1,length(ffn)+2));
    end % if
    
    % return if anatxt did not detect valid data
    if anaNumColon==0
        A = [];
        hl = '';
        fpos = filePos;
        return
    end
end


%% Detect line termination character

if arg.val.InfoLevel >= 1
    hw = waitbar(0,'detect line termination character ...');
    set(hw,'Name',[mfilename ' - ' fnShort]);
    hasWaitbar = true;
else
    hasWaitbar = false;
end

lbfull = detectLineBreakCharacters(ffn);
%   lbfull  line break character(s) as uint8, i.e.
%           [13 10]     (cr+lf) for standard DOS / Windows files
%           [10]        (lf) for Unix files
%           [13]        (cr) for Mac files
% The DOS style values are returned as defaults if no such line breaks are
% found.

lbuint = lbfull(end);      
lbchar = char(lbuint);
numLbfull = numel(lbfull);     

%% Open file and set position indicator to end of header
% ... and extract header separately if not already done

logfid = fopen(ffn);
if numHeader > 0
    if doAnalyzeFile % header lines have already been extracted
        hl = anaHeader;
        lenHeader = numel(hl);
        fseek(logfid,filePos+lenHeader,'bof');
    else
        if arg.has.FilePos
            fseek(logfid,filePos,'bof');
        end

        %*% todo: use function getLines here
        read_len = 65536;   % (quite small) size of text sections just for header line extraction
        do_read  = true;
        num_lb_curr = 0;
        countLoop = 0;
        while do_read
            [f8p,lenf8p]    = fread(logfid,read_len,'*uint8');	% current text section

            ldcp_curr       = find(f8p==lbuint);                % line break positions in current text section
            num_lb_curr     = num_lb_curr + numel(ldcp_curr);   % number of line breaks so far
            
            do_read         = (lenf8p == read_len) && (num_lb_curr < numHeader);
            countLoop       = countLoop + 1;
        end
        
        if num_lb_curr >= numHeader
            lenHeader = ldcp_curr(end-(num_lb_curr-numHeader)) + (countLoop-1)*read_len;
            if countLoop == 1
                % take the complete header from the first section
                hl = char(f8p(1:lenHeader)).';
                fseek(logfid,filePos+lenHeader,'bof');
            else
                % the header did not fit into a single section, so re-read
                % it as a whole
                fseek(logfid,filePos,'bof');
                hl = char(fread(logfid,lenHeader).');
            end
        else 
            % exit here as we have found less line breaks than the given
            % number of header lines!
            fseek(logfid,filePos,'bof');
            hl = char(fread(logfid).');
            fpos = ftell(logfid);
            fclose(logfid);
         	[A,repChar] = deal([]);
            if arg.val.InfoLevel>=1
                disp(['Exiting txt2mat: '  num2str(numHeader) ' header lines expected, but only ' num2str(num_lb_curr) ' line breaks found.'])
                close(hw)
            end
          	return
            
        end
    end
else
    lenHeader = 0;
    hl = '';
    if arg.has.FilePos
     	fseek(logfid,filePos,'bof');
    end
end

%% Read in ASCII file - case 1: portions only, as RowRange is given.
% RowRange should be given if the file is too huge to be read at once by
% fread. In this case multiple freads are used to read in consecutive
% sections of the text. By counting the line breaks those rows of the text
% that match the RowRange argument are added to the 'core' variable f8 that
% is later used for the numeric conversion.

% By definition, a line begins with its first character and ends with its
% last termination character.

if hasWaitbar
    waitbar(0.01,hw,'reading file ...');
end

if arg.has.RowRange
    do_read             = true;     % loop condition
    num_lb_prev         = 0;
    read_len            = memPar;
    f8                  = [];
    while do_read
        [f8p,lenf8p]  = fread(logfid,read_len,'*uint8');  	% current text section

        ldcp_curr       = find(f8p==lbuint);                % line break positions in current text section
        num_lb_curr     = numel(ldcp_curr);

        % add lines of interest to f8
        if (arg.val.RowRange(1) <= num_lb_prev+num_lb_curr+1) && (num_lb_prev < arg.val.RowRange(2))

            if arg.val.RowRange(1) <= num_lb_prev + 1	% lines of interest started before current section
                sdx = 1;                                        % start index is beginning of section => the part of the section to be added to f8 includes the start of the section 
            else                                                % lines of interest start within current section
                num_lines_to_omit = arg.val.RowRange(1)-1-num_lb_prev;  % how many lines not to add
                sdx = ldcp_curr(num_lines_to_omit)+1;         	% start right after the omitted lines
            end

            if arg.val.RowRange(2) > num_lb_curr+num_lb_prev    % lines of interest end beyond current section
                edx = lenf8p;                                   % end index is length of section => the part of the section to be added to f8 includes the end of the section 
            else                                                % lines of interest end within current section
                num_lines_to_add = arg.val.RowRange(2)-num_lb_prev;     % how many lines to add
                edx = ldcp_curr(num_lines_to_add);             	% corresponding end index
            end

            f8 = [f8; f8p(sdx:edx)]; %#ok<AGROW>
            fpos = ftell(logfid)-lenf8p+edx;       % position of the latest added character 
        end

        % quit loop if all rows of interest are read or if end of file is reached 
        if num_lb_prev >= arg.val.RowRange(2) || lenf8p<read_len
            do_read = false;
        end
        num_lb_prev          = num_lb_prev + num_lb_curr;  	% absolute number of dectected line breaks
    end
    
end
%% Read in ASCII file - case 2: full file. Then close file.

if ~arg.has.RowRange
    [f8,fcount]  = fread(logfid,Inf,'*uint8');
    fpos = fcount + filePos + lenHeader;
end

if ftell(logfid) == -1
    error(ferror(fid, 'clear'));
end

fclose(logfid); 

if numel(f8)==0
    A = [];
    if arg.val.InfoLevel>=1
        disp('Exiting txt2mat: no numeric data found.')
        close(hw)
    end
    return
end


%% Clean up whitespaces at the end of file

f8 = cleanUpFinalWhitespace(f8,lbfull);


%% check line break position awareness

hasReplacements = any([numRC,numRS,numRR] > 0 );

% as finding the line breaks is time-critical, "LbAwareness" is
% introduced to tell us what we know about line break positions:
% 0: nothing
% 1: the positions of the final line break in every section
% 2: the above + the number of lines up to each of those line breaks
% 3: all line break positions

% determine the minimum reqired LbAwareness, and set a waitbar progress
% factor >1 if there's no sscanf read: 
wbFactor = 1;
switch lower(readMode)
    case 'char'
        minLbAwareness = double(hasReplacements);
        wbFactor = 2;
    case 'block'
        minLbAwareness = 1;
    case {'matrix','auto'}
        minLbAwareness = 2;
    case 'line'
        minLbAwareness = 3;
    case 'cell'
        minLbAwareness = 3;
        wbFactor = 1.9;
end


%% filter lines (rows)

% select lines by line number and 'bad' and/or 'good' marker strings

if arg.has.SelectLineFun || (numBL + numGL > 0)
    if hasWaitbar
        waitbar(wbFactor*0.10,hw,'filtering lines ...');
    end
    [f8, idcLb, cntLb, secLbIdc] = filterLines(f8, lbuint, memPar, arg);
    LbAwareness = 3;
else
    LbAwareness = 0;
end


%% Find line break positions if necessary

if LbAwareness < minLbAwareness
    
    if hasWaitbar
        waitbar(wbFactor*0.20,hw,'updating line break positions ...');
    end
    
    % Find out if we have to expect text length changes due to the
    % replacemets
    doExpectLengthChange = false;   % default
    if numRR > 0
        % always expect changes by regular expressions
        doExpectLengthChange = true;
    else
        % check for string replacements that will change the length
        for edx = 1:numRS
            if any(diff(cellfun('length', arg.val.ReplaceStr{edx})))
                doExpectLengthChange = true;
                break
            end
        end
    end
    
    if doExpectLengthChange || strcmpi(readMode,'block')
        % - make K1
        doFindAll = false;
        doCount   = false;
        LbAwareness = 1;
    else
        if strcmpi(readMode,'line') || strcmpi(readMode,'cell')
        	% - make K3
            doFindAll = true;
            doCount   = true;
            LbAwareness = 3;
        else  % readmode is 'auto' or 'matrix'
            % - make K2
            doFindAll = false;
            doCount   = true;
            LbAwareness = 2;
        end
    end

    [idcLb,cntLb,secLbIdc] = findLineBreaks(f8, lbuint, memPar, doFindAll, doCount);
end

%% Replace (regular) expressions and characters

doReplaceLb = false;   % default, to be checked below

if numRR > 0
    has_length_changed = true;
else
    has_length_changed = false; % flag for changes of length of f8 by replacements
end

if hasReplacements
    if hasWaitbar
        waitbar(wbFactor*0.20,hw,'replacing strings ...');
    end

    numSectionLb = numel(secLbIdc);

    % If a ReplaceStr begins with a line break character, such a character
    % will temporarily be prepended to each replacement section to apply
    % the replacement to the _first_ line of a section, too.
    % Besides, check for any occurence of the break character in the
    % ReplaceStr in order to preventively trigger an update of the line
    % break positions afterwards.
    % Set defaults before checking:
    doPrependLb = false;   
    numPrepend  = 0;       
    if numRS>0
        % put all the characters from the ReplaceStr strings into an
        % uint8-array:
        uint8Replace = uint8(char([arg.val.ReplaceStr{:}]));
        % check if any row starts with a line break:
        if any(uint8Replace(:,1)==lbuint)
            doPrependLb = true;
            numPrepend  = 1;
        end
        if any(uint8Replace(:)==lbuint)
            doReplaceLb = true;
        end
    end
    
    for sdx = 2:numSectionLb
        
        if doPrependLb
            f8_akt = char([lbuint, f8(idcLb(secLbIdc(sdx-1))+1 : idcLb(secLbIdc(sdx))).']);
        else
            f8_akt = char(f8(idcLb(secLbIdc(sdx-1))+1 : idcLb(secLbIdc(sdx))).');
        end
        
        if numRS > 0 || numRR > 0
            len_f8_akt = idcLb(secLbIdc(sdx)) - idcLb(secLbIdc(sdx-1));  % length of current section before replacements

            % Replacements, e.g. {'odd','one','1'} replaces 'odd' and 'one' by '1'

            % Regular Expression Replacements: ============================
            for vdx = 1:numRR                  % step through replacements arguments
                srarg = arg.val.ReplaceRegExpr{vdx};    	% pick a single argument...

                for xdx = 1:(numel(srarg)-1)
                    f8_akt = regexprep(f8_akt, srarg{xdx}, srarg{end});     % ... and perform replacements
                end % for

            end % for

            % Expression Replacements: ====================================
            for vdx = 1:numRS                  % step through replacements arguments
                srarg = arg.val.ReplaceStr{vdx};    	% pick a single argument...

                for xdx = 1:(numel(srarg)-1)
                    f8_akt = strrep(f8_akt, srarg{xdx}, srarg{end});        % ... and perform replacements
                    if ~has_length_changed && (len_f8_akt~=numel(f8_akt))
                        has_length_changed = true;                          % detect a change of length of f8
                    end
                end % for

            end % for

            % update f8-sections by f8_akt ================================
            exten = numel(f8_akt) - len_f8_akt;	% extension by replacements
            
            if exten == 0   
                if doPrependLb
                    f8( idcLb(secLbIdc(sdx-1))+1 : idcLb(secLbIdc(sdx)) ) = uint8(f8_akt(1+numPrepend:end)).';
                else
                    f8( idcLb(secLbIdc(sdx-1))+1 : idcLb(secLbIdc(sdx)) ) = uint8(f8_akt).';
                end
            else   
                if doPrependLb
                    f8 = [f8(1:idcLb(secLbIdc(sdx-1))); uint8(f8_akt(1+numPrepend:end)).'; f8(idcLb(secLbIdc(sdx))+1:end)];
                else
                    f8 = [f8(1:idcLb(secLbIdc(sdx-1))); uint8(f8_akt).'                  ; f8(idcLb(secLbIdc(sdx))+1:end)];
                end
                % update linebreak indices of the following sections
                % (but we don't know the lb indices of the current one anymore):
                idcLb(secLbIdc(sdx:end)) = idcLb(secLbIdc(sdx:end)) + exten;
            end
            
        end % if numRS > 0 || numRR > 0
        
        % Character Replacements: =========================================
        for vdx = 1:numRC                  % step through replacement arguments
            srarg = repChar{vdx};       % pick a single argument
            for xdx = 1:(numel(srarg)-1)
                rep_idx = idcLb(secLbIdc(sdx-1))+strfind(f8_akt,srarg(xdx))-numPrepend;
                f8(rep_idx) = uint8(srarg(end));   % perform replacement
            end % for
        end
        
        if hasWaitbar && ~mod(sdx,256)
            waitbar(wbFactor*(0.20+0.25*((sdx-1)/(numSectionLb-1))),hw)
        end
        
    end

    clear f8_akt
end % if


%% ReadMode 'char': exit here with char array

if strcmpi(readMode,'char')
    A=char(f8.');
    if arg.val.InfoLevel>=1
        close(hw)
    end
    return
end


%% Update linebreak indices
% see above...

% if the final line break might have changed, clean up trailing whitespaces
% here again
if doReplaceLb || numRR > 0
    f8 = cleanUpFinalWhitespace(f8,lbfull);
end

if has_length_changed || (LbAwareness < minLbAwareness) || doReplaceLb
    if hasWaitbar
        waitbar(0.45,hw,'updating line break positions ...');
    end

    if strcmpi(readMode,'block')
        % - make K1
        doFindAll = false;
        doCount   = false;
        LbAwareness = 1;
    elseif strcmpi(readMode,'line') || strcmpi(readMode,'cell')
        % - make K3
        doFindAll = true;
        doCount   = true;
        LbAwareness = 3;
    else  % readmode is 'auto' or 'matrix'
        % - make K2
        doFindAll = false;
        doCount   = true;
        LbAwareness = 2;
    end

    [idcLb,cntLb,secLbIdc] = findLineBreaks(f8, lbuint, memPar, doFindAll, doCount);
end

% Determine the total number of line breaks (including the leading 'zero'
% line break and the eventually added final line break) depending on
% LbAwareness. If LbAwareness is less than 2, we can't know that number.
if LbAwareness == 2
    num_lf = cntLb(end)+1;
elseif LbAwareness == 3
    num_lf = numel(idcLb);
else
    num_lf = NaN;
end

%% ReadMode 'cell': return lines in a cell array

if strcmpi(readMode,'cell')
    
    f8 = char(f8).';
    
    % A = arrayfun(@(m,n) {(f8(m:n)}, ...
    %                         lf_idc(1:end-1)+1,lf_idc(2:end)-num_lbfull);
    % but arrayfun is slower here, so use V6 code (for loop) only:
    
    A = repmat({''},num_lf-1,1);
    for m = 1:num_lf-1
        A{m} = f8(idcLb(m)+1:idcLb(m+1)-numLbfull);
    end

    if arg.val.InfoLevel>=1
        close(hw)
    end
    return

end

%% ReadMode 'block': wilfully fill up output matrix

if strcmpi(readMode,'block')
    
    if hasWaitbar
        waitbar(0.5,hw,'converting in ''block'' mode ...');
    end
    
    numColonBlock   = abs(numColon);    % number of columns in output matrix
    isNumelOk       = true;             % initialize flag "in every section the number of elements is a multiple of number of columns"
    numSectionLb    = numel(secLbIdc);  % 1 + number of sections to process
    doSetNan        = true;             % flag "output matrix will be initialized with NaNs"
    
    % convert first section ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    startIdcF8 = idcLb(secLbIdc(1))+1;
    endIdcF8   = idcLb(secLbIdc(2));
    
    % THE conversion of this section by sscanf:
    [Atmp,count,errmsg,nextindex] = ...
            sscanf(char(f8(startIdcF8 : endIdcF8)), formatStr); %#ok<ASGLU>
    numAtmp = numel(Atmp);
	
    % examine how many elements we found in this section
    numRowsCurr      = ceil(numAtmp/numColonBlock);         % how many rows will contain these elements
    numelMissing     = numRowsCurr*numColonBlock-numAtmp;   % how many elements are missing to fill up the last of these rows

    a = initializeMatrix(1,1,arg.val.NumericType,doSetNan);
    
    if numSectionLb < 3
        % there is only one section, so just generate the final output
        % matrix here:
        A = reshape([Atmp;repmat(a,numelMissing,1)],numColonBlock,numRowsCurr).';
        if numelMissing>0
            isNumelOk = false;
        end
    else
        % there are multiple sections, so initialize the output matrix
        % first ...
        if isnan(num_lf)
              % guess final size of A for preallocating
              expandFactor   = diff(idcLb(secLbIdc([1,end])))/diff(idcLb(secLbIdc([1,2])));
              numRowsGuessed = round(numRowsCurr * expandFactor);
        else
            numRowsGuessed = num_lf;
        end
        A = initializeMatrix(numRowsGuessed,numColonBlock,arg.val.NumericType,doSetNan);

        % ... and put the first elements to it:
        startRow = 1;
        endRow   = numRowsCurr;
        Atmp = reshape([Atmp;repmat(a,numelMissing,1)],numColonBlock,numRowsCurr).';
        A(startRow:endRow,1:numColonBlock) = Atmp;

        % If the first section was incomplete, the first elements of the
        % second section will be added to the last row of the first
        % section. So keep in mind the elements of the incomplete row here:
        if numelMissing>0
            isNumelOk = false;
            repeatRow = 1;
            ARepeat = A(endRow,1:(numColonBlock-numelMissing)).';
        else
            repeatRow = 0;
            ARepeat = [];
        end

        % now step through the following sections
        for sdx = 2:numSectionLb-1

            % the text positions of the current section:
            startIdcF8 = idcLb(secLbIdc(sdx))+1;
            endIdcF8   = idcLb(secLbIdc(sdx+1));

            % THE conversion of this section by sscanf:
            [Atmp,count,errmsg,nextindex] = ...
                sscanf(char(f8(startIdcF8 : endIdcF8)), formatStr); %#ok<ASGLU>
            numAtmp = numel(Atmp);
            if numAtmp == 0
                Atmp = double(Atmp);
            end

            % as with the first section, add the new values the output
            % matrrix
            numRowsCurr  = ceil( (numAtmp-numelMissing) / numColonBlock );
            numelMissing = numRowsCurr*numColonBlock-(numAtmp-numelMissing);
            startRow     = endRow+1-repeatRow;
            endRow       = endRow+numRowsCurr;
            
            Atmp = reshape([ARepeat;Atmp;repmat(a,numelMissing,1)],numColonBlock,numRowsCurr+repeatRow).';
            A(startRow:endRow,1:numColonBlock) = Atmp;     
            
            % remember elements of an incomplete row for the next section
            if numelMissing>0
                isNumelOk = false;
                repeatRow = 1;
                ARepeat = A(endRow,1:(numColonBlock-numelMissing)).';
            else
                repeatRow = 0;
                ARepeat = [];
            end
            
            if hasWaitbar && ~mod(sdx,256)
                waitbar(0.5+0.5*((sdx-1)/(numSectionLb-1)),hw)
            end
            
        end
        
        if numRowsGuessed > endRow
            A = A(1:endRow,:);
            % A(endRow+1:numRowsGuessed,:) = [];
        end
        
    end
    
    if ~isNumelOk
        warning('txt2mat:NumberOfElements', 'Number of elements did not fill up a complete row')
    end
        
end

%% ReadMode 'matrix': try converting large sections
% sscanf will be applied to consecutive working sections consisting of
% <ldx_rng> rows. The number of numeric values must then be a multiple of
% the number of columns. Otherwise, or if sscanf produces an error, inform
% the user and eventually proceed to the (slower) line-by-line conversion.


errmsg = '';    % Init. error message variable
if strcmpi(readMode,'auto') || strcmpi(readMode,'matrix') 
    if hasWaitbar
        waitbar(0.5,hw,'converting in ''matrix'' mode ...');
    end
    
    try
        numColonMatrix  = abs(numColon);
        errorType = 'none';         % 
        A = initializeMatrix(num_lf-1,numColonMatrix,arg.val.NumericType,false);
        
        % Usually, in 'matrix' mode, we have LbAwareness == 2. As the way
        % we calculate the number of rows in a section depends on
        % LbAwareness, we check that here: 
        hasNotAllLb = LbAwareness < 3;
        
        numSectionLb = numel(secLbIdc);
        
        %*% for testing purposes: aggregate multiple sections to a larger one 
        %sectionStep =1;    % how many sections to aggregate
        %selectedSectionIdc = min(2:sectionStep:numSectionLb+sectionStep-1, numSectionLb);
        %*% in this case, use max(1,sdx-sectionStep) instead of sdx-1 below 
        
        selectedSectionIdc = 2:numSectionLb;
    
        for sdx = selectedSectionIdc
            
            % start and end indices of the current section in the text:
            startIdcF8 = idcLb(secLbIdc(sdx-1))+1;
            endIdcF8   = idcLb(secLbIdc(sdx));
            
            % THE conversion of this section by sscanf:
            [Atmp,count,errmsg,nextindex] = ...
                    sscanf(char(f8(startIdcF8 : endIdcF8)), formatStr); 

            % the correponding row indices of the output matrix:
            if hasNotAllLb
                startRow       = cntLb(sdx-1)+1;
                endRow         = cntLb(sdx);
            else
                startRow       = secLbIdc(sdx-1);
                endRow         = secLbIdc(sdx)-1;
            end
            num_lines_loop = endRow - startRow + 1;
            
            %~% error handling ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if ~isempty(errmsg) 
                % there's an sscanf error message
                errorType = 'sscanf';
                break
            elseif numel(Atmp) ~= numColonMatrix * num_lines_loop
                % we did not read the expected number of numeric elements
                errorType = 'numel';
                numelExpected = numColonMatrix * num_lines_loop;
                numelFound    = numel(Atmp);
                break
            end
            %~% end error handling ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
            % put the values to the right dimensions and add them to A
            Atmp = reshape(Atmp,numColonMatrix,num_lines_loop)';
            A(startRow:endRow,:) = Atmp;
            
            if hasWaitbar && ~mod(sdx,256)
                waitbar(0.5+0.5*((sdx-1)/(numSectionLb-1)),hw)
            end

        end % for sdx = 2:numSectionLb
        
        % error diagnosis and user information ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        switch errorType
            case 'sscanf'
                if (arg.val.InfoLevel >= 2) && ( nextindex <= endIdcF8 - startIdcF8 + 1 )  
                    % If sscanf did not process the whole string, display
                    % the text line where it stopped.
                    
                    % line break indices in the current section
                    idcLbCurr = [0, strfind(f8(startIdcF8 : endIdcF8).', lbchar)];
                    % find line break index of the abortion line
                    idxErrorLine = find(idcLbCurr-nextindex > 0, 1 );    
                    % text content of the abortion line
                    errorLineText = f8(startIdcF8 + (idcLbCurr(idxErrorLine-1):idcLbCurr(idxErrorLine)-numLbfull-1) ).';
                    % display information about the error cause
                    disp(['Sscanf error after reading ' num2str((startRow-1)*numColonMatrix+count) ' numeric values.'])
                    disp(['Text content of the critical row (no. ' num2str(numHeader+startRow-1+idxErrorLine-1) ' without deleted lines): '])
                    disp(errorLineText)
                end % if
                
            case 'numel'
                if arg.val.InfoLevel >= 2
                    % We don't know the exact lines containing the wrong
                    % number of values. As a guess, just display the
                    % positions of the longest or the shortest text lines
                    % (by simply counting characters).
                    
                    % line break indices in the current section
                    idcLbCurr = [0, strfind(f8(startIdcF8 : endIdcF8).', lbchar)];
                    % corresponding text line lengths
                    lenLine = diff(idcLbCurr);
                    [lenLineSorted,idclenLineSorted] = sort(lenLine);
                    maxNumDisplayed = min(5,numel(lenLine));

                    if numelFound < numelExpected
                        disp(['Found less elements (' num2str(numelFound) ') than expected (' num2str(numelExpected) ') in the current section.'])
                        disp('As a hint, these are the text lines containing the least characters:')
                        disp(['lines no. [' num2str(numHeader+startRow-1+idclenLineSorted(1:maxNumDisplayed)) '] having [' num2str(lenLineSorted(1:maxNumDisplayed),' %i') '] characters, resp.'])
                    else
                        disp(['Found more elements (' num2str(numelFound) ') than expected (' num2str(numelExpected) ') in the current section.'])
                        disp('As a hint, these are the text lines containing the most characters:')
                        disp(['lines no. [' num2str(numHeader+startRow-1+idclenLineSorted(end:-1:end-maxNumDisplayed+1)) '] having [' num2str(lenLineSorted(end:-1:end-maxNumDisplayed+1),' %i') '] characters, resp.'])
                    end
                end
                error('Unexpected number of elements in read mode ''matrix''.')
        end
        % end error diagnosis and user information ~~~~~~~~~~~~~~~~~~~~~~~~        
        
    catch   %#ok<CTCH> % catch further errors (old catch style)
        if ~exist('errmsg','var') || isempty(errmsg)
            errmsg = lasterr; %#ok<LERR> (old catch style)
        end
    end % try
end

% Quit on error if 'matrix'-mode was enforced: 
if strcmpi(readMode,'matrix') && ~isempty(errmsg)
    if arg.val.InfoLevel >= 1
        close(hw)
    end
    error(errmsg);
end


%% ReadMode 'line': convert line-by-line

clear Atmp

if strcmpi(readMode,'line') || ~isempty(errmsg) 
    num_data_per_row = zeros(num_lf-1,1);
    
    if ~strcmpi(readMode,'line')
        numColon = -abs(numColon);
        if arg.val.InfoLevel >= 2
            disp('Due to error')
            disp(strrep(['  ' errmsg],char(10),char([10 32 32])))
            disp('txt2mat will now try to read line by line...')
        end % if
    end
    
    if LbAwareness < 3
        idcLb = findLineBreaks(f8, lbuint, memPar, true, false);
        num_lf = numel(idcLb);
    end

    % initialize result matrix A depending on matlab version:
    width_A = max(abs(numColon),1);
    [A,A1] = initializeMatrix(num_lf-1,width_A,arg.val.NumericType,true);

    if hasWaitbar
        if strcmpi(readMode,'line')
            waitbar(0.5,hw,{'reading line-by-line ...'})
        else
            poshw = get(hw,'Position');
            set(hw,'Position',[poshw(1), poshw(2)-4/7*poshw(4), poshw(3), 11/7*poshw(4)]);
            waitbar(0.5,hw,{'now reading line-by-line because of error:';['[' errmsg ']']})
            set(findall(hw,'Type','text'),'interpreter','none');
        end
        drawnow
    end
	
	% extract numeric values line-by-line:
	for ldx = 1:(num_lf-1)
        a = sscanf(char(f8( (idcLb(ldx)+1) : idcLb(ldx+1)-1 )),formatStr)';
        num_data_per_row(ldx) = numel(a);
        % If necessary, expand A along second dimension (allowed if
        % numColon < 0)
        if (num_data_per_row(ldx) > width_A) && (numColon < 0)
            A = [A, repmat(A1,size(A,1),...
                 num_data_per_row(ldx)-width_A)]; %#ok<AGROW>
            width_A = num_data_per_row(ldx);
        end
        A(ldx,1:min(num_data_per_row(ldx),width_A)) = a(1:min(num_data_per_row(ldx),width_A));
        
        % display waitbar:
        if hasWaitbar && ~mod(ldx,10000)
                waitbar(0.5+0.5*(ldx./(num_lf-1)),hw)
        end % if
	end % for
    
    % display info about number of numeric values per line
    if arg.val.InfoLevel >= 2
        if numColon>=0
            reference = numColon;
        elseif numColon == -1;
            reference = width_A;
        else
            reference = -numColon;
        end
        
        disp('txt2mat row length info:')
        idc_less_data = find(num_data_per_row<reference);
        idc_more_data = find(num_data_per_row>reference);
        num_less_data = numel(idc_less_data);
        num_more_data = numel(idc_more_data);
        num_equal_data = num_lf-1 - num_less_data - num_more_data;
        info_ca(1:3,1) = {['  ' num2str(num_equal_data)];['  ' num2str(num_less_data)];['  ' num2str(num_more_data)]};
        info_ca(1:3,2) = {[' row(s) found with ' num2str(reference) ' values'],...
                           ' row(s) found with less values',...
                           ' row(s) found with more values'};
        info_ca(1:3,3) = {' ';' ';' '};
        if num_less_data>0
            info_ca{2,3} = [' (row no. ', num2str(numHeader+idc_less_data(1:min(10,num_less_data))'), repmat(' ...',1,num_less_data>10), ')'];
        end
        if num_more_data>0
            info_ca{3,3} = [' (row no. ', num2str(numHeader+idc_more_data(1:min(10,num_more_data))'), repmat(' ...',1,num_more_data>10), ')'];
        end
        disp(strcatcell(info_ca));

    end % if arg.val.InfoLevel >= 2
    
end % if

if arg.val.InfoLevel >= 1
    close(hw)
end


%% : : : : : subfunction ANATXT : : : : : 

function [anaNumHeader, anaNumColon, anaFormat, anaRepChar, anaReadMode, ...
    anaNumAnalyzed, anaHeader, anaFileErr, anaErr] = anatxt(arg)

% ANATXT analyse data layout in a text file for txt2mat
% 
% Usage:
% [nh, nc, fmt, SR, RM, llta, hl, ferrmsg, aerrmsg] = ...
%       anatxt(arg);
%
% nh            number of header lines
% nc            number of columns
% fmt           format string (curr. always '%f')
% SR            character replacement string
% RM            recommended read mode
% llta          lines analysed after header
% hl            header line characters
% ferrmsg       file operation error message
% aerrmsg       other error messages from this function
%
% arg           txt2mat's input argument struct

%   Copyright 2006-2014 Andres
%   $Revision: 4.00 $  $Date: 2014/03/18 14:05:08 $
%   todo: especially this function needs a cleanup...

% some preparations
ffn             = arg.val.FileName;
filePos         = arg.val.FilePos;
repChar         = arg.val.ReplaceChar;
repStr          = arg.val.ReplaceStr;
repReg          = arg.val.ReplaceRegExpr;
numHeader       = arg.val.NumHeaderLines;

numRR           = arg.num.ReplaceRegExpr;
numRS           = arg.num.ReplaceStr;
numRC           = arg.num.ReplaceChar;
numBL           = arg.num.BadLineString;
numGL           = arg.num.GoodLineString;

[anaNumColon, anaNumAnalyzed] = deal(0);
[anaReadMode, anaHeader, anaErr] = deal('');
anaRepChar = {};
anaNumHeader = numHeader;


%% Read in file

% definitions
numCharRead = 65536;    % minimum number of characters to read
minLines    = 10;       % minimum number of lines to read
if isfinite(numHeader)
    minLines = minLines + numHeader;
end
valueRatio  = 0.1;      % this ratio will tell if a row has enough values
anaFormat   = '%f';     % assume floats only (so far)

hasFileErr  = false;    % init
anaFileErr  = '';       % init

fid = fopen(ffn); 
if filePos > 0
    status = fseek(fid,filePos,'bof');
    if status ~= 0
        hasFileErr = true;
        anaFileErr = ferror(fid,'clear');
    end
end

if ~hasFileErr
    % detect line termination character
    lbfull = detectLineBreakCharacters(ffn);
    lbuint = lbfull(end);        
    lbchar = char(lbuint);
    % read in the first part of the file
    [f8,numLb,posLb] = getLines(fid, minLines, numCharRead, 0, 0, false, lbfull);
    % getLines get a set of consecutive lines from file
    % [hl,numLb,posLb,isAtEnd] = getLines(fid, minLines, minChars, offset, ...
    %                                  origin, inclWsAtEnd, lbfull, lenSection)

end
fclose(fid); 

% care for some exceptions
if hasFileErr
    anaErr = 'file operation error';
    return
end
if isempty(f8)
    anaErr = 'empty file';
    return
end
if numLb <= numHeader
    anaErr = 'file has not more lines than given number of header lines';
    return
end

% remember the original text before deletions and replacements
f8Orig    = char(f8.');
posLbOrig = posLb;

if numHeader > 0
    % select post-header-part of f8
    f8 = f8(posLb(numHeader+1):end);    
    numLb = numLb - numHeader;
    posLb = posLb(numHeader+1:end) - posLb(numHeader+1);
end

%% filter lines (rows)

doFilter = arg.has.SelectLineFun || (numBL + numGL > 0);
if doFilter
    [f8, posLb, numLb, ~, isOk] = filterLines(f8, lbuint, numCharRead, arg);
end


%% Replace regular expressions, strings, and characters, if needed
        
if numRS>0 || numRC>0 || numRR>0
    
    % If a ReplaceStr begins with a line break character, such a character
    % will temporarily be prepended to apply the replacement to the _first_
    % line, too.
    prependChar = '';       % prepend nothing by default
    if numRS>0
        % put all the characters from the ReplaceStr strings into an
        % uint8-array:
        uint8Replace = uint8(char([repStr{:}]));
        % check if any row starts with a line break:
        if any(uint8Replace(:,1)==lbuint)
            prependChar = lbchar;
        end
    end
    numPrepend = numel(prependChar);
    
    f8=[prependChar, char(f8.')];
    
    if numRR>0
        for vdx = 1:numRR       % step through regex replacement arguments 
            srarg = repReg{vdx};    % pick a single replacement argument
            for sdx = 1:(numel(srarg)-1)
                f8 = regexprep(f8, srarg{sdx}, srarg{end}); % replace it
            end
        end
    end

    if numRS>0
        for vdx = 1:numRS     	% step through string replacement arguments 
            srarg = repStr{vdx};    % pick a single replacement argument
            for sdx = 1:(numel(srarg)-1)
                f8 = strrep(f8, srarg{sdx}, srarg{end});    % replace it
            end
        end
    end

    if numRC>0
        for vdx = 1:numRC     	% step through char replacement arguments
            srarg = repChar{vdx}; 	% pick a single replacement argument
            for sdx = 1:(numel(srarg)-1)
                f8( strfind(f8,srarg(sdx)) ) = srarg(end);  % replace it
            end
        end
    end
    
    f8 = uint8(f8(1+numPrepend:end).');
    % update line break indices
    isLB   = f8==lbuint;
    posLb  = [0;find(isLB)];
    numLb  = numel(posLb)-1;
end

%% Find character types

% further representations of the text as required below
f8c      = char(f8.');
f8d      = double(f8.');

% types of characters:
prnAscii = uint8([32:127, 128+32:255]);                 % printable ASCIIs
dec_nr_p = sort(uint8('+-1234567890dDeE.NanIiFfA'));    % decimals with NaN, Inf, signs and .
sep_wo_k = uint8([9 32    47 58 59]);   	% separators excluding comma  
sep_wi_k = uint8([9 32 44 47 58 59]);   	% separators including comma (Tab Space ,/:;)
komma    = uint8(',');               	% ,
other    = setdiff(prnAscii, [sep_wi_k, dec_nr_p]); % printables without separators and decimals

% characters not expected to appear in the data lines:
is_othr = ismembc(f8d,double(other));       % switch to double for compatibility 
is_beg_othr = diff([false, is_othr]);       % true where groups of such characters begin
idc_beg_othr = find(is_beg_othr==1);        % start indices of these groups
[~, sidx] = sort([posLb(2:end).',idc_beg_othr]);     % in sidx, the numbers (1:num_lb) representing the linebreaks are placed between the indices of the start indices from above
num_beg_othr_per_line = diff([0,find(sidx<=numLb)]) - 1;   % number of character groups per line

% numbers enclosing a dot:
% idc_digdotdig = regexp(f8c, '[\+\-]?\d+\.\d+([deDE][\+\-]?\d+)?', 'start');
idc_digdotdig = regexp(f8c, '[\+\-]?\d+\.\d+([deDE][\+\-]?\d+)?');
[~, sidx] = sort([posLb(2:end).',idc_digdotdig]);
num_beg_digdotdig_per_line = diff([0,find(sidx<=numLb)]) - 1;

% numbers enclosing a comma:
% idc_digkomdig = regexp(f8c, '[\+\-]?\d+,\d+([eE][\+\-]?\d+)?', 'start');
idc_digkomdig = regexp(f8c, '[\+\-]?\d+,\d+([eE][\+\-]?\d+)?');
[~, sidx] = sort([posLb(2:end).',idc_digkomdig]);
num_beg_digkomdig_per_line = diff([0,find(sidx<=numLb)]) - 1;

% numbers without a dot or a comma:
% idc_numbers = regexp(f8c, '[\+\-]?\d+([eE][\+\-]?\d+)?', 'start');
idc_numbers = regexp(f8c, '[\+\-]?\d+([eE][\+\-]?\d+)?');
[~, sidx] = sort([posLb(2:end).',idc_numbers]);
num_beg_numbers_per_line = diff([0,find(sidx<=numLb)]) - 1;

% NaN and Inf items :
idc_nan = regexpi(f8c, '\<[\+\-]?(nan|inf)\>');
[~, sidx] = sort([posLb(2:end).',idc_nan]);
num_beg_nan_per_line = diff([0,find(sidx<=numLb)]) - 1;

% commas enclosed by numeric digits
% idc_kombd = regexp(f8c, '(?<=[\d]),(?=[\d])', 'start');
% if compareversion(vn,7)
%     idc_kombd = regexp(f8c, '(?<=[\d]),(?=[\d])');  % lookaround new to v7.0??
% else
    idc_kombd = 1+regexp(f8c, '\d,\d');
% end
[~, sidx] = sort([posLb(2:end).',idc_kombd]);
num_beg_kombd_per_line = diff([0,find(sidx<=numLb)]) - 1;

% two sequential commas without a (different) separator inbetween
% idc_2kom  = regexp(f8c, ',[^\s:;],', 'start');
idc_2kom  = regexp(f8c, ',[^\s:;/],');

% commas:
is_kom  = f8.'==komma;
idc_kom = find(is_kom);
[~, sidx] = sort([posLb(2:end).',idc_kom]);
num_kom_per_line = diff([0,find(sidx<=numLb)]) - 1;


%% Analyze

if isnan(numHeader) % ~~~~~ there's no user-supplied number of header lines
    % determine number of header lines:
    numHeader = max([0, find(num_beg_othr_per_line>0)]); % for now, take the last line containing an 'other'-character 
    if numHeader>=numLb
        anaErr = 'no numeric data found';
        if numHeader>0
            anaHeader = char(f8(1:posLb(numHeader+1)));
        end
        return
    end
    num_beg_numbers_ph = num_beg_numbers_per_line(numHeader+1:end)+num_beg_nan_per_line(numHeader+1:end);    % number of lines following
    % by definition, a line is a valid data line if it contains enough
    % numbers compared to the average:
    has_enough_numbers = num_beg_numbers_ph>valueRatio.*mean(num_beg_numbers_ph);  
    numHeader = numHeader + find(has_enough_numbers, 1 ) - 1; 
    % extract header and data section
    if numHeader>0    
        f8v_idx1 = posLb(numHeader+1)+1; % beginning of the data section in f8
        if doFilter
            % reconstruct number of header lines from the original text
            anaNumHeader = find(cumsum(isOk)==numHeader,1,'first');
        else
            anaNumHeader = numHeader;
        end
        anaHeader = f8Orig(1:posLbOrig(anaNumHeader+1));
    else
        f8v_idx1 = 1;
        anaHeader = [];
        anaNumHeader = 0;
    end
    f8 = f8(f8v_idx1:end);	% valid data section of f8
    anaNumAnalyzed = numLb - numHeader;	% number of non-header lines to analyse
else % ~~~~~~~~~~~~~~~ a number of header lines was given as input argument
    if numHeader>0
        anaHeader = f8Orig(1:posLbOrig(numHeader+1));
    else
        anaHeader = [];
    end
    anaNumAnalyzed = numLb;
end

% find out decimal separator character ('.' or ',')
anaRepChar = {};    % Init. replacement character string
SR_idx     = 0;     % Init. counter of the above
sepchar    = '';    % Init. separator (delimiter) character
decchar    = '.';   % Init. decimal character (default)

num_values_per_line = -num_beg_digdotdig_per_line + num_beg_numbers_per_line;

% Are there commas? If yes, are they decimal commas or delimiters?
if any( num_kom_per_line(numHeader+1:end) > 0 ) 
    sepchar = ',';  % preliminary take comma for delimiter
    % Decimal commas are neighboured by two numeric digits ...
    % and between two commas there has to be another separator
    if  all(num_kom_per_line(numHeader+1:end) == num_beg_kombd_per_line(numHeader+1:end)) ... % Are all commas enclosed by numeric digits?
        && ~any(num_beg_digdotdig_per_line(numHeader+1:end) > 0) ...   % There are no numbers with dots?
        && ~any(idc_2kom(numHeader+1:end) > 0)                         % There is no pair of commas with no other separator inbetween?

        decchar = ',';
        sepchar = '';
        
        num_values_per_line = -num_beg_digkomdig_per_line + num_beg_numbers_per_line; % number of values per line
    end
end

% replacement string for replacements by spaces
% other separators
is_wo_k_found = ismember(sep_wo_k, f8);  % Tab Space : ;
is_other_found= ismember(other,f8);      % other printable ASCIIs

% possible replacement string to replace : and ;
sr1 = [sepchar, char(sep_wo_k([0 0 1 1 1]&is_wo_k_found))];   
% possible replacement string to replace other characters
sr2 = char(other(is_other_found));        % still obsolete as such lines are treated as header lines
                                          % Wrong! The above is not true if
                                          % the number of header lines is
                                          % given by the user.

if numel([sr1,sr2])>0
    SR_idx = SR_idx + 1;
    anaRepChar{SR_idx} = [sr1, sr2, ' '];
end

% possible replacement string to replace the decimal character
if strcmp(decchar,',')
    SR_idx = SR_idx + 1;
    anaRepChar{SR_idx} = ',.';
end

num_items_per_line = num_values_per_line + num_beg_nan_per_line;

anaNumColon = max(num_items_per_line(numHeader+1:end));    % proposed number of columns

if isempty(anaNumColon)
    anaErr = 'no numeric data found';
    return
end

% suggest a proper read mode depending on uniformity of the number of values per
% line
if numel(unique(num_items_per_line(numHeader+1:end))) > 1
    anaReadMode = 'line';
    anaNumColon = -anaNumColon;
else
    anaReadMode = 'auto';
end

%% : : : : : further subfunctions : : : : : 

function s = strcatcell(C)

% STRCATCELL Concatenate strings of a 1D/2D cell array of strings
%
% C = {'a ','123';'b','12'}
%   C = 
%     'a '    '123'
%     'b'     '12' 
% s = strcatcell(C)
%   s =
%     a 123
%     b 12 

num_col = size(C,2);
D = cell(1,num_col);
for idx = 1:num_col
    D{idx} = char(C{:,idx});
end
s = [D{:}];


function [w, newidcoi, vi] = cutvec(v,li,hi,doKeep,varargin)

% CUTVEC remove multiple sections from a vector by linear index intervals
%
% Syntax:
%   w = cutvec(v,li,hi,doKeep)
% OR
%   [w, new_idc_oi, vi] = ...
%       cutvec(v,li,hi,doKeep,old_idc_oi)
%
% v             input vector
% li            lower endpoints of linear index intervals (sorted vector)
% hi            upper endpoints of linear index intervals (sorted vector)
% doKeep        true:   remove values outside all intervals
%               false:  remove values within all intervals
% old_idc_oi    indices of interest in v (optional)
% 
% w             output vector consisting of v-sections
% new_idc_oi    corresponding indices of interest in w
% vi            logical matrix with w=v(vi)
%
% Inputs li, hi and doKeep may also be cell arrays of equal size holding
% multiple sets of index endpoints and logicals.
%
% EXAMPLE:
%
% w = cutvec([1:20],[3,10,16],[7,12,19],1)
%
%   =>  w = [3 4 5 6 7   10 11 12   16 17 18 19]
%
% w = cutvec([1:20],[3,10,16],[7,12,19],0)
%
%   =>  w = [1 2   8 9   13 14 15   20]
%
% w = cutvec([1:20],{[3,10,16],[1,15]},...
%                    {[7,12,19],[5,20]},{0,1})
%
%   =>  w = [1 2   15   20]
%
% tic, w = cutvec([1:5000000]',[100:500:5000000],[200:500:5000000],0); toc
% 
% % Elapsed time is 0.202949 seconds.
%
% v = 1:20;
% li= [10,18];
% hi= [12,19];
% doKeep = 0;
% idcoi = [1,4,7,10,13,18,20];
% 
% [w, newidcoi, vi] = cutvec(v,li,hi,doKeep,idcoi)

%   $Revision: 1.23 $ 

lenV   = numel(v);
has_idcoi = false;
newidcoi=[];

if nargin == 5  % indices of interest are provided
    idcoi   = int32(varargin{1});
    if ~issorted(idcoi)
        error([mfilename ': vector of indices of interest must be sorted!'])
    end
    has_idcoi = true;
end

if iscell(li)
    vi = endpoint2logical(lenV,li{1},hi{1},logical(doKeep{1}));
    for ci = 2:numel(li)
        vi = vi & endpoint2logical(lenV,li{ci},hi{ci},logical(doKeep{ci}));
    end
else
    vi = endpoint2logical(lenV,li,hi,logical(doKeep));
end

if has_idcoi
    remidc   = int32(find(vi));
    newidcoi = ismembc2(idcoi,remidc);
end

w = v(vi);


function vi = endpoint2logical(len,li,hi,doInclude)

% ENDPOINT2LOGICAL convert endpoints of index intervals to logical index
%
% Syntax:
%   vi = endpoint2logical(len,li,hi,doInclude)
%
% with
%
% len           length of logical index vector
% li            vector with lower endpoints of linear index intervals
% hi            vector with upper endpoints of linear index intervals
% doInclude     true:  logical indices are 1 only inside  the intervals
%               false: logical indices are 1 only outside the intervals
%
% vi            logical index vector

% initialize output:
if doInclude
    vi = false(len,1);
else
    vi = true(len,1);
end

for i = 1:numel(li)
    vi(li(i):hi(i)) = doInclude;
end


function arg = argincheck(allargin)

% ARGINCHECK get input arguments for txt2mat
%
% arg = argincheck(allargin)
% provides input argument information in struct arg with fields
%       arg.val.(argname)  ->  value of the input
%       arg.has.(argname)  ->  T/F argument was given
%       arg.num.(argname)  ->  number of values for some non-scalar inputs

% Check input argument occurence (Property/Value-pairs)
%  1 'NumHeaderLines',     Scalar,     13
%  2 'NumColumns',         Scalar,     100
%  3 'Format',             String,     ['%d.%d.%d' repmat('%f',1,6)]
%  4 'ReplaceChar',        CellAString {')Rx ',';: '}
%  5 'BadLineString'       CellAString {'Warng', 'Bad'}
%  6 'ReplaceStr',         CellAString {{'True','1'},{'False','0'},{'#Inf','Inf'}}
%  7 'DialogString'        String      'Now choose a Labview-Logfile'
%  8 'MemPar'              2x1-Vector  [2e7, 2e5]
%  9 'InfoLevel'           Scalar      2
% 10 'ReadMode'            String      'Auto'
% 11 'NumericType'         String      'single'
% 12 'RowRange'            2x1-Vector  [1,Inf]
% 13 'FilePos'             Scalar      1e5
% 14 'ReplaceRegExpr'      CellArOfStr {{'True','1'},{'False','0'},{'#Inf','Inf'}} 
% 15 'GoodLineString'      CellAString {'OK'}
% 16 'SelectLineFun'       FunHandle   @(rowNo) rem(rowNo-1,2) < 1

% check for validated argument struct as last input to bypass further input
% parsing (undocumented, untested -> todo)
hasValidatedArgStruct = false;  % default
if ~isempty(allargin) && isstruct(allargin{end})
    argStruct = allargin{end};
    if isfield(argStruct,'isValidated') && argStruct.isValidated
        hasValidatedArgStruct = true;
    end
end

if hasValidatedArgStruct
    % carry over validated inputs
    arg = argStruct;
else
    %-- main input parsing
    p = inputParser;
    p.KeepUnmatched = true;
    p.FunctionName = 'txt2mat';
    %-- optional inputs that follow the file name
    p.addOptional(  'NumHeaderLines', NaN , @(x)isempty(x)||(isnumeric(x)&&isscalar(x)))
    p.addOptional(  'NumColumns'    , []  , @(x)isempty(x)||(isnumeric(x)&&isscalar(x)))
    p.addOptional(  'Format'        , '%f', @(x)isempty(x)||(ischar(x)&&any(x=='%')))
    p.addOptional(  'ReplaceChar'   , {}  , @(x)isempty(x)||iscellstr(x)||ischar(x))
    p.addOptional(  'BadLineString' , {}  , @(x)isempty(x)||iscellstr(x))
    %-- param/value only inputs:
    p.addParamValue('SelectLineFun' , {}  , @(x)isa(x,'function_handle'))
    p.addParamValue('GoodLineString', {}  , @(x)isempty(x)||iscellstr(x))
    p.addParamValue('ReplaceStr'    , {}  , @(x)isempty(x)||iscell(x))
    p.addParamValue('ReplaceRegExpr', {}  , @(x)isempty(x)||iscell(x))
    p.addParamValue('NumericType'   , 'double', @(x)ischar(x))
    p.addParamValue('RowRange'      , [1,Inf] , @(x)isnumeric(x)&&(numel(x)==2))
    p.addParamValue('FilePos'       , 0   , @(x)isnumeric(x)&&isscalar(x))
    p.addParamValue('ReadMode'      , 'auto', @(x)ischar(x))
    p.addParamValue('DialogString'  , 'Select File', @(x)ischar(x))
    p.addParamValue('InfoLevel'     , 2   , @(x)isnumeric(x)&&isscalar(x))
    p.addParamValue('MemPar'        , 65536, @(x)isnumeric(x)&&isscalar(x))
    %-- older param names, still accepted
    p.addParamValue('ConvString'    , '%f', @(x)isempty(x)||ischar(x))
    p.addParamValue('ReplaceExpr'   , {}  , @(x)isempty(x)||iscell(x))
    %-- parse inputs:
    p.parse(allargin{2:end})

    % rearrange input argument parsing results to a nested struct called
    % 'arg', with
    % arg.val.(name) holding the values of the inputs
    % arg.has.(name) indicating whether the input was given (t/f)
    if ~isempty(fieldnames(p.Unmatched))
        ufn = fieldnames(p.Unmatched);
     	warning('txt2mat:unmatchedArg', ...
                ['Unmatched input parameter names were ignored ("'  ufn{1} '").'])
    end
    arg.val   = p.Results;
    defnames  = p.UsingDefaults;
    argnames  = fieldnames(arg.val);
    isdefcell = [argnames.'; repmat({true},1,numel(argnames))];
    arg.has   = struct(isdefcell{:});
    for k = defnames
        arg.has.(k{:}) = false;
    end
    
    % ~~~ additional checks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    % error if both old and new param names occur, accept if solely old one
    % 'ConvString' -> 'Format'
    if arg.has.ConvString && arg.has.Format
        error('txt2mat:deprecatedConvString', ...
              'use param name ''Format'' only (instead of ''ConvString'')');
    elseif arg.has.ConvString
        arg.has.Format = arg.has.ConvString;
        arg.val.Format = arg.val.ConvString;
    end
    % 'ReplaceExpr' -> 'ReplaceStr'
    if arg.has.ReplaceExpr && arg.has.ReplaceStr
        error('txt2mat:deprecatedReplaceExpr', ...
              'use param name ''ReplaceStr'' only (instead of ''ReplaceExpr'')');
    elseif arg.has.ReplaceExpr
        arg.has.ReplaceStr = arg.has.ReplaceExpr;
        arg.val.ReplaceStr = arg.val.ReplaceExpr;
    end
    
    % NumHeaderLines must be a nonnegative integer.
    if arg.has.NumHeaderLines && arg.val.NumHeaderLines < 0 && ...
            arg.val.NumHeaderLines ~= round(arg.val.NumHeaderLines)
        error('txt2mat:wrongNumHeaderLines', ...
              'NumHeaderLines must be a nonnegative integer.')
    end
    
    % NumColumns must be an integer scalar.
    if arg.has.NumColumns && ...
            arg.val.NumColumns ~= round(arg.val.NumColumns)
        error('txt2mat:wrongColumns', ...
              'NumColumns must be integer.')
    end

    % change empty format string to default
    if isempty(arg.val.Format)
        arg.val.Format = '%f';
    end

    % wrap a single string ReplaceChar into a cell
    if ischar(arg.val.ReplaceChar)
        arg.val.ReplaceChar = {arg.val.ReplaceChar};
        %warning('txt2mat:ineptReadmode', ...
        %    'for future versions, please use a cell array of strings for character replacements.')
    end
    arg.num.ReplaceChar    = numel(arg.val.ReplaceChar);

    % add number of bad and good line strings
    arg.num.BadLineString  = numel(arg.val.BadLineString);
    arg.num.GoodLineString = numel(arg.val.GoodLineString);
    
    % add numbers of string and regular expression replacements
    arg.num.ReplaceStr     = numel(arg.val.ReplaceStr);
    arg.num.ReplaceRegExpr = numel(arg.val.ReplaceRegExpr);
    
    % check if ReplaceStr is empty or has correct Find+Replace string pairs
    if arg.has.ReplaceStr && ~isempty(arg.val.ReplaceStr) && ~( ...
       ( iscellstr(arg.val.ReplaceStr)&&(numel(arg.val.ReplaceStr)==2) ) ...
       || all(cellfun(@(x)iscellstr(x)&&(numel(x)==2),arg.val.ReplaceStr)) )
        error('txt2mat:ReplaceStr', ...
              'ReplaceStr must be a cell array of two-element cell arrays of strings.')
    end

    % check if ReplaceRegExpr is empty or has correct Find+Replace string pairs
    if arg.has.ReplaceRegExpr && ~isempty(arg.val.ReplaceRegExpr) && ~( ...
       (iscellstr(arg.val.ReplaceRegExpr)&&(numel(arg.val.ReplaceRegExpr)==2)) ...
       || all(cellfun(@(x)iscellstr(x)&&(numel(x)==2),arg.val.ReplaceRegExpr)) )
        error('txt2mat:ReplaceRegExpr', ...
              'ReplaceRegExpr must be a cell array of two-element cell arrays of strings.')
    end

    % force ReadMode to 'line' if NumColumns < 0
    if arg.has.NumColumns && arg.val.NumColumns < 0
        arg.val.ReadMode = 'line';
        if arg.has.ReadMode && ~strcmpi(arg.val.ReadMode,'line')
            warning('txt2mat:changedReadmode', ...
                'ReadMode is changed to ''line'' as NumColumns is negative.')
        end
    end
    
    % further checks on RowRange
    if arg.has.RowRange  && ~issorted(arg.val.RowRange) && ...
       any(arg.val.RowRange ~= round(arg.val.RowRange)) && ...
       arg.val.RowRange(1) < 1
        error('txt2mat:wrongRowRange', ...
              'RowRange must be a sorted positive integer 2x1 vector.')
    end
        
    % further checks on FilePos
    if arg.has.FilePos  &&  arg.val.FilePos < 0 && ...
       any(arg.val.FilePos ~= round(arg.val.FilePos))
        error('txt2mat:wrongFilePos', ...
              'FilePos must be a nonnegative integer.')
    end
    
    % further checks on SelectLineFun
    if arg.has.SelectLineFun
        try
            SlfTest = arg.val.SelectLineFun((1:8).');
        catch err
        error('txt2mat:errorSelectLineFun', ...
              'SelectLineFun error on test data (1:8).''')
        end
        if numel(SlfTest)~=8
            error('txt2mat:wrongSelectLineFun', ...
              'SelectLineFun must preserve length of input (test data: (1:8).'')')
        elseif ~islogical(SlfTest)
            warning('txt2mat:SelectLineFunNonLogical', ...
                ['SelectLineFun output should be logical, but it is ' class(SlfTest) ])
        end
    end
        
    % ~~~ additional checks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ end ~
            
    % confirm arg struct validation for repeated usage (future version)
    arg.isValidated = true;
end

% add file name
if numel(allargin) >= 1
    arg.val.FileName = allargin{1};
    arg.has.FileName = true;
else
    arg.val.FileName = '';
    arg.has.FileName = false;
end


function lb = detectLineBreakCharacters(ffn)

% DETECTLINEBREAKCHARACTERS find out type of line termination of a file
%
% lb = detectLineBreakCharacters(ffn)
%
% with
%   ffn     ascii file name
%   lb      line break character(s) as uint8, i.e.
%           [13 10]     (cr+lf) for standard DOS / Windows files
%           [10]        (lf) for Unix files
%           [13]        (cr) for Mac files
%
% The DOS style values are returned as defaults if no such line breaks are
% found.

% www.editpadpro.com/tricklinebreak.html :
% Line Breaks in Windows, UNIX & Macintosh Text Files
% A problem that often bites people working with different platforms, such
% as a PC running Windows and a web server running Linux, is the different
% character codes used to terminate lines in text files. 
% 
% Windows, and DOS before it, uses a pair of CR and LF characters to
% terminate lines. UNIX (Including Linux and FreeBSD) uses an LF character
% only. The Apple Macintosh, finally, uses a CR character only. In other
% words: a complete mess.

lfuint   = uint8(10);       % LineFeed
cruint   = uint8(13);       % CarriageReturn
crlfuint = [cruint,lfuint];
lfchar   = char(10);
crchar   = char(13);
crlfchar = [crchar,lfchar];
readlen  = 16384;

% Cycle through file and read until we find line termination characters or
% we reach the end of file. 
% Possible line breaks are: cr+lf (default), lf, cr

logfid = fopen(ffn); 
has_found_lbs = false;
while ~has_found_lbs

    [f8,cntr] = fread(logfid,readlen,'*char');

    pos_crlf = strfind(f8',crlfchar);
    pos_lf   = strfind(f8',lfchar);
    pos_cr   = strfind(f8(1:end-1)',crchar);
    % here we ignored a cr at the end as it might belong to a cr+lf
    % combination (later we'll step back one byte in the file position to
    % avoid overlooking such a single cr)

    num_lbs = [numel(pos_crlf),numel(pos_lf),numel(pos_cr)];

    if all(num_lbs==0)
        fseek(logfid, -1, 0);    % step back one byte
        
        % if we reached the end of file without finding any special
        % character, set the endmost line break character and the complete
        % line break character to DOS values as defaults
        if cntr < readlen
            has_found_lbs = true;   % just to exit the while loop
            lb = crlfuint;          % complete line break character set
        end
    elseif num_lbs(1)>0
        has_found_lbs = true;
        lb = crlfuint;
    elseif num_lbs(2)>0
        has_found_lbs = true;
        lb = lfuint;
    elseif num_lbs(3)>0
        has_found_lbs = true;
        lb = cruint;
    end
end
fclose(logfid); 

function [txt, posLb0, cntLbMod, idxSecEndLb, isOk] = ...
    filterLines(txt, uintLb, startLenSbs, arg)

% FILTERLINES loop through sections of txt and remove unwanted lines
% 
% [txt, posLb0, cntLbMod, idxSecEndLb, isOk] = ...
%                                filterLines(txt, uintLb, startLenSbs, arg)
% 
% Inputs: 
%   txt         uint8 representation of the original char string
%   uintLb      line break character as uint8
%   startLenSbs initial subsection length
%   arg         struct with fields
%       has.SelectLineFun   logical, tells if a selection function exists
%       val.SelectLineFun   function for line selection
%       val.GoodLineString  cell with good line marker strings
%       val.BadLineString   cell with bad line marker strings
%
% Outputs:
%   txt         uint8 representation of modified char string
%   posLb0      line break positions in modified txt (starting with 0)
%   cntLbMod    number of lines in modified txt
%   idxSecEndLb posLb0(idxSecEndLb) are the positions of the line breaks
%               at the section borders
%   isOk        true: line from input txt is kept, false: line is removed

% some abbreviations:
goodStr = arg.val.GoodLineString;
badStr  = arg.val.BadLineString;
numGood = numel(goodStr);
numBad  = numel(badStr);

% initializations for the text section loop
doRead   = true;
idxRdLo  = 0;	% idxRdLo: start index of a full section to be read from 
                %     inside original txt (equals last line break position
                %     from previous section)  
                % iTxtLo, iTxtHi: indices of a subsection inside txt
             	% iSecLo, iSecHi: indices of a subsection inside a section 
idxWrLo  = 0;   % start index of a modified section to be written to txt
cntLbTxt = 0;   % counts lines in original txt
cntLbMod = 0;   % counts lines in modified txt
cntSec   = 0;   % counts sections in original txt
cntSecMod= 0;   % counts sections in modified txt
lenWork  = max(2,startLenSbs); % set initial subsection length to at least 2
numTxt   = numel(txt);
while doRead        % loop through text sections
    cntSec  = cntSec + 1;
    
    % prepare building a section of txt that contains line breaks
    workSec = zeros(lenWork,1, 'uint8');    % initialize content of section
    isLbSec = false(lenWork,1);      % will be true at line break positions

    % loop through subsections until at least one line break is found to
    % ensure we have complete lines in the current section
    hasNoLb = true;
    iSecHi  = 0;
    while hasNoLb   
        iSecLo 	= iSecHi+1;
        iSecHi	= iSecLo + lenWork - 1;
        iTxtLo  = idxRdLo + iSecLo;
        [iTxtHi,ci] = min([numTxt,idxRdLo + iSecHi]);
        workSbs = txt(iTxtLo:iTxtHi);               % current subsection
        isLbSbs = workSbs==uintLb;                  
        workSec(iSecLo:iTxtHi-idxRdLo) = workSbs; 	% add text to section
        isLbSec(iSecLo:iTxtHi-idxRdLo) = isLbSbs;  	% add line break t/f
        doRead  = ci > 1;
        hasNoLb = ~any(isLbSbs) & ci > 1;
    end
    lenWork    = iTxtHi-idxRdLo;  	% adapt future length of subsections
    posLbSec   = find(isLbSec);   	% line break positions in current section
    posLbSec0  = [0; posLbSec];   	% ", prepend zero
    lenLineSec = diff(posLbSec0);  	% length of line (in characters)
    numLbSec   = numel(posLbSec); 	% number of line breaks in current section
    lenSec     = posLbSec(end);   	% position of last line break
    workSec    = workSec(1:lenSec);	% crop section to last line break
    idxRdLo    = idxRdLo + lenSec;  % set start index for next iteration
    
    % initialize vector holding all line break positions in modified txt,
    % including a zero at the beginning (posLb0), and a vector indexing the
    % end-of-section line breaks inside it (idxSecEndLb)
    if cntSec == 1	
        posLb0 = zeros(ceil(numLbSec/lenSec*numTxt)+1,1);
        idxSecEndLb = ones(max(2,ceil(numTxt/lenSec)),1);
    end
        
    % ~~~ line selection by function and good/bad line strings ~~~~~~~~~~~~

    % apply the selection function on the current line numbers
    if arg.has.SelectLineFun
        % test line numbers to decide which lines (i.e. rows) to keep
        % we must use the original line numbers from txt here
        isLineSel = arg.val.SelectLineFun((cntLbTxt+1:cntLbTxt+numLbSec).');
    else
        isLineSel = true(numLbSec,1);   % do not remove any lines
    end
  
    % Find lines marked good or bad.
    % Start with the good line marker strings.
    if numGood > 0
        idcGoodCurr = cell(numGood,1);
        for k = 1:numGood
            % find positions of the current marker in the current section:
            idcGoodCurr{k} = strfind(char(workSec.'),goodStr{k}).';
        end
        % ~~ get the corresponding line break positions... ~~~~~~~~~~~~~~~~
        % sort all marker positions found and remove doublets
        idcGoodAll = unique(cat(1,idcGoodCurr{:}));
        % see how they sort into the sorted vector of line break positions
        [~,ix] = sort([idcGoodAll; posLbSec0]);
        % a line break position that is no longer followed directly by
        % another line break position but by one or more marker positions
        % denotes a line containing at least one marker string
        [~,ix] = sort(ix);
        isLineGood = diff(ix(numel(idcGoodAll)+1:end))>1;
        % ~~ ...done. (Is there a faster solution??) ~~~~~~~~~~~~~~~~~~~~~~
    else
        isLineGood = true(numLbSec,1);
    end
    % Then do the same for the bad line marker strings.
    if numBad > 0
        idcBadCurr = cell(numBad,1);
        for k = 1:numBad
            idcBadCurr{k} = strfind(char(workSec.'),badStr{k}).';
        end
        idcBadAll = unique(cat(1,idcBadCurr{:}));
        [~,ix] = sort([idcBadAll; posLbSec0]);
        [~,ix] = sort(ix);
        isLineNotBad = diff(ix(numel(idcBadAll)+1:end))==1;
    else
        isLineNotBad = true(numLbSec,1);
    end
    
    % ~~~ combine selection critera and update txt ~~~~~~~~~~~~~~~~~~~~~~~~
    
    isLineOk = isLineSel & isLineGood & isLineNotBad;
    
    if nargout > 4
        if cntSec == 1	
            isOk = false(ceil(numLbSec/lenSec*numTxt)+1,1);
        end
        isOk(cntLbTxt+1:cntLbTxt+numLbSec) = isLineOk;
    end
    
    % update line break counter for original txt (to remind the numbers for
    % the selection function and to have the indices for isOk output)
    cntLbTxt = cntLbTxt + numLbSec; 
    
    
    if all(isLineOk)	% no lines of the current section will be removed
        if cntSec > 1
            % write section to new position into txt
            txt(idxWrLo+1:idxWrLo+lenSec) = workSec;
        end
        % collect line break positions of modified txt
        posLb0(cntLbMod+2:cntLbMod+numLbSec+1) = idxWrLo+posLbSec;
        % count line breaks in modified txt
        cntLbMod    = cntLbMod + numLbSec;
        % start index of next txt write
        idxWrLo = idxWrLo + lenSec;
        % define a new section inside the modified txt
        cntSecMod = cntSecMod + 1;
        % index for the section ends in posLb0
        idxSecEndLb(cntSecMod+1) = idxSecEndLb(cntSecMod)+numLbSec;
    elseif any(isLineOk)	% some lines will be removed
        lenLineOk = lenLineSec(isLineOk);
        % start and end indices of groups of continguous lines that will remain 
        selL = posLbSec0( [isLineOk(1:end) & ~[false;isLineOk(1:end-1)]; false]  );
        selR = posLbSec0( [false; isLineOk(1:end) & ~[isLineOk(2:end); false]] );
        % update section:
        workSec     = cutvec(workSec,selL+1,selR,true);
        posLbMod    = cumsum(lenLineOk);
        numLbMod    = numel(lenLineOk);
        % write modified section back into txt
        txt(idxWrLo+1:idxWrLo+posLbMod(end)) = workSec;
        % collect line break positions of modified txt
        posLb0(cntLbMod+2:cntLbMod+numLbMod+1) = idxWrLo+posLbMod;
        % count line breaks in modified txt
        cntLbMod    = cntLbMod + numLbMod;
        % start index of next txt write
        idxWrLo = idxWrLo + posLbMod(end);   
        % define a new section inside the modified txt
        cntSecMod = cntSecMod + 1;
        % index for the section ends in posLb0
        idxSecEndLb(cntSecMod+1) = idxSecEndLb(cntSecMod)+numLbMod;
    end
end

% remove overallocated parts from the outputs:
txt         = txt(1:idxWrLo);
posLb0      = posLb0(1:cntLbMod+1);
idxSecEndLb = idxSecEndLb(1:cntSecMod+1);


function [idcLb, cntLb, secLbIdc] = ...
    findLineBreaks(f8, uintLb, lenSection, doFindAll, doCount) 

% FINDLINEBREAKS find line break indices
%
% [idcLb, cntLb, secLbIdc, idcBad] = ...
%               findLineBreaks(f8, uintLb, lenSection, doFindAll, doCount)
%
% This function cycles through a text by manageable sections and finds line
% break characters - either all or just the last one in each section. If
% only the last line break in each section is to be found, findLineBreaks
% can provide the corresponding consecutive number of this line break in
% the text. 
%
% idcLb     	(nx1)-vector. Zero + some or all line break positions in f8
% cntLb         empty or (nx1)-vector. If not all line breaks have to be
%               found, but doCount is true, this is the number of of each
%               line break in f8 that is listed in idcLb (with a zero put
%               in front). Otherwise cntLb is left empty, as cntLb would
%               just be trivially [0:numel(idcLb)]
% secLbIdc      idcLb(secLbIdc) are the positions of the last line
%               break in each section (including the "zero" line break)
%
% f8            the text as an uint8 (Nx1)-vector
% uintLb        uint8-scalar representation of the line break character to
%               be found (10 or 13; could actually be any character). 
% lenSection   	character length of a section
% doFindAll     true: find and index every line break; false: find only the
%               last one in a section
% doCount       count number of every line break in cntLb - this is active
%               only in the non-trivial case when only the last line
%               break in a section has to be found 

%   $Revision: 4.00 $ 

lenF8   = numel(f8);
idxLo 	= 1;   % init., start index of a section processed in a loop
cntLb   = [];

numSection = ceil(lenF8/lenSection);

if doFindAll    % ~~~~~~~~~~~~ find all line break positions ~~~~~~~~~~~~~~
    % In what follows, the text will repeatedly be processed in consecutive
    % sections of length <lenSection> to help avoid memory problems.
    secLbIdc = ones(numSection+1,1); 
    loopCntr = 0;
    lbCntr   = 0;
    while idxLo <= lenF8
        loopCntr = loopCntr + 1;
        idxHi = min(idxLo - 1 + lenSection,lenF8);	% end index of current section

        % find line breaks in current section
        isLb = f8(idxLo:idxHi)==uintLb;
        crPosLb = find(isLb)+idxLo-1;
        numCrLb = numel(crPosLb);
        if loopCntr == 1
            % preallocate idcLb with estimated number of line breaks
            idcLb = zeros((1+numSection+1)*(numCrLb+1), 1);
        end

        % collect line break indices
        idcLb(lbCntr+2:lbCntr+numCrLb+1) = crPosLb;
        
        secLbIdc(loopCntr+1) = numel(idcLb);
        
        idxLo = idxHi + 1;                      % start index for the following loop
        lbCntr = lbCntr + numCrLb;
    end % while
    
    idcLb = idcLb(1:lbCntr+1);
    
else    % ~~~~~~ find last line break position of each section only ~~~~~~~

    % Preallocate maximum space for output variables:
    if doCount
        cntLb = zeros(numSection+1,1);
    end
    idcLb = zeros(numSection+1,1);
    
    lbCntr = 0; % keep in mind how many line breaks have been found,
               	% as some sections might not contain a line break at all

    % Find line break indices within lenSection distance
    while idxLo <= lenF8
        idxHi = min(idxLo - 1 + lenSection,lenF8);   % end index of current section

        % parse backwards to find the last line break of the section
        cntr = 0;
        doKeepOnLooking = true;
        while doKeepOnLooking
            hasNotFound = (f8(idxHi-cntr) ~= uintLb);
            cntr = cntr+1;
            doKeepOnLooking = hasNotFound && (cntr < lenSection);
        end
        
        if ~hasNotFound
            lbCntr = lbCntr + 1;
            % add the line break to the list
            idcLb(lbCntr+1) = idxHi-cntr+1;
            
            % if desired, count all line breaks of the section
            if doCount
                cntLb(lbCntr+1)= cntLb(lbCntr) + sum(f8(idxLo:idxHi)==uintLb); %#ok<AGROW>
            end
        end
        idxLo = idxHi + 1;
    end % while 
    
    % if too much space was preallocated, shorten the outputs:
    if lbCntr<numSection
        idcLb(lbCntr+2:numSection+1) = [];
        if doCount
            cntLb(lbCntr+2:numSection+1) = [];
        end
    end
    
    secLbIdc = (1:numel(idcLb)).';
    
end     % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function [A,a] = initializeMatrix(numRows,numColumns,numericType,doSetNan)

% INITIALIZEMATRIX initialize result matrix A depending on matlab version
%
% [A,a] = initializeMatrix(numRows,numColumns,numericType,...
%                          doSetNan, matlabVersionNumber);
%
% A                     numRows x numColumns - Matrix
% a                     scalar of the same type a A
%
% numRows               nonnegative integer
% numColumns            nonnegative integer
% numericType           numeric type string ('double','single',...)
% doSetNan              logical - if true, set outputs to NaNs rather than
%                       zeros if the numericType allows NaNs

if doSetNan && (strcmpi(numericType,'double') || ...
        strcmpi(numericType,'single'))
    A = NaN(numRows,numColumns,numericType);
    a = NaN;
else
    A = zeros(numRows,numColumns,numericType);
    a = 0;
end


function f8 = cleanUpFinalWhitespace(f8,lbfull)

% CLEANUPFINALWHITESPACE replace final whitespaces by spaces + line break
%
% f8 = cleanUpFinalWhitespace(f8,lbfull)
% with
% f8        text as uint8-vector
% lbfull    full line break characters as uint8-vector

spuint   = uint8(32);   % Space (= ascii whitespace limit) as uint8
num_lbfull = numel(lbfull); 
cnt_trail_white = 0;
is_ws_at_end = true;

while is_ws_at_end  % step through the endmost characters
    if f8(end-cnt_trail_white) <= spuint        % is it a whitespace?
        cnt_trail_white = cnt_trail_white + 1;
    else
        f8(end-cnt_trail_white+1:end) = spuint;	% fill with spaces
        if cnt_trail_white >= num_lbfull
            % replace endmost space(s) by a line break:
            f8(end-num_lbfull+(1:num_lbfull))  = lbfull;    
        else
            % append a final line break:
            f8(end+(1:num_lbfull))  = lbfull;               
        end
        is_ws_at_end = false;
    end
end % while


function [f8, l, pLb, isAtEnd] = getLines(fid,minLines,varargin)

% getLines get a set of consecutive lines from file
% 
% [hl,numLb,posLb,isAtEnd] = getLines(fid, minLines, minChars, offset, ...
%                                  origin, inclWsAtEnd, lbfull, lenSection)
%
% fid           file identifier
% minLines      minimum number of lines to retrieve
% minChars      minimum number of characters to retrieve
%               (optional, default 0)
% offset        file position to start at, relative to origin
%               (optional, default 0)
% origin        (optional) a string whose legal values are
%               'bof'  Beginning of file
%               'cof'  Current position in file (default)
%               'eof'  End of file
% inclWsAtEnd   include a trailing line in the file that consists of white-
%               space only and that is not terminated by a line break
%               (optional, default false)
% lbfull        line termination character(s) as uint8
%               (optional, default [13,10])
% lenSection    (internal) length of a processed section
%               (optional, default 65536)
% 
% hl            the lines from the file as uint8 vector - each line is
%               terminated by a line break, even a final line that was not
%               terminated in the file
% numLb         number of lines, i.e. number of line breaks in hl
% posLb         line break positions in hl, including an added leading zero 
% isAtEnd       true if the end of hl corresponds to the end of file

%   $Revision: 2.11 $ 

% set defaults for opt. inputs:
% minChars, offset,origin,inclWsAtEnd,lbfull,lenSection
optargs = {0, 0, 'cof', false, uint8([13 10]),  65536};

% skip any new inputs if they are empty
isEmptyArg = cellfun('isempty', varargin);

% overwrite defaults with non-emty arguments in varargin
optargs(~isEmptyArg) = varargin(~isEmptyArg);
 
% assign to variables
[minChars, offset, origin, inclWsAtEnd, lbfull, lenSection] = optargs{:};

% move to requested file position
if offset ~= 0 || ~strcmpi(origin,'cof')
	fseek(fid,offset,origin);
end

% get number of the file's remaining bytes from current position:
bytePos = ftell(fid);
fseek(fid, 0, 'eof');
byteEnd = ftell(fid);
fseek(fid, bytePos, 'bof');
numByte = byteEnd-bytePos;
spuint  = uint8(32);   % Space (= ascii whitespace limit) as uint8
lbuint  = lbfull(end);
lenLb   = numel(lbfull);

[f8c,nF8c]	= fread(fid,lenSection,'*uint8');	% current text section

isIn = nF8c < numByte;      % not at the end of text?
pLbc = find(f8c==lbuint); 	% current line break positions
nLbc = numel(pLbc);         % number of line breaks so far
gLb  = max([0;pLbc]);       % greatest line break position

% continue reading if not enough line breaks or characters have been read
% and if we're not at the end of the file
doRead = ((nLbc < minLines) || gLb < minChars) && isIn;

if doRead       % estimate output sizes and preallocate
     f8 = zeros(min( max(ceil(nF8c/nLbc*minLines), minChars), ...
                     numByte),1,'uint8');
     pLb = zeros(max(1+minLines+ceil(nLbc/nF8c), ...
                       ceil(nLbc/nF8c*minChars) ), 1);
end

% start to write to outputs
f8(1:nF8c,1)    = f8c;
pLb(1:nLbc+1,1) = [0;pLbc];


f = nF8c;     % counts number of characters read from fid
l = nLbc;     % counts number of line breaks
while doRead
    % continue to read
    [f8c,nF8c]	= fread(fid,lenSection,'*uint8');	% current text section
    pLbc     	= find(f8c==lbuint);	% position of current line breaks
    nLbc    	= numel(pLbc);          % number   of current line breaks

    % continue to write to outputs
    f8(f+1:f+nF8c)      = f8c;
    pLb(l+2:l+nLbc+1,1)	= f   + pLbc;

    % prepare reading next section
    if nLbc > 0                 % if there are new line breaks...
        gLb = pLb(l+nLbc+1);    % ...update greatest line break position
    end
    f       = f + nF8c;
    l       = l + nLbc;
    isIn    = f < numByte;      % end of text?
    doRead  = ((l < minLines) || (gLb < minChars) ) && isIn;
end

if ((l < minLines) || (gLb < minChars)) && f > 0 && ...
        f8(f) ~= lbuint && ...
            (  inclWsAtEnd || any(f8(pLb(l+1)+1:f) > spuint ) )
    % We're at the end of file but have not yet enough lines and/or chars.
    % Add a line break to the last line if it has none and if it has
    % at least some non-white-space characters (i.e. ignore a final line
    % without a line break that contains only white-space-chars)
    f8(f+1:f+lenLb) = lbfull;
    f          = f+lenLb;
    l          = l + 1;
    pLb(l+1,1) = f;
end

if l < minLines || pLb(1+l) < minChars
    % having read up to the end of the file, delete overallocated parts of
    % pLb and f8 
    pLb = pLb(1:l+1);
    f8  = f8(1:pLb(l+1));
    isAtEnd = true;
else
    % first line break index satisfying minLines and minChars 
    k = minLines + find( pLb(1+minLines:end) >= minChars, 1, 'first');
    % select desired parts and correct file position
    f8  = f8(1:pLb(k));
    pLb = pLb(1:k);
    l   = k-1;
    fseek(fid,pLb(k)-f,'cof');
    isAtEnd = pLb(k) >= numByte;
end