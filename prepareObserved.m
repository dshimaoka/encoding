function observed = prepareObserved(imageProc, dsRate)
%observed = prepareObserved(imageProc, dsRate)
% returns observed signal (time x pixel) at dsRate [Hz]
% from result of saveImageProcess.m
%
% 2023 - 02 - 09 DS created from quickAnalysisCJ224_runPassiveMovies2.m
%
% TODO:
% compute dI/I just once across conditions?
% 

OETimes = imageProc.OETimes;
V = imageProc.V;
Fcam = 1/median(diff(OETimes.camOnTimes)); %camera effective sampling rate
stimInfo = imageProc.stimInfo;

%% resample (necessary for preprocDownsample)
camOnTimes_rs = OETimes.camOnTimes(1):1/round(Fcam): OETimes.camOnTimes(end);
V = interp1(OETimes.camOnTimes, V', camOnTimes_rs)';

%% align to visual stimulus onsets
%mISI = mean(diff(OETimes.stimOnTimes));
calcWin = [0 stimInfo.duration]; %chop off all trials at exact same time

[~, winSamps, singlePeriEventV, stimLabels_ok, uniqueLabels] ...
    = eventLockedAvg(V, camOnTimes_rs, OETimes.stimOnTimes, stimInfo.stimLabels, ...
    calcWin);

dsparams = preprocDownsample_GetMetaParams(1); % for TR=1; use (2) for TR=2　%SLOW
dsparams.imHz = round(Fcam);
dsparams.sampleSec = 1/dsRate;
nrmparams = preprocNormalize_GetMetaParams(1);%FAST
Snorm = [];TimeVec_ds_c=[];
for imov = 1:numel(stimLabels_ok)
    %% downsampling
    % dsparams.dsType
    % dsparams.imHz
    % dsparams.sampleSec
    % dsparams.frameshifts
    % dsparams.gaussParams
    
    [Sds] = preprocDownsample(squeeze(singlePeriEventV(imov,:,:))', dsparams);
    TimeVec = winSamps';%1/dsparams.sampleSec*(0:size(singlePeriEventV,1)-1)';
    TimeVec_ds = preprocDownsample(TimeVec,dsparams);
    if imov==1
        TimeVec_ds_c = TimeVec_ds;
    else
        TimeVec_ds_c = [TimeVec_ds_c; TimeVec_ds_c(end) + dsparams.sampleSec + TimeVec_ds];
    end
    %% compute dI/I
    % baseWin = ones(1,numel(winSamps));
    % dFFmethod = 2;
    % singlePeriEventStack = getdFFSingleEventStack(singlePeriEventStack, baseWin, dFFmethod, doMedian);
    % nrmparams.normalize
    % nrmparams.reduceChannels
    % nrmparams.crop
    Snorm(imov,:,:) = preprocNormalize(Sds,nrmparams);
end

observed = reshape(Snorm, size(Snorm,1)*size(Snorm,2),[]);

