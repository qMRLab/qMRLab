function Data = ApplyView(Data, View)
if isstruct(Data)
    for ff = 1:length(Data.fields)
        data = Data.(Data.fields{ff});
        data = setView(data,View);
        Data.(Data.fields{ff}) = data;
    end
else
    Data = setView(Data,View);
end

function data = setView(data,View)
switch View
    case 'Axial';  data = permute(data,[1 2 3 4 5]);
    case 'Coronal';  data = permute(data,[1 3 2 4 5]);
    case 'Sagittal';  data = permute(data,[2 3 1 4 5]);
end
