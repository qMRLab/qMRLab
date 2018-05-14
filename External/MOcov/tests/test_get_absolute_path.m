function test_suite = test_get_absolute_path
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

