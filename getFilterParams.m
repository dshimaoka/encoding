function [gaborparams_real, gaborparams, S] = getFilterParams(gparamIdx, screenPix, screenDeg)
% [gaborparams_real, gaborparams] = getFilterParams(gparamIdx, screenPix, screenDeg)

%gparamIdx = 2;
%screenPix = [144 256];%/4; %Y-X %gaborparams is identical irrespective of the denominator
%screenDeg = [15 27]; %[deg]

gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
gparams.show_or_preprocess = 0; %necessary to obtain gaborparams
S = zeros(screenPix(1), screenPix(2), 20); %X-Y-T

[S, gparams] = preprocWavelets_grid(S, gparams, 0);%filter assumes no time delay
gaborparams = gparams.gaborparams;
%     .gaborparams = A set of parameters for each Gabor wavelet.
%                       This is a p-by-D matrix where p is number of parameters (8)
%                       and D is the number of wavelet channels
%                       Each field in gaborparams represents:
%                       [pos_x pos_y direction s_freq t_freq s_size t_size phasevalue]
%                       s_size: Spatial envelope size in standard deviation 1=entire screen
%                         
%                       t_size: Number of frames to calculate wavelets
%                       phasevalue can be 0 to 6, where
%                         0: spectra
%                         1: linear sin transform
%                         2: linear cos transform
%                         3: half-rectified sin transform (positive values)
%                         4: half-rectified sin transform (negative values)
%                         5: half-rectified cos transform (positive values)
%                         6: half-rectified cos transform (negative values)
%                         7: dPhase/dt
%                         8: dPhase/dt (positive values)
%                         9: dPhase/dt (negative values)
%
% see also: make3dgabor_frames.m


%% convert to real space
% pix2deg = mean(screenDeg./screenPix); %[deg/pix]
gaborparams_real = gaborparams;
gaborparams_real(1,:) = screenDeg(2) * gaborparams(1,:) - screenDeg(2)/2; %pos_x [deg]
gaborparams_real(2,:) = screenDeg(1) * gaborparams(2,:) - screenDeg(1)/2; %pos_y [deg]
% gaborparams_real(3,:) 
gaborparams_real(4,:) = 1/max(screenDeg)* gaborparams(4,:);%s_freq [cpd]
% gaborparams_real(5,:) 
gaborparams_real(6,:) = 1/max(screenDeg) * gaborparams(6,:); %s_size [deg]
% gaborparams_real(7,:) 
% gaborparams_real(8,:) 
