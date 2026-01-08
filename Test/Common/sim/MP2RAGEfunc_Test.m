classdef MP2RAGEfunc_Test < matlab.unittest.TestCase
% Provisional comparison between MPRAGEfunc and the modified MP2RAGEfunc
% Once the second replaces the first, reference results can be cached
% and loaded from a MAT file.

    properties (TestParameter)
        T1 = {1.2, rand(100,1) + 0.5}
        prot = struct(...
            'default', struct('TRs', 6, 'TRf', 0.0067, 'n', [35 72], 'TI', [0.8 2.7], 'FA', [4 5]), ...
            'madeup', struct('TRs', 5, 'TRf', 0.005, 'n', 20, 'TI', [0.7 1.5 2.4], 'FA', [3 4 7]));
        invEff = {0.96, 0.92};
        seq = {'normal', 'waterexcitation'};
    end

    methods (Test, ParameterCombination = 'pairwise')
        function testProperty(testCase, T1, prot, invEff, seq)

            Ni = numel(prot.TI);
            fref = @(T1) MPRAGEfunc(Ni, prot.TRs, prot.TI, prot.n, prot.TRf, prot.FA, seq, T1, invEff);
            Sref = arrayfun(fref, T1, 'UniformOutput', 0);
            Sref = cat(1,Sref{:});

            S = MP2RAGEfunc(prot.TRs, prot.TI, prot.n, prot.TRf, prot.FA, T1, invEff, seq);

            testCase.verifyEqual(Sref, S, 'AbsTol', eps(1), 'RelTol', 1e-12)
        end
    end
end