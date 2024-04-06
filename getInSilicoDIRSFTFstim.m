function insilicoDIRSFTFStim = getInSilicoDIRSFTFstim(gaborParamIdx, RF_insilico, ...
    trainParam_Fs, stimSize, useGPU)
%insilicoORSFStim = getInSilicoORSFstim(gaborParamIdx, RF_insilico, ...
    % trainParam_Fs, oriStimSize, useGPU)
if nargin < 5
    useGPU = 0;
end

screenPix = RF_insilico.DIRSFTF.screenPix;

dirList = RF_insilico.DIRSFTF.dirList;
sfList = RF_insilico.DIRSFTF.sfList;
tfList = RF_insilico.DIRSFTF.tfList;

if ~isfield(RF_insilico.DIRSFTF,'Fs_visStim') || isempty(RF_insilico.DIRSFTF.Fs_visStim)
    RF_insilico.DIRSFTF.Fs_visStim = gaborParamIdx.predsRate;
end
Fs_visStim = RF_insilico.DIRSFTF.Fs_visStim;
dwell = RF_insilico.DIRSFTF.dwell;

nDIRs = numel(dirList);
nSF = length(sfList);
nTF = length(tfList);

nRepeats = RF_insilico.DIRSFTF.nRepeats;

if size(sfList,1) < size(sfList,2)
    sfList = sfList';
end


sfrange = getSFrange_stim(screenPix, stimSize);

if max(sfList) > sfrange(2)
    warning(['specified SF deviates maximum SF of vis stim ' num2str(sfrange(2)) '[cpd]']);
end
if min(sfList) < sfrange(1)
       warning(['specified SF deviates minimum SF of vis stim ' num2str(sfrange(1)) '[cpd]']);
end 

%random varibles: spatial phase and DIR and SF and TF
dirSfTfStream = repmat(1:nDIRs*nSF*nTF, 1, nRepeats);
dirSfTfStream = dirSfTfStream(randperm(nDIRs*nSF*nTF*nRepeats));
[sfIdxStream, dirIdxStream, tfIdxStream] = ind2sub([nSF nDIRs nTF], dirSfTfStream);
dirStream = dirList(dirIdxStream);
pixPerDeg = mean(screenPix./stimSize);
sfStream = 1/pixPerDeg * sfList(sfIdxStream); %convert cycles/deg to cycles/pix
tfStream = tfList(tfIdxStream);

nOns = length(dirStream);

gparams = preprocWavelets_grid_GetMetaParams(gaborParamIdx.gparamIdx);
%checkGparam(gparams, screenPix, rr);

filterWidth = gparams.tsize; %#frames of visual stimulus
onFrames = dwell*(1:nOns);%filterWidth*(1:nOns);
timeVec_stim = 1/Fs_visStim*(0:(onFrames(end) + dwell - 1));


%1 make visual stimulus (2D stripes)
phaseInit = 2*pi*rand(1,nOns); %spatial phase at the time of stimulus onset

%pix2deg = 1;
xdeg = (1:screenPix(2))-0.5*screenPix(2);
ydeg = (1:screenPix(1))-0.5*screenPix(1);
[X,Y]=meshgrid(xdeg,ydeg);
stim_is = single(zeros(screenPix(1),screenPix(2),length(timeVec_stim)));

for ff = 1:nOns
    XY = X*cos(dirStream(ff))+Y*sin(dirStream(ff));
    AngFreqs = 2*pi* sfStream(ff) * XY + phaseInit(ff);
    %     stim_is(:,:,onFrames(ff):onFrames(ff)+dwell-1) = repmat(sin(AngFreqs),1,1,dwell);
    phaseDelay = tfStream(ff) * 2*pi / Fs_visStim; %temporal phase advancement per frame
    
    for id = 1:dwell %slow
        thisFrame = onFrames(ff)+id-1;
        %thisFrame = onFrames(ff):onFrames(ff)+dwell-1
        stim_is(:,:,thisFrame) = sin(AngFreqs + phaseDelay*thisFrame);
    end
end
stim_is = 0.5*(stim_is+1); %[0-1]


%% 2 compute response of the filter bank
gaborParamIdx.cparamIdx = [];
gaborParamIdx.predsRate = [];
[S_nm, timeVec_mdlResp] = preprocAll(stim_is, gaborParamIdx, RF_insilico.DIRSFTF.Fs_visStim, ...
    trainParam_Fs, useGPU);
S_nm = S_nm'; %predictXs accepts [nVar x nFrames]


insilicoDIRSFTFStim.S_nm = S_nm;
insilicoDIRSFTFStim.timeVec_mdlResp = timeVec_mdlResp;
%insilicoDIRSFTFStim.stim_is = stim_is; %14/11/2023
insilicoDIRSFTFStim.timeVec_stim = timeVec_stim;
insilicoDIRSFTFStim.onFrames = onFrames;
insilicoDIRSFTFStim.dirStream = dirStream;
insilicoDIRSFTFStim.sfStream = sfStream;
insilicoDIRSFTFStim.tfStream = tfStream;
insilicoDIRSFTFStim.dirSfTfStream = dirSfTfStream;


