function test_suite=pad_volume_for_sharp_Test
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
end

function test_that_function_returns_volume_with_expected_padded_size(testCase)
    tmpVolume = ones(10,10,10);

    paddedVolume = pad_volume_for_sharp(tmpVolume);
    
    expectedOutputSize = [28 28 28]; % Padded by 9 rows on each side.
    
    assertEqual(size(paddedVolume), expectedOutputSize);
end

function test_that_padding_are_zeros(testCase)
    tmpVolume = ones(10,10,10);

    paddedVolume = pad_volume_for_sharp(tmpVolume);
    
    xLeft = paddedVolume(1:9,:,:);
    assertTrue(~any(xLeft(:)));

    xRight = paddedVolume(20:end,:,:);
    assertTrue(~any(xRight(:)));
    
    yLeft = paddedVolume(:,1:9,:);
    assertTrue(~any(yLeft(:)));

    yRight = paddedVolume(:,20:end,:);
    assertTrue(~any(yRight(:)));
    
    zLeft = paddedVolume(:,:,1:9);
    assertTrue(~any(zLeft(:)));

    zRight = paddedVolume(:,:,20:end);
    assertTrue(~any(zRight(:)));
    
end