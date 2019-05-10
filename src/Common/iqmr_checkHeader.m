%Script pour tester la bonne ?criture des headers des models

function b = iqmr_checkHeader(file)
    b = true;
    cdmfile(file);
    h = iqmr_header.header_parse(file);
    
    fprintf('Header verification of %s in progress... \nPlease wait until the process is finished...\n\n', file);
    % Check head
    if size(h.head) == 0
        b = false;
        fprintf(2,'ERROR: Missing description of the model\n\n');
    end
    if size(h.assumption) == 0
        b = false;
        fprintf(2,'ERROR: Missing assumptions\n\n');
    end
    if size(h.input) == 0
        b = false;
        fprintf(2,'ERROR: Missing or inadequate input format\n');
        informSyntaxInputOrOutput();
    else
        d = true;
        for i = 1:size(h.input)
            if strcmp(h.input(i,2),'')
                b = false;
                d = false;
            end
        end
        if d == false
            fprintf(2,'ERROR: Missing one or more input description or incorrect spacing\n');
            informSyntaxInputOrOutput();
        end      
    end
    
    if size(h.output) == 0
        b = false;
        fprintf(2,'ERROR: Missing or inadequate output format\n');
        informSyntaxInputOrOutput();
    else
        d = true;
        for i = 1:(1)
            if strcmp(h.output(i,2),'')
                b = false;
                d = false;
            end
        end
        if d == false
            fprintf(2,'ERROR: Missing one or more output description or incorrect spacing\n');
            informSyntaxInputOrOutput();
        end
    end
    
    if size(h.protocol) == 0
        b = false;
        fprintf(2,'ERROR: Missing or inadequate protocol format\n');
        informSyntaxProtocolOrOption();
    else
        d = true;
        s = size(h.protocol);
        for i = 1:s(1)
            if s(2) >= 3
                if ~strcmp(h.protocol(i,3),'') && strcmp(h.protocol(i,4),'')
                    b = false;
                    d = false;
                end
            else
                if ~strcmp(h.protocol(i,1),'') && strcmp(h.protocol(i,2),'')
                    b = false;
                    d = false;
                end  
            end
        end
        if d == false
            fprintf(2,'ERROR: Missing one or more protocol description or incorrect spacing\n');
            informSyntaxProtocolOrOption();
        end
    end
    if size(h.option) == 0
        b = false;
        fprintf(2,'ERROR: Missing or inadequate option format\n');
        informSyntaxProtocolOrOption();
    else
        d = true;
        for i = 1:size(h.option)
            if ~strcmp(h.option(i,3),'') && strcmp(h.option(i,4),'')
                b = false;
                d = false;
            end
        end
        if d == false
            fprintf(2,'ERROR: Missing one or more option description or incorrect spacing\n');
            informSyntaxProtocolOrOption();
        end
    end
    if size(h.usage) == 0
        b = false;
        fprintf(2,'ERROR: Missing or inadequate usage format\n\n');
    end
    if max(size(h.author)) == 0 || strcmp(h.author(1),'FILL')
        b = false;
        fprintf(2,'ERROR: Missing or inadequate author format\n\n');
    end
    if size(h.references) == 0
        b = false;
        fprintf(2,'ERROR: Missing or inadequate references format\n\n');
    end
    if b == true
        fprintf('CORRECT HEADER FORMAT \n\n');
    else
        fprintf(2, '*Please respect the spacing number in between names and descriptions.\n\n');
        fprintf(2, 'For more information on the correct header format, please see other models .m files.\n');
    end
    
end

function informSyntaxInputOrOutput()
     fprintf('Please use the following syntax:\n');
     fprintf('   Name               Description (if needed)\n');
     fprintf('*If a description is to long, you can continue on the next line with the same indent and two more spaces.*\n\n');
end

function informSyntaxProtocolOrOption()
    fprintf('Please use the following syntax:\n');
    fprintf('   Name               Description (if needed)\n');
    fprintf('     Name             Description\n');
    fprintf('*If a description is to long, you can continue on the next line with the same indent and two more spaces.*\n\n');  
end
        