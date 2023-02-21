T = 7200; %original movie duration [s]
R = 2; %down sampling rate [Hz]
P = 3014; %number of parameters of the gabor wavlet filter bank
W = 2:4; %temporal kernel window size [s]

predX_numel = (T*R + P*W*R) .* (P*W*R); %array size

singleByte = 4;
predX_GB = predX_numel * singleByte * 1e-9; %array size in GB