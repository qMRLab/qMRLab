function HDF5_datatype = data_type_minc2(dataset_datatype)
    dataset_datatype = char(dataset_datatype);
    switch dataset_datatype
        case 'H5T_IEEE_F64LE'
            HDF5_datatype = 'double';
        case 'H5T_IEEE_F32LE'
            HDF5_datatype = 'single';
        case 'H5T_STD_U64LE'
            HDF5_datatype = 'uint64';
        case 'H5T_STD_I64LE'
            HDF5_datatype = 'int64';
        case 'H5T_STD_U32LE'
            HDF5_datatype = 'uint32';
        case 'H5T_STD_I32LE'
            HDF5_datatype = 'int32';
        case 'H5T_STD_U16LE'
            HDF5_datatype = 'uint16';
        case 'H5T_STD_I16LE'
            HDF5_datatype = 'int16';
        case 'H5T_STD_U8LE'
            HDF5_datatype = 'uint8';
        case 'H5T_STD_I8LE'
            HDF5_datatype = 'int8';
        otherwise 
            error('Unsupported HDF5 datatype identified: %s', dataset_datatype);
    end 
end 