function insilicoORSFStim = getInSilicoORSFstim(gaborParamIdx, RF_insilico, ...
    trainParam_Fs, oriStimSize, useGPU)
%insilicoORSFStim = getInSilicoORSFstim(gaborParamIdx, RF_insilico, ...
    % trainParam_Fs, oriStimSize, useGPU)
if nargin < 5
    useGPU = 0;
end

screenPix = RF_insilico.ORSF.screenPix;

oriList = RF_insilico.ORSF.oriList;
sfList = RF_insilico.ORSF.sfList;
if ~isfield(RF_insilico.ORSF,'Fs_visStim') || isempty(RF_insilico.ORSF.Fs_visStim)
    RF_insilico.ORSF.Fs_visStim = gaborParamIdx.predsRate;
end
Fs_visStim = RF_insilico.ORSF.Fs_visStim;
dwell = RF_insilico.ORSF.dwell;

nORs = numel(oriList);
nSF = length(sfList);

nRepeats = RF_insilico.ORSF.nRepeats;

if size(sfList,1) < size(sfList,2)
    sfList = sfList';
end


sfrange = getSFrange_stim(screenPix, oriStimSize);

if max(sfList) > sfrange(2)
    warning(['specified SF deviates maximum SF of vis stim ' num2str(sfrange(2)) '[cpd]']);
end
if min(sfList) < sfrange(1)
       warning(['specified SF deviates minimum SF of vis stim ' num2str(sfrange(1)) '[cpd]']);
end 

%random varibles: spatial phase and OR and SF
oriSfStream = repmat(1:nORs*nSF, 1, nRepeats);
oriSfStream = oriSfStream(randperm(nORs*nSF*nRepeats));
[sfIdxStream, oriIdxStream] = ind2sub([nSF nORs], oriSfStream);
oriStream = oriList(oriIdxStream);
pixPerDeg = mean(screenPix./oriStimSize);
sfStream = 1/pixPerDeg * sfList(sfIdxStream); %convert cycles/deg to cycles/pix

nOns = length(oriStream);

gparams = preprocWavelets_grid_GetMetaParams(gaborParamIdx.gparamIdx);
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
gaborParamIdx.cparamIdx = [];
gaborParamIdx.predsRate = [];
[S_nm, timeVec_mdlResp] = preprocAll(stim_is, gaborParamIdx, RF_insilico.ORSF.Fs_visStim, ...
    trainParam_Fs, useGPU);
S_nm = S_nm'; %predictXs accepts [nVar x nFrames]


insilicoORSFStim.S_nm = S_nm;
insilicoORSFStim.timeVec_mdlResp = timeVec_mdlResp;
insilicoORSFStim.stim_is = stim_is;
insilicoORSFStim.timeVec_stim = timeVec_stim;
insilicoORSFStim.onFrames = onFrames;
insilicoORSFStim.oriStream = oriStream;
insilicoORSFStim.sfStream = sfStream;
insilicoORSFStim.oriSfStream = oriSfStream;


