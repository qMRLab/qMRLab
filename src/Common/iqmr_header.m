%MATLAB header parser class
%
%This class generates a header object from the class header containing
%every information in the header of a file that respects the convention.
%
% Properties
%   assumption          Assumptions of the model
%   input               Input arguments of the model
%   output              Output of the functions of the model
%   protocol            Protocol used in the model
%   option              Options that can be changed in the model
%   usage               Usage examples for the model
%   author              Author for the model
%   references          References of the model
%   head                First of the model
%
% Methods
%   header              Constructor of the class header
%   header_parse        Header parser that takes the file name as an
%                         argument and separates every secton of the file 
%                         and saves the different informations 
%
% Organization of the class
%   first column: title of the variable, input, output, option, etc.
%   second column: second title for the option, protocol, etc. if there is
%       one or description
%   third colum: third title for the option, protocol, etc. if there is one
%       or description
%   ...
%
% Author: Gabriel Berestovoy
% References: see other

classdef iqmr_header
    % Description : Properties of the header class.
    % Attributes:    assumption  (cells)
    %               input       (cells)
    %               output      (cells)
    %               protocol    (cells)
    %               option      (cells)
    %               usage       (cells)
    %               author      (cells)
    %               references  (cells)
    %               head        (cells)
    
    properties
        assumption = {};
        input = {};
        output = {};
        protocol = {};
        option = {};
        usage = {};
        author = {};
        references = {};
        head = {};
    end
    methods (Static)
        
        % Description:  header class constructor with input arguments
        % Inputs:       head    (cells)
        %               ass     (cells)
        %               in      (cells)
        %               out     (cells)
        %               prot    (cells)
        %               opt     (cells)
        %               us      (cells)
        %               aut     (cells)
        %               ref     (cells)
        
        function obj = iqmr_header(head,ass,in,out,prot,opt,us,aut,ref)
            obj.head = head;
            obj.assumption = ass;
            obj.input = in;
            obj.output = out;
            obj.protocol = prot;
            obj.option = opt;
            obj.usage = us;
            obj.author = aut;
            obj.references = ref;
        end
        
        % Description:  Header parser for other files
        % Input:        file    (fID)
        % Output:       h       (typename<header>)
        function h = header_parse(file)
            %Set global variables for other functions
            global fields;
            global k;
            global cat;
            global finished;
            global index_descr;
            global index_cat;
            global index_first;
            global index_name;
            
            %Set the initial values of these global variables
            fields = {'Assumptions:','Inputs:','Outputs:','Protocol:','Options:','Command line usage','Author','Reference'};
            k = 1;
            cat = 0;
            finished = 0;
            index_descr = -1;
            index_cat = -1;
            index_first = -1;
            index_name = -1;
            reading = '';
            
            %Opne the file
            filepath = which(file);
            fID = fopen(filepath);
            line = fgets(fID);
            
            %Initialize the temporary cell variables to temporary values
            assumption = {};
            input ={};
            output = {};
            protocol = {};
            option = {};
            usage = {};
            author = {};
            references = {};
            head = {};
            
            %Loop across the file
            while ~feof(fID) && ~finished
                %Check if the header is finished
                if strcmpi(reading,fields(8)) && isempty(strfind(line,'%'))
                    finished = 1;
                end
                %Check for the section that is read in the file
                if strcmpi(line(1), '%') && ~strcmpi(strrep(strrep(line,char(10),''),char(13),''),'%')
                    line = strrep(line,'%','');
                    for i = 1:length(fields)
                        finds = strfind(lower(line),lower(char(fields(i))));
                        if ~isempty(finds)
                            if finds(1)<= 13
                                reading = fields(i);
                                k=1;
                                cat=0;
                            end
                        end
                    end
                    %Go get the informations
                    if strcmpi(reading, '')
                        %Get the first part
                        head = iqmr_header.get_head(head, line);
                        
                    elseif strcmpi(reading,fields(1))
                        %Get the Assumptions
                        assumption = iqmr_header.get_assumption(assumption, line);
                        
                    elseif strcmpi(reading,fields(2))
                        %Get the inputs 
                        input = iqmr_header.get_input(input, line);
                        
                    elseif strcmpi(reading, fields(3))
                        %Get the outputs 
                        output = iqmr_header.get_output(output, line);
                        
                    elseif strcmpi(reading,fields(4))
                        %Get the protocols
                        protocol = iqmr_header.get_protocol(protocol, line);

                    elseif strcmpi(reading,fields(5))
                        %Get the options
                        option = iqmr_header.get_option(option, line);

                    elseif strcmpi(reading,fields(6))
                        %Get the usage
                        usage = iqmr_header.get_usage(usage, line);

                    elseif strcmpi(reading,fields(7))
                        %Get the author
                        author = iqmr_header.get_author(author, line);

                    elseif strcmpi(reading,fields(8))
                        %Get the references
                        references = iqmr_header.get_references(references, line);

                    end
                end
                line = fgets(fID);
            end
            fclose(fID);
            h = iqmr_header(head,assumption,input,output,protocol,option,usage,author,references);
        end
        
        % Description: Get the assumptions from the file
        function a = get_assumption(assumption, line)
            global fields;
            global k;
            
            a = assumption;
            if ~isempty(strfind(lower(line), lower(char(fields(1))))) && strncmpi(strtrim(line),fields(1),length(fields(1)))
            elseif length(line) > 4 && line(4) ~= ' '
                  a{k,1} = line;
                  k = k + 1;
            elseif length(line) > 6 && line(6) ~= ' '
                  a{k-1}= [a{k-1}, line];
            end
        end
        
        % Description: Get the inputs from the file
        function input = get_input(i, line)
            global fields;
            global k;
            global index_descr;
            global index_first;
            
            input = i;
            %Get the inputs 
            [startindex, endindex] = regexp(line, '\s+');
            index_first = 4;
            if ~isempty(startindex) && ~isempty(endindex)
                index_first = endindex(1) - startindex(1) + 2;
            end
            if ~isempty(strfind(line, char(fields(2)))) && strncmpi(strtrim(line),fields(2),length(fields(3)))
                index_descr = 10;
            elseif line(index_first) ~= ' ' && index_first < index_descr
                %input{k,1} = strtrim(extractBetween(line,index_first,endindex(2)));
                input{k,1} = strtrim(line(index_first:endindex(2)));
                if length(line) > 23
                    input{k,2} = strtrim(line(endindex(2):length(line)));
                    index_descr = endindex(2);
                end
                k = k + 1;
            elseif line(endindex(1) + 1) ~= ' '
                input{k-1,2} = [input{k-1,2}, ' ', strtrim(line)];
            end
        end
        
        % Description: Get the outputs from the file
        function output = get_output(ou, line)
            global fields;
            global k;
            global index_descr;
            global index_first;
            
            output = ou;
            [startindex, endindex] = regexp(line, '\s+');
            index_first = 4;
            if ~isempty(startindex) && ~isempty(endindex)
                index_first = endindex(1) - startindex(1) + 2;
            end
            if ~isempty(strfind(line, char(fields(3)))) && strncmpi(strtrim(line),fields(3),length(fields(3)))
                index_descr = 10;
            elseif line(index_first) ~= ' ' && index_first < index_descr
                output{k,1} = strtrim(line(index_first:endindex(2)));
                if length(line) > 23
                    output{k,2} = strtrim(line(endindex(2):length(line)));
                    index_descr = endindex(2);
                elseif length(line) <= 23
                    output{k,1} = [output{k,1}, ' ', strtrim(line(endindex(2):length(line)))];
                end
                k = k + 1;
            elseif line(endindex(1) + 1) ~= ' '
                output{k-1,2} = [output{k-1,2}, ' ', strtrim(line)];
            end  
        end
        
        % Description: Get the protocols from the file
        function protocol = get_protocol(p, line)
            global fields;
            global k;
            global cat;
            global index_descr;
            global index_cat;
            global index_first;
            global index_name;
            
            protocol = p;
            [startindex, endindex] = regexp(line,'\s+');
            index = 1;
            i = 1;
            if exist('index_cat','var') == 0
                index_cat = -1;
                index_name = -1;
                index_first = 4;
            end
            if ~isempty(startindex) && ~isempty(endindex)
                index_first = endindex(1) - startindex(1) + 2;
            end
            if index_cat == 0 
                index_cat = endindex(1) + 1;
            elseif endindex(1) + 1 > index_cat && index_name == 0
                index_name = endindex(1) + 1;
                index_descr = endindex(2) + 1;
            end
            %Check the index at which the description starts
            while i <= length(endindex) && index == 1
                if endindex(i) >= 10 && endindex(i)- startindex(i) > 0
                    index = endindex(i);
                end
                i = i + 1;
            end
            if index == 1
                index = 23;
            end
            if ~isempty(strfind(line, char(fields(4)))) && strncmpi(strtrim(line),fields(4),length(fields(4)))
                index_cat = 0;
                index_name = 0;
                index_descr = 0;
            elseif line(index_cat) ~= ' '
                len = length(line);
                if len > 20
                    protocol{k,1} = strtrim(line(index_cat:index));
                else
                    protocol{k,1} = strtrim(line);
                end
                if length(line) > 21
                    protocol{k,2} = strtrim(line(index:length(line)));
                end
                k = k + 1;
                cat = 1;
            elseif line(index_name) ~= ' '
                protocol{k,3} = strtrim(line(index_name:min(index,end)));
                if length(line) > 23
                    protocol{k,4} = strtrim(line(index:length(line)));
                end
                k = k + 1;
                cat = 0;
            elseif line(index_name) == ' ' && index_first < index_descr
                protocol{k-1,3} = [protocol{k-1,3}, ' ',strtrim(line(index_name:index))];
                if length(line) > 23
                    protocol{k-1,4} = [protocol{k-1,4}, ' ',strtrim(line(index:length(line)))];
                end
            elseif (line(29) ~= ' ' || line(30)) && cat == 1
                protocol{k-1,2} = [protocol{k-1,2} ,' ', strtrim(line)];
            elseif (line(29) ~= ' ' || line(30)) && cat == 0
                protocol{k-1,4} = [protocol{k-1,4} ,' ', strtrim(line)];
            end
        end
        
        % Description: Get the options from the file
        function option = get_option(op, line)
            global fields;
            global k;
            global cat;
            global index_descr;
            global index_cat;
            global index_first;
            global index_name;
            
            option = op;
            [startindex, endindex] = regexp(line,'\s+');
            index = 1;
            i = 1;
            if exist('index_cat','var') == 0
                index_cat = -1;
                index_name = -1;
                index_first = 4;
            end
            if ~isempty(startindex) && ~isempty(endindex)
                index_first = endindex(1) - startindex(1) + 2;
            end
            if index_cat == 0 
                index_cat = endindex(1) + 1;
            elseif endindex(1) + 1 > index_cat && index_name == 0
                index_name = endindex(1) + 1;
                index_descr = endindex(2) + 1;
            end
            %Check the index at which the description starts
            while i <= length(endindex) && index == 1
                if endindex(i) >= 15 && endindex(i)- startindex(i) > 0
                    index = endindex(i);
                end
                i = i + 1;
            end
            if index == 1
                index = 23;
            end
            if ~isempty(strfind(line, char(fields(5)))) && strncmpi(strtrim(line),fields(5),length(fields(5)))
                index_cat = 0;
                index_name = 0;
                index_descr = 0;
            elseif line(index_cat) ~= ' '
                len = length(line);
                if len > 20
                    option{k,1} = strtrim(line(index_cat:index));
                else
                    option{k,1} = strtrim(line);
                end
                if length(line) > 21
                    option{k,2} = strtrim(line(index:length(line)));
                end
                k = k + 1;
                cat = 1;
            elseif line(index_name) ~= ' '
                option{k,3} = strtrim(line(index_name:index));
                if length(line) > 23
                    option{k,4} = strtrim(line(index:length(line)));
                end
                k = k + 1;
                cat = 0;
            elseif line(index_name) == ' ' && index_first < index_descr
                option{k-1,3} = [option{k-1,3}, ' ',strtrim(line(index_name:index))];
                if length(line) > 23
                    option{k-1,4} = [option{k-1,4}, ' ',strtrim(line(index:length(line)))];
                end
            elseif (line(29) ~= ' ' || line(30)) && cat == 1
                option{k-1,2} = [option{k-1,2} ,' ', strtrim(line)];
            elseif (line(29) ~= ' ' || line(30)) && cat == 0
                option{k-1,4} = [option{k-1,4} ,' ', strtrim(line)];
            end
        end
        
        % Description: Get the usage from the file
        function usage = get_usage(u, line)
            global fields;
            global k;
            
            usage = u;
            if ~isempty(strfind(line, char(fields(6)))) && strncmpi(strtrim(line),fields(6),length(fields(6)))
            else
                usage{k,1}=strtrim(line);
                k = k + 1;
            end
        end
        
        % Description: Get the author from the file
        function author = get_author(au, line)
            global k;
            
            author = au;
            author{k,1}=strtrim(line);
            k = k + 1;
        end
        
        % Description: Get the references from the file
        function references = get_references(r, line)
            global fields;
            global k;
            
            references = r;
            if ~isempty(strfind(line, char(fields(8)))) && strncmpi(strtrim(line),fields(6),length(fields(6)))
            else
                references{k,1} = strtrim(line);
                k = k + 1;
            end
        end
        
        % Description: Get the header's first part from the file
        function head = get_head(he, line)
            global k;
            
            head = he;
            head{k,1} = strtrim(line);
            k = k + 1;
        end
    end
end

