function RF_insilico = getInSilicoRF(paramIdx, r0, rr, lagFrames, ...
    tavg, Fs, RF_insilico, oriStimSize)
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
%oriStimSize: original stimulus window [height] in degree
%
%OUTPUT
%append the following fields to RF_insilico:
%   .RF: stim-trig avg [screenY x screenX x nDelays x nNeurons ]
%   .RF_delay: axis of time delay after vis stim onset, corresponding to 3rd dim of RF_is in [s] 

polarity = 'white';

screenPix = RF_insilico.screenPix;
nRepeats = RF_insilico.nRepeats;

%nDelays = size(rr,1);
nNeurons = size(rr,3);

if isempty(RF_insilico.Fs_visStim)
    RF_insilico.Fs_visStim = paramIdx.predsRate;
end

%%1 make sparse white noise

dotStream = repmat(1:screenPix(1)*screenPix(2), 1, nRepeats);
dotStream = dotStream(randperm(screenPix(1)*screenPix(2)*nRepeats));
dotStream = repmat(dotStream,RF_insilico.dwell,1);
dotStream = dotStream(:)';

nFrames = numel(dotStream);
timeVec_stim = 1/RF_insilico.Fs_visStim*(1:nFrames);%0:1/Fs:maxT;%[s]

%[dotYidxStream, dotXidxStream] = ind2sub([screenPix screenPix], dotStream);
stim_is_flat = single(zeros(screenPix(1)*screenPix(2), nFrames));
for tt = 1:nFrames
    stim_is_flat(dotStream(tt),tt)=1;
end
%stim_is_flat(dotStreamIdx) = 1; %<this is what I want to do wo for loop
stim_is = reshape(stim_is_flat, screenPix(1), screenPix(2), nFrames);


%% 2 compute response of the filter bank, at Fs Hz
paramIdx.cparamIdx = [];
paramIdx.predsRate = [];
[S_nm, timeVec_mdlResp] = preprocAll(stim_is, paramIdx, RF_insilico.Fs_visStim, Fs);
S_nm = S_nm'; %predictXs accepts [nVar x nFrames]


%% 3 compute responese of the wavelet filter
% lagRange = [min(lagFrames) max(lagFrames)];%/Fs? %lag range provided as rr
gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
filterWidth = gparams.tsize; %#frames
lagRangeS_mdl = [mean(lagFrames)-0.5*filterWidth mean(lagFrames)+0.5*filterWidth]/Fs; %expected frame window of gabor wavelet bank

RF_delay = linspace(lagRangeS_mdl(1),lagRangeS_mdl(2),round(diff(lagRangeS_mdl)*Fs+1)); %"surround time" from getSparseResponse ;
RF_is = zeros(screenPix(1), screenPix(2), length(RF_delay), nNeurons);
for iNeuron = 1:nNeurons
    [observed] = predictXs(timeVec_mdlResp, S_nm, ...
        squeeze(r0(iNeuron)), squeeze(rr(:,:,iNeuron)), [lagFrames(1) lagFrames(end)], tavg);
    
    %% 4 estimate RF
    % stimulus-triggered avg (by AP)...fast
    [response_t] = getSparseResponse(observed, timeVec_mdlResp, stim_is, ...
        timeVec_stim, lagRangeS_mdl, polarity);% [delay x 1 x ]
    % < getSparseResponse can deal with multiple variables but not scalable
    response_t = (squeeze(response_t))';
    RF_is(:,:,:,iNeuron) = reshape(response_t,screenPix(1),screenPix(2),[]);
end
RF_insilico.RF = RF_is;
RF_insilico.RFdelay = RF_delay;

xpix = 1:screenPix(2);
RF_insilico.xaxis = oriStimSize(2)*(xpix - mean(xpix))./numel(xpix);
ypix = 1:screenPix(1);
RF_insilico.yaxis = oriStimSize(1)*(ypix - mean(ypix))./numel(ypix);

