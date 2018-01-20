%Script pour tester la bonne écriture des headers des models

function b = checkHeader(file)
    b = true;
    cdmfile(file);
    h = header.header_parse(file);
    
    fprintf('Header verification of %s in progress... \nPlease wait until the process is finished...\n\n', file);
    % Check head
    if size(h.head) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate description of the model\n');
    end
    if size(h.assumption) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate assumptions format\n');
    end
    if size(h.input) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate input format\n');
    else
        d = true;
        for i = 1:size(h.input)
            if strcmp(h.input(i,2),'')
                b = false;
                d = false;
            end
        end
        if d == false
            fprintf('ERROR: Missing one or more input description or incorrect spacing\n');
        end      
    end
    
    if size(h.output) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate output format\n');
    else
        d = true;
        s = size(h.protocol);
        for i = 1:(1)
            if strcmp(h.output(i,2),'')
                b = false;
                d = false;
            end
        end
        if d == false
            fprintf('ERROR: Missing one or more output description or incorrect spacing\n');
        end
    end
    
    if size(h.protocol) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate protocol format\n');
    else
        d = true;
        s = size(h.protocol);
        for i = 1:s(1)
            if s(2) >= 3
                if ~strcmp(h.protocol(i,3),'') & strcmp(h.protocol(i,4),'')
                    b = false;
                    d = false;
                end
            else
                if ~strcmp(h.protocol(i,1),'') & strcmp(h.protocol(i,2),'')
                    b = false;
                    d = false;
                end  
            end
        end
        if d == false
            fprintf('ERROR: Missing one or more protocol description or incorrect spacing\n');
        end
    end
    if size(h.option) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate option format');
    else
        d = true;
        for i = 1:size(h.option)
            if ~strcmp(h.option(i,3),'') & strcmp(h.option(i,4),'')
                b = false;
                d = false;
            end
        end
        if d == false
            fprintf('ERROR: Missing one or more option description or incorrect spacing\n');
        end
    end
    if size(h.usage) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate usage format\n');
    end
    if size(h.author) == 0 | strcmp(h.author(1),'FILL')
        b = false;
        fprintf('ERROR: Missing or inadequate author format\n');
    end
    if size(h.references) == 0
        b = false;
        fprintf('ERROR: Missing or inadequate references format\n');
    end
    if b == true
        fprintf('CORRECT HEADER FORMAT \n\n');
    end