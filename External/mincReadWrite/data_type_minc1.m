function netCDF_datatype = data_type_minc1(dataset_datatype)

    switch dataset_datatype 
        case 1
            netCDF_datatype = 'int8'; % or uint8 if netcdf4
        case 2
            netCDF_datatype = 'int8';
        case 3 
            netCDF_datatype = 'int16';
        case 4 
            netCDF_datatype = 'int32'; 
        case 5 
            netCDF_datatype = 'single'; % or float
        case 6 
            netCDF_datatype = 'double'; 
        case 7 
            netCDF_datatype = 'uint8'; 
        case 8 
            netCDF_datatype = 'uint16'; 
        case 9 
            netCDF_datatype = 'uint32'; 
        case 10 
            netCDF_datatype = 'int64';
        case 11 
            netCDF_datatype = 'uint64'; 
    end 
end 