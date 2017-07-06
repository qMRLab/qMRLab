
load('testdata.mat')
method='Magnitude';
[T1,rb,ra,res]=fitT1_IR(data,TI,method);

% Check the fit
nbtp = 20;
timef = linspace(min(TI),max(TI),nbtp);

switch method
    case{'Complex'}
            datafit = ra + rb.*exp(-timef./T1);
    case{'Magnitude'}
            datafit= abs(ra + rb.*exp(-timef./T1));
end

figure
plot(TI, data,'.','MarkerSize',15)
hold on
plot(timef,datafit,'.r','MarkerSize',15)