function test_suite = test_mocov_is_absolute_path()
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
            test_functions=localfunctions();
        catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_mocov_is_absolute_path_basics()
    if ispc()
        assertTrue(mocov_is_absolute_path('C:\\'));
        assertTrue(mocov_is_absolute_path('C:'));
        assertTrue(mocov_is_absolute_path('C:\\aa\\bb'));
        assertTrue(mocov_is_absolute_path('D:/bb/cc'));
        assertFalse(mocov_is_absolute_path('C\\'));
        assertFalse(mocov_is_absolute_path('/bb/cc'));
        assertFalse(mocov_is_absolute_path('./bb/cc'));
        assertFalse(mocov_is_absolute_path('../bb/cc'));
    else
        assertFalse(mocov_is_absolute_path('C:\\'));
        assertFalse(mocov_is_absolute_path('C:'));
        assertTrue(mocov_is_absolute_path('/bb/cc'));
        assertTrue(mocov_is_absolute_path('/'));
        assertFalse(mocov_is_absolute_path('./bb/cc'));
        assertFalse(mocov_is_absolute_path('../bb/cc'));
    end