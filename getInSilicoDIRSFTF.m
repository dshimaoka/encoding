function RF_insilico = getInSilicoDIRSFTF(paramIdx, trained, trainParam, ...
    RF_insilico, stimSz, insilicoDIRSFTFStim)
%INPUT:
%gparamIdx: parameter Idx supplied to preprocWavelets_grid_GetMetaParams
%r0: scalar
%rr: [nDelays of hemodynamic coupling x nFilters]
%screenPix: screen pixel size (assume same size of x & y )
%Fs: sampling rate of in-silico visual stim
%nRepeats: number of stimulus presentation per OR and SF
%nOR: number of ORs (equally spaced between 0-pi
%sfList: list of SFs (cycles per deg)
%stimSz: [height x width] [deg]
%useGPU: whether to use GPU for proprocAll/preprocWavelets_grid (default:1)
%
%OUTPUT:
%resp: resp across repeats and delays [nSFs x nDIRs x nTFs]
%dirList: list of DIRs (1st dim of mresp) (rad)
%sfList: list of SFs (2nd dim of mresp) (cycles per pixel)
%tfList: list of TFs (3rd dim of mresp) (Hz)

r0 = trained.r0e;
rr = trained.rre;
lagFrames = trainParam.lagFrames;
tavg = trainParam.tavg;
Fs = trainParam.Fs;


dirList = RF_insilico.DIRSFTF.dirList;
sfList = RF_insilico.DIRSFTF.sfList;
tfList = RF_insilico.DIRSFTF.tfList;
nDIRs = numel(dirList);
nSF = length(sfList);
nTF = length(tfList);
nNeurons = size(rr,3);


gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
%checkGparam(gparams, screenPix, rr);

filterWidth = gparams.tsize; %#frames of visual stimulus

%% compute response of the filter bank
if nargin<6 || isempty(insilicoDIRSFTFStim)
    insilicoDIRSFTFStim= getinsilicoDIRSFTFStim(paramIdx, RF_insilico, trainParam.Fs, stimSz);
end
S_nm = insilicoDIRSFTFStim.S_nm;
timeVec_mdlResp = insilicoDIRSFTFStim.timeVec_mdlResp;
%stim_is = insilicoDIRSFTFStim.stim_is;
timeVec_stim = insilicoDIRSFTFStim.timeVec_stim;
onFrames = insilicoDIRSFTFStim.onFrames;
dirSfTfStream = insilicoDIRSFTFStim.dirSfTfStream;

%% 3 compute responese of the wavelet filter
%lagRange = [min(lagFrames)/Fs max(lagFrames)/Fs];%lag range provided as rr
%lagRange_model = [0 (gparams.tsize-1)/Fs];
lagRangeS_mdl = [mean(lagFrames)-0.5*filterWidth mean(lagFrames)+0.5*filterWidth]/Fs; %expected frame window of gabor wavelet bank
respDelay = lagRangeS_mdl(1):1/Fs:lagRangeS_mdl(2);

resp = zeros(nSF, nDIRs, nTF, numel(respDelay),nNeurons);
for iNeuron = 1:nNeurons
    [observed] = predictXs(timeVec_mdlResp, S_nm, ...
        squeeze(r0(iNeuron)), squeeze(rr(:,:,iNeuron)), [lagFrames(1) lagFrames(end)], tavg);
    
    %% 4 test OR tuning
    [avgPeriEventV, ~, periEventV] = eventLockedAvg(observed, timeVec_mdlResp, ...
        timeVec_stim(onFrames), dirSfTfStream, lagRangeS_mdl);
    %      avgPeriEventV: nEventTypes x nCells x nTimePoints
    resp(:,:,:,:,iNeuron) = reshape(squeeze(avgPeriEventV), nSF, nDIRs, nTF, []);
end
RF_insilico.DIRSFTF.respDelay = respDelay;

RF_insilico.DIRSFTF.resp = resp;
% RF_insilico.DIRSFTF.kernel = kernel; %FIX ME
%RF_insilico.DIRSFTF.dirList = dirList;
%RF_insilico.DIRSFTF.sfList = 1/pixPerDeg * sfList;
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
% Error in getInSilicoDIRSFTF>checkGparam (line 125)
% [gab, pp] = preprocWavelets_grid(zeros(screenPix(1),screenPix(2)), gparams);

gparams.show_or_preprocess = 0;
[gab, pp] = preprocWavelets_grid(zeros(screenPix(1),screenPix(2)), gparams);
nFilters = length(gab);
if ~isequal(size(rr,2), nFilters)
    error('#filters does not match. Check 1st and 3rd inputs');
end
end