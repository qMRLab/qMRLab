clear; clc;

Protocol = load('Protocol.mat');
FitOpt = load('FitOpt.mat');
load('MTdata.mat');
load('Mask.mat');
load('B0map.mat');
load('B1map.mat');
load('R1map.mat');

data.MTdata = double(MTdata);
data.Mask = double(Mask);
data.B0map = double(B0map);
data.B1map = double(B1map);
data.R1map = double(R1map);

FitResults = FitData( data, Protocol, FitOpt, 'SPGR', 0);