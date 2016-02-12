clc; clear;
MTdata = getappdata(0,'MTdata');
 Prot = getappdata(0,'Prot');
 FitOpt = getappdata(0,'FitOpt');
 Sim = getappdata(0,'Sim');
 
 %%
 Fit = SPGR_fit(MTdata, Prot, FitOpt );