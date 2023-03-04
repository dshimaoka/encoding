function RF_insilico = getInSilicoORSF(paramIdx, trained, trainParam, RF_insilico, oriStimSize)
%INPUT:
%gparamIdx: parameter Idx supplied to preprocWavelets_grid_GetMetaParams
%r0: scalar
%rr: [nDelays of hemodynamic coupling x nFilters]
%screenPix: screen pixel size (assume same size of x & y )
%Fs: sampling rate of in-silico visual stim
%nRepeats: number of stimulus presentation per OR and SF
%nOR: number of ORs (equally spaced between 0-pi
%sfList: list of SFs (cycles per deg)
%oriStimSize: [height x width] [deg]
%
%OUTPUT:
%mresp: resp across repeats and delays [nORs x nSFs x nNeurons]
%oriList: list of ORs (1st dim of mresp) (rad)
%sfList: list of SFs (2nd dim of mresp) (cycles per pixel)

r0 = trained.r0e;
rr = trained.rre;
lagFrames = trainParam.lagFrames;
tavg = trainParam.tavg;
Fs = trainParam.Fs;

screenPix = RF_insilico.ORSF.screenPix;

if ~isfield(RF_insilico.ORSF,'oriList') || isempty(RF_insilico.ORSF.oriList)
    nORs = 10;
    oriList = pi/180*linspace(0,180,nORs+1)';
    oriList = oriList(1:end-1);
    RF_insilico.ORSF.oriList = oriList;
end

if  ~isfield(RF_insilico.ORSF,'sfList') || isempty(RF_insilico.ORSF.sfList)
    sfList = linspace(1/screenPix(1), 1/2, 5); %cycles per pixel
    %sfList = [0.05 0.1 0.15 0.2]';
    RF_insilico.ORSF.sfList = sfList;
end

if ~isfield(RF_insilico.ORSF,'Fs_visStim') || isempty(RF_insilico.ORSF.Fs_visStim)
    RF_insilico.ORSF.Fs_visStim = paramIdx.predsRate;
end


oriList = RF_insilico.ORSF.oriList;
sfList = RF_insilico.ORSF.sfList;
Fs_visStim = RF_insilico.ORSF.Fs_visStim;
dwell = RF_insilico.ORSF.dwell;

nORs = numel(oriList);
nNeurons = size(rr,3);
nSF = length(sfList);

nRepeats = RF_insilico.ORSF.nRepeats;

if size(sfList,1) < size(sfList,2)
    sfList = sfList';
end


A = 0.5*(screenPix(2)/oriStimSize(2) + screenPix(1)/oriStimSize(1)); %[pix/deg]

%maxSF =  %[cpd] %FIXME
%minSF = %[cpd]  %FIXME

%random varibles: spatial phase and OR and SF
oriSfStream = repmat(1:nORs*nSF, 1, nRepeats);
oriSfStream = oriSfStream(randperm(nORs*nSF*nRepeats));
[sfIdxStream, oriIdxStream] = ind2sub([nSF nORs], oriSfStream);
oriStream = oriList(oriIdxStream);
sfStream = 1/A * sfList(sfIdxStream); %convert cycles/deg to cycles/pix

nOns = length(oriStream);

gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
%checkGparam(gparams, screenPix, rr);

filterWidth = gparams.tsize; %#frames of visual stimulus
onFrames = dwell*(1:nOns);%filterWidth*(1:nOns);
timeVec_stim = 1/Fs_visStim*(0:(onFrames(end) + dwell - 1));


%1 make visual stimulus (2D stripes)
phaseStream = 2*pi*rand(1,nOns);
%pix2deg = 1;
xdeg = (1:screenPix(2))-0.5*screenPix(2);
ydeg = (1:screenPix(1))-0.5*screenPix(1);
[X,Y]=meshgrid(xdeg,ydeg);
stim_is = single(zeros(screenPix(1),screenPix(2),length(timeVec_stim)));
for ff = 1:nOns
    XY = X*cos(oriStream(ff))+Y*sin(oriStream(ff));
    AngFreqs = 2*pi* sfStream(ff) * XY + phaseStream(ff);
    stim_is(:,:,onFrames(ff):onFrames(ff)+dwell-1) = repmat(sin(AngFreqs),1,1,dwell);
end
stim_is = 0.5*(stim_is+1); %[0-1]


%% 2 compute response of the filter bank
paramIdx.cparamIdx = [];
paramIdx.predsRate = [];
[S_nm, timeVec_mdlResp] = preprocAll(stim_is, paramIdx, RF_insilico.ORSF.Fs_visStim, Fs);
S_nm = S_nm'; %predictXs accepts [nVar x nFrames]


%% 3 compute responese of the wavelet filter
%lagRange = [min(lagFrames)/Fs max(lagFrames)/Fs];%lag range provided as rr
%lagRange_model = [0 (gparams.tsize-1)/Fs];
lagRangeS_mdl = [mean(lagFrames)-0.5*filterWidth mean(lagFrames)+0.5*filterWidth]/Fs; %expected frame window of gabor wavelet bank
respDelay = lagRangeS_mdl(1):1/Fs:lagRangeS_mdl(2);

resp = zeros(nSF, nORs, numel(respDelay),nNeurons);
for iNeuron = 1:nNeurons
    [observed] = predictXs(timeVec_mdlResp, S_nm, ...
        squeeze(r0(iNeuron)), squeeze(rr(:,:,iNeuron)), [lagFrames(1) lagFrames(end)], tavg);
    
    %% 4 test OR tuning
    [avgPeriEventV, ~, periEventV] = eventLockedAvg(observed, timeVec_mdlResp, ...
        timeVec_stim(onFrames), oriSfStream, lagRangeS_mdl);
    %      avgPeriEventV: nEventTypes x nCells x nTimePoints
    %mresp_tmp = squeeze(mean(avgPeriEventV,3))';
    resp(:,:,:,iNeuron) = reshape(squeeze(avgPeriEventV), nSF, nORs, []);
    %sresp = squeeze(mean(periEventV,3));
end
RF_insilico.ORSF.respDelay = respDelay;

RF_insilico.ORSF.resp = resp;
% RF_insilico.ORSF.kernel = kernel; %FIX ME
RF_insilico.ORSF.oriList = oriList;
RF_insilico.ORSF.sfList = 1/A * sfList;
end

function checkGparam(gparams, screenPix, rr)
%NG in massive??
% Making wavelets...
% {^HThe following error occurred converting from gpuArray to single:
% Conversion to single from gpuArray is not possible.
% 
% Error in preprocWavelets_grid (line 358)
%                 gaborbank(:,:,:,wcount) = rgc;
% 
% Error in getInSilicoORSF>checkGparam (line 125)
% [gab, pp] = preprocWavelets_grid(zeros(screenPix(1),screenPix(2)), gparams);

gparams.show_or_preprocess = 0;
[gab, pp] = preprocWavelets_grid(zeros(screenPix(1),screenPix(2)), gparams);
nFilters = length(gab);
if ~isequal(size(rr,2), nFilters)
    error('#filters does not match. Check 1st and 3rd inputs');
end
end