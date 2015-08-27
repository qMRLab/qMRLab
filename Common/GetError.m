function Error = GetError(SimRndResults)

RndParam  =  getappdata(0,'RndParam');
Error.F   = (SimRndResults.F   - RndParam.F);
Error.kr  = (SimRndResults.kr  - RndParam.kr);
Error.R1f = (SimRndResults.R1f - RndParam.R1f);
Error.R1r = (SimRndResults.R1r - RndParam.R1r);
Error.M0f = (SimRndResults.M0f - RndParam.M0f);