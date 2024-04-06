function [observed, TimeVec_ds_c] = prepareObserved(imageProc, dsRate)
%observed = prepareObserved(imageProc, dsRate)
% returns observed signal (time x pixel) at dsRate [Hz] after
% preprocDownSample and preprocNormalize
% from result of saveImageProcess.m
%
% 2023 - 02 - 09 DS created from quickAnalysisCJ224_runPassiveMovies2.m
%
% 

OETimes = imageProc.OETimes;
V = imageProc.V;
Fcam = 1/median(diff(OETimes.camOnTimes)); %camera effective sampling rate
stimInfo = imageProc.stimInfo;

%% resample (necessary for preprocDownsample)
camOnTimes_rs = OETimes.camOnTimes(1):1/round(Fcam): OETimes.camOnTimes(end);
V = interp1(OETimes.camOnTimes, V', camOnTimes_rs)';
if size(V,2) == 1
    V = V';
end
    
%% align to visual stimulus onsets
%mISI = mean(diff(OETimes.stimOnTimes));
calcWin = [0 stimInfo.duration]; %chop off all trials at exact same time

[~, winSamps, singlePeriEventV, stimLabels_ok, uniqueLabels] ...
    = eventLockedAvg(V, camOnTimes_rs, OETimes.stimOnTimes, stimInfo.stimLabels, ...
    calcWin);

dsparams = preprocDownsample_GetMetaParams(1); %SLOW
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
    data = squeeze(singlePeriEventV(imov,:,:))';
    if size(data,1)==1
        data = data';
    end
    
    [Sds] = preprocDownsample(data, dsparams);
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
    Snorm(:,imov,:) = preprocNormalize(Sds,nrmparams); %[time x imovie x pixel]
    
    %sanity check
    %yyaxis left; plot(winSamps,squeeze(singlePeriEventV(1,7618,:)),TimeVec_ds, Sds(:,7618));
    %yyaxis right; plot(TimeVec_ds, Snorm(1,:,7618))
end

observed = reshape(Snorm, size(Snorm,1)*size(Snorm,2),[]); %(movie1 time 0-end, movie2 time 0-end ) x pixels

