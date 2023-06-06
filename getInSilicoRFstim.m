function insilicoRFStim = getInSilicoRFstim(gaborBankParamIdx, RF_insilico, trainParam_Fs)

screenPix = RF_insilico.noiseRF.screenPix;
nRepeats = RF_insilico.noiseRF.nRepeats;

if ~isfield(RF_insilico.noiseRF,'Fs_visStim') || isempty(RF_insilico.noiseRF.Fs_visStim)
   Fs_visStim = gaborBankParamIdx.predsRate;
else
    FS_visStim = RF_insilico.noiseRF.Fs_visStim;
end

%%1 make sparse white noise
dotStream = repmat(1:screenPix(1)*screenPix(2), 1, nRepeats);
dotStream = dotStream(randperm(screenPix(1)*screenPix(2)*nRepeats));
dotStream = repmat(dotStream,RF_insilico.noiseRF.dwell,1);
dotStream = dotStream(:)';

nFrames = numel(dotStream);
timeVec_stim = 1/Fs_visStim*(0:nFrames-1);%0:1/Fs:maxT;%[s]

%[dotYidxStream, dotXidxStream] = ind2sub([screenPix screenPix], dotStream);
stim_is_flat = single(zeros(screenPix(1)*screenPix(2), nFrames));
for tt = 1:nFrames
    stim_is_flat(dotStream(tt),tt)=1;
end
%stim_is_flat(dotStreamIdx) = 1; %<this is what I want to do wo for loop
stim_is = reshape(stim_is_flat, screenPix(1), screenPix(2), nFrames);
clear stim_is_flat

%% 2 compute response of the filter bank, at Fs Hz
gaborBankParamIdx.cparamIdx = [];
gaborBankParamIdx.predsRate = [];
[S_nm, timeVec_mdlResp] = preprocAll(stim_is, gaborBankParamIdx, Fs_visStim, trainParam_Fs);
S_nm = S_nm'; %predictXs accepts [nVar x nFrames]

insilicoRFStim.S_nm = S_nm;
insilicoRFStim.timeVec_mdlResp = timeVec_mdlResp;
insilicoRFStim.stim_is = stim_is;
insilicoRFStim.timeVec_stim = timeVec_stim;
