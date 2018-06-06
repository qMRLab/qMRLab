function [paddedVolume] = pad_volume_for_sharp(inputVolume)
%PAD_VOLUME_FOR_SHARP Pads mask and wrapped phase volumes with zeros for Sharp kernel
%convolutions.

    pad_size = [9,9,9];     % pad for Sharp recon
                            % MB: Investigate why 9 zeros for each dimension?

    paddedVolume = padarray(inputVolume, pad_size);

end
