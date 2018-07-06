function [paddedVolume] = pad_volume_for_sharp(inputVolume, pad_size)
%PAD_VOLUME_FOR_SHARP Pads mask and wrapped phase volumes with zeros for Sharp kernel
%convolutions.

    paddedVolume = padarray(inputVolume, pad_size);

end
