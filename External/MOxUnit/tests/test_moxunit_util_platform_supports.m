function test_suite=test_moxunit_util_platform_supports
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_moxunit_util_platform_supports_localfunctions_in_script
    flag=moxunit_util_platform_supports('localfunctions_in_script');

    if moxunit_util_platform_is_octave()
        expected_flag=true;
    else
        v=moxunit_util_platform_version();
        expected_flag=version_less_than(v,[9,0]);
    end

    assertEqual(flag,expected_flag);


function test_moxunit_util_platform_supports_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        moxunit_util_platform_supports(varargin{:}),'');
    aet('unknown');
    aet(2);

function tf=version_less_than(x,y)
    tf=false;
    for k=1:numel(y)
        if x(k)<y(k)
            tf=true;
            return;
        end
    end
