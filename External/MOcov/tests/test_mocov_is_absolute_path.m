function test_suite = test_mocov_is_absolute_path()
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