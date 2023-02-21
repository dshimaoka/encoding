function [RF_is, lagTimes_mdl] = getInSilicoRF(paramIdx, r0, rr, lagFrames, ...
    tavg, screenPix, Fs, nRepeats)
%[RF_is, lagRange] = getInSilicoRF(gparamIdx, r0, rr, screenPix, Fs, nRepeats)
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
%screenPix: screen # pixels [y - x] for in silico simulation (no need to match that for in vivo exp)
%Fs: sampling rate of in-silico model AND visual stim (theres no point of having different Fs between them)
%maxT: maximam time of in-silico visual stim
%nRepeats: #presentation per screen pixel(default:20)
%
%OUTPUT
%RF_is: stim-trig avg [screenY x screenX x nDelays x nNeurons ]
%lagTimes_model: axis of time delay corresponding to 3rd dim of RF_is in [s] (vector length = gparams.tsize)

polarity = 'white';

if nargin < 8
    nRepeats = 20;
end

if length(screenPix)==1
    screenPix(2) = screenPix(1);
end

nDelays = size(rr,1);
nNeurons = size(rr,3);

if isempty(lagFrames)
    lagFrames = 0:(nDelays-1);
end

%%1 make sparse white noise
nFrames = screenPix(1)*screenPix(2)*nRepeats;
timeVec = 1/Fs*(1:nFrames);%0:1/Fs:maxT;%[s]

dotStream = repmat(1:screenPix(1)*screenPix(2), 1, nRepeats);
dotStream = dotStream(randperm(screenPix(1)*screenPix(2)*nRepeats));
%[dotYidxStream, dotXidxStream] = ind2sub([screenPix screenPix], dotStream);
stim_is_flat = single(zeros(screenPix(1)*screenPix(2), nFrames));
for tt = 1:nFrames
    stim_is_flat(dotStream(tt),tt)=1;
end
%stim_is_flat(dotStreamIdx) = 1; %<this is what I want to do wo for loop
stim_is = reshape(stim_is_flat, screenPix(1), screenPix(2), nFrames);


%% 2 compute response of the filter bank
paramIdx.cparamIdx = [];
paramIdx.dsparamIdx = [];
S_nm = preprocAll(stim_is, paramIdx, Fs);
S_nm = S_nm'; %predictXs accepts [nVar x nFrames]


%% 3 compute responese of the wavelet filter
lagRange = [min(lagFrames) max(lagFrames)];%/Fs? %lag range provided as rr
%gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
%lagRange_model = [0 (gparams.tsize-1)/Fs];%motion energy model
%lagTimes_model = round(lagRange_model(1)*Fs):round(lagRange_model(2)*Fs);
%lagTimes_model = round(lagRange(1)/Fs):round(lagRange(2)/Fs); %response time window in seconds not frames
lagRange_mdl = [lagRange(1) 3*lagRange(2)]; %response latency of model in Frames
lagTimes_mdl = linspace(lagRange_mdl(1)/Fs,lagRange_mdl(2)/Fs,round(diff(lagRange_mdl/Fs)*Fs+1)); %"surround time" from getSparseResponse 
RF_is = zeros(screenPix(1), screenPix(2), length(lagTimes_mdl), nNeurons);
for iNeuron = 1:nNeurons
    [observed] = predictXs(timeVec, S_nm, ...
        squeeze(r0(iNeuron)), squeeze(rr(:,:,iNeuron)), lagRange, tavg);
    
    %% 4 estimate RF
    % stimulus-triggered avg (by AP)...fast
    [response_t] = getSparseResponse(observed, timeVec, stim_is, ...
        timeVec, lagRange_mdl/Fs, polarity);% [delay x 1 x ]
    % < getSparseResponse can deal with multiple variables but not scalable
    response_t = (squeeze(response_t))';
    RF_is(:,:,:,iNeuron) = reshape(response_t,screenPix(1),screenPix(2),[]);
end
