function RF_insilico = getInSilicoRF(paramIdx, trained, trainParam, ...
    RF_insilico, stimXdeg, stimYdeg, insilicoRFStim)
%RF_insilico = getInSilicoRF(gparamIdx, r0, rr, screenPix, Fs, nRepeats)
% estimate RF contour of the motion-energy model through in-silico noise
% stimulation
%
%INPUT
%paramIdx: parameter Idx for the in-silico model
%MUST BE IDENTICAL TO ONE USED FOR TRAINANEURON?
%r0: [nNeurons]
%rr: [nDelays of hemodynamic coupling x nFilters x nNeurons]
%lagFrames: response latency of the model output = lag range provided as rr (in frames not seconds)
%tavg: whether r0/rr was obtained by time averaging. If yes, the model can still have temporal delays (specified in gparam Idx), but its output should be temporally monotonic
%Fs: sampling rate of hemodynamic coupling function
% (sampling rate of gabor-wavlet filter is given by paramIdx.predsRate = downsampling freq of vis stim)
%RF_insilico
%   .screenPix: screen # pixels [y - x] for in silico simulation (no need to match that for in vivo exp)
%   .nRepeats: #presentation per screen pixel(default:20)
%stimX(Y)deg: list of stimulus positions used for computing motion-energy model
%
%OUTPUT
%append the following fields to RF_insilico:
%   .RF: stim-trig avg [screenY x screenX x nDelays x nNeurons ]
%   .RF_delay: axis of time delay after vis stim onset, corresponding to 3rd dim of RF_is in [s] 

% if nargin < 6 || isempty(stimXdeg)
%     stimXdeg = oristimSize(2)*(1:RF_insilico.noiseRF.screenPix(2) - 0.5*RF_insilico.noiseRF.screenPix(2))/RF_insilico.noiseRF.screenPix(2);
% end
% if nargin < 7 || isempty(stimYdeg)
%     stimYdeg = oristimSize(1)*(1:RF_insilico.noiseRF.screenPix(1) - 0.5*RF_insilico.noiseRF.screenPix(1))/RF_insilico.noiseRF.screenPix(1);
% end

polarity = 'white';

r0 = trained.r0e;
rr = trained.rre;
lagFrames = trainParam.lagFrames;
tavg = trainParam.tavg;
Fs = trainParam.Fs;
screenPix = RF_insilico.noiseRF.screenPix;

%nDelays = size(rr,1);
nNeurons = size(rr,3);

%% compute response of the filter bank
if nargin<7 || isempty(insilicoRFStim)
    insilicoRFStim= getInSilicoRFstim(paramIdx, RF_insilico, trainParam.Fs);
end
S_nm = insilicoRFStim.S_nm;
timeVec_mdlResp = insilicoRFStim.timeVec_mdlResp;
stim_is = insilicoRFStim.stim_is;
timeVec_stim = insilicoRFStim.timeVec_stim;

%% compute responese of the wavelet filter
% lagRange = [min(lagFrames) max(lagFrames)];%/Fs? %lag range provided as rr
gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
filterWidth = gparams.tsize; %#frames
lagRangeS_mdl = [mean(lagFrames)-0.5*filterWidth mean(lagFrames)+0.5*filterWidth]/Fs; %expected frame window of gabor wavelet bank

RF_delay = linspace(lagRangeS_mdl(1),lagRangeS_mdl(2),round(diff(lagRangeS_mdl)*Fs+1)); %"surround time" from getSparseResponse ;
RF_is = zeros(screenPix(1), screenPix(2), length(RF_delay), nNeurons);
for iNeuron = 1:nNeurons
    [observed] = predictXs(timeVec_mdlResp, S_nm, ...
        squeeze(r0(iNeuron)), squeeze(rr(:,:,iNeuron)), [lagFrames(1) lagFrames(end)], tavg);
    
    %% estimate RF
    % stimulus-triggered avg (by AP)...fast
    [response_t] = getSparseResponse(observed, timeVec_mdlResp, stim_is, ...
        timeVec_stim, lagRangeS_mdl, polarity);% [delay x 1 x ]
    % < getSparseResponse can deal with multiple variables but not scalable
    response_t = (squeeze(response_t))';
    RF_is(:,:,:,iNeuron) = reshape(response_t,screenPix(1),screenPix(2),[]);
end
RF_insilico.noiseRF.RF = RF_is;
RF_insilico.noiseRF.RFdelay = RF_delay;

xpix = 1:screenPix(2);
% RF_insilico.noiseRF.xaxis = oriStimSize(2)*(xpix - mean(xpix))./numel(xpix);
ypix = fliplr(1:screenPix(1));
% RF_insilico.noiseRF.yaxis = oriStimSize(1)*(ypix - mean(ypix))./numel(ypix);

% RF_insilico.noiseRF.xaxis = stimXdeg;
% RF_insilico.noiseRF.yaxis = stimYdeg;

RF_insilico.noiseRF.xaxis = (max(stimXdeg)-min(stimXdeg))/(max(xpix)-min(xpix))*(xpix-1)+min(stimXdeg);
RF_insilico.noiseRF.yaxis = (max(stimYdeg)-min(stimYdeg))/(max(ypix)-min(ypix))*(ypix-1)+min(stimYdeg);

% xpos = (1:screenPix(2))/screenPix(2);
% ypos = (1:screenPix(1))/screenPix(1);
% xrelpos = stimXrange/max(stimXrange);
% yrelpos = stimYrange/max(stimYrange);
% [RF_insilico.noiseRF.xaxis,RF_insilico.noiseRF.yaxis] = ...
%     relpos2deg(xrelpos,yrelpos,oriStimSize(2),oriStimSize(1));

