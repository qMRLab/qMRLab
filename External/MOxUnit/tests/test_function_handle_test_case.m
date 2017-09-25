function test_suite=test_function_handle_test_case
% tests for MOxUnitFunctionHandleTestCase
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_function_handle_test_case_basics
    rand_str=@()char(20*rand(1,10)+65);

    outcome_class2func=struct();
    outcome_class2func.MOxUnitPassedTestOutcome=@do_nothing;
    outcome_class2func.MOxUnitSkippedTestOutcome=@()...
                            moxunit_throw_test_skipped_exception('foo');
    outcome_class2func.MOxUnitFailedTestOutcome=@()error('here');

    keys=fieldnames(outcome_class2func);
    for k=1:numel(keys)
        outcome_class=keys{k};
        func=outcome_class2func.(outcome_class);

        name=rand_str();
        location=rand_str();

        f=MOxUnitFunctionHandleTestCase(name, location, func);
        assertEqual(getName(f),name);
        assertEqual(getLocation(f),location);
        assertEqual(str(f),sprintf('%s:  %s',name,location));

        rep=MOxUnitTestReport(0,1);
        rep=run(f,rep);

        assertEqual(countTestOutcomes(rep),1);
        outcome=getTestOutcome(rep,1);

        assertEqual(class(outcome),outcome_class);
    end





function do_nothing()
    % do nothing
