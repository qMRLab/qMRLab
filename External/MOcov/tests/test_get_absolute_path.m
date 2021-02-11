function test_suite = test_get_absolute_path
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
            test_functions=localfunctions();
        catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_get_absolute_path_basics()
    aeq=@(a,b)assertEqual(mocov_get_absolute_path(a),b);

    aeq('/','/');
    aeq('/foo/../','/');
    aeq('/foo/..//','/');
    aeq('/foo/..','/');
    aeq('/foo/../.','/');
    aeq('/foo/.././','/');


    orig_pwd=pwd();
    cleaner=onCleanup(@()cd(orig_pwd));
    p=fileparts(mfilename('fullpath'));
    cd(p);
    aeq('',p);

