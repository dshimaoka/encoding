function [S, timeVec] = preprocAll(S, paramIdx, frameRate, dsRate)
%[S, timeVec] = preprocAll(S, paramIdx, frameRate, dsRate)
%
%INPUT
%S: x-y-c-t
%frameRate: original sampling rage in Hz
%dsRate: desired downsampling rate in Hz (default:1)

%OUTPUT
%S_fin: (frame number) - (filter number)

if nargin < 4 || isempty(dsRate)
    dsRate = 1;
end
if nargin < 2 || isempty(paramIdx)
    paramIdx.cparamIdx = 1;
    paramIdx.gparamIdx = 2;
    paramIdx.nlparamIdx = 1;
    paramIdx.dsparamIdx = 1;
    paramIdx.nrmparamIdx = 1;
end


if ~isempty(paramIdx.cparamIdx)
    cparams = preprocColorSpace_GetMetaParams(paramIdx.cparamIdx);
    [S, cparams] = preprocColorSpace(S, cparams);
end

% Gabor wavelet processing
if ~isempty(paramIdx.gparamIdx)
    gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
    [S, gparams] = preprocWavelets_grid(S, gparams);%filter assumes no time delay
end

% Compute log of each channel to scale down very large values
if ~isempty(paramIdx.nlparamIdx)
    nlparams = preprocNonLinearOut_GetMetaParams(paramIdx.nlparamIdx);
    [S, nlparams] = preprocNonLinearOut(S, nlparams);
end

timeVec = 1/frameRate*(0: size(S,1)-1)';

% Downsample data to the sampling rate of your fMRI data (the TR)
if ~isempty(paramIdx.dsparamIdx)
    %resample so the framerate is integer
    times_rs = (timeVec(1):1/round(frameRate): timeVec(end))';
    S = interp1(timeVec, S, times_rs);
    
    dsparams = preprocDownsample_GetMetaParams(paramIdx.dsparamIdx); % for TR=1; use (2) for TR=2
    dsparams.imHz = round(frameRate);
    dsparams.sampleSec = 1/dsRate;
    [S, dsparams] = preprocDownsample(S, dsparams);
    timeVec = preprocDownsample(times_rs,dsparams);
end

% Z-score each channel
if ~isempty(paramIdx.nrmparamIdx)
    nrmparams = preprocNormalize_GetMetaParams(paramIdx.nrmparamIdx);
    [S, nrmparams] = preprocNormalize(S, nrmparams);
end

%% NG should not impose delay
%impose delay so the filter uses signal only from the past
% S = S';
% S = circshift(S, round(gparams.tsize/2), 2);
% S = S';

