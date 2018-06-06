function [phase_wrap_pad, mask_pad] = pad_volume_for_sharp(phase_wrap, mask)
%PAD_VOLUME_FOR_SHARP Pads mask and wrapped phase volumes with zeros for Sharp kernel
%convolutions.

    pad_size = [9,9,9];     % pad for Sharp recon
                            % MB: Investigate why 9 zeros for each dimension?

    mask_pad = padarray(mask, pad_size);
    phase_wrap_pad = padarray(phase_wrap, pad_size);

end
