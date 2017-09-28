function report=run(obj,report)
% Run test associated with MOxUnitMatlabUnitWrapperTestCase
%
% report=run(obj,report)
%
% Inputs:
%   obj             MOxUnitMatlabUnitWrapperTestCase object
%   report          MoxUnitTestReport instance to which test results are to
%                   be reported.
%
% Output:
%   report          MoxUnitTestReport containing tests results
%                   after running the test associated with obj.
%
% See also: MoxUnitTestReport
%

    start_tic = tic;

    try
        runner=matlab.unittest.TestRunner.withNoPlugins();
        result=runner.run(obj.matlab_unittest_test_obj);

        if isequal(result.Passed,1)
            test_outcome_constructor=@MOxUnitPassedTestOutcome;
            test_outcome_args={};
        else
            % everything else fails
            test_outcome_constructor=@MOxUnitFailedTestOutcome;
            test_outcome_args={make_failed_error(obj)};
        end
    catch
        e=lasterror();
        test_outcome_constructor=@MOxUnitErroredTestOutcome;
        test_outcome_args={e};
    end

    test_outcome = test_outcome_constructor(obj, toc(start_tic), ...
                            test_outcome_args{:});

    report = reportTestOutcome(report, test_outcome);


function make_failed_error(obj)
    e=struct();
    e.message=sprintf('Test failed: %s', str(obj));
    e.identifier='';
    e.stack=struct(zeros(0,1));