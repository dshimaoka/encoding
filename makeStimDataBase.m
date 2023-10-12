%makeStimDataBase.m:
%this script process and save stimulus data(saveGaborBankOut), together with in-silico simulation 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m

if isempty(getenv('COMPUTERNAME'))
    addpath(genpath('~/git'));
    % addDirPrefs; %BAD IDEA TO write matlabprefs.mat in a batch job!!    
    [~,narrays] = getArray('script_wrapper.sh');
else
    narrays = 1;
end

%% draw slurm ID for parallel computation specifying stimulus ID    
pen = getPen; 


expID = 9;


roiSuffix = '';
stimSuffix = '_square30';

%% imaging parameters
rescaleFac = 0.1;
procParam.cutoffFreq = 0.02; %0.1
procParam.lpFreq = []; %2
rotateInfo = [];
rebuildImageData = false;
makeMask = false;%true;
uploadResult = true;
dsRate = 1;%[Hz] %sampling rate of hemodynamic coupling function


%% stimulus parameters
%ID1,3
%stimXrange = 24:156; %201:256; %1:left
%stimYrange = 5:139; %72-28+1:72+28;  %1:top
%ID2
%stimXrange = 161:238;
%stimYrange = 29:108;
%ID8,9
%test1
% stimXrange = 293:293+247;
% stimYrange = 378:378+247;
%test2
% stimXrange =768:768+247;
% stimYrange = 378:378+247;
%test3 square18
%stimXrange = 800-247:800+247;
%stimYrange = 540-247:540+247;
%test4: rect18-40 ... Sfin = [7200 x 14375]
%stimXrange = 800-247:800+247;
%stimYrange = 1:1080;
%test5: rect10-40 ... Sfin = [7200 x 6555]
%stimXrange = 1047-275:1047;
%stimYrange = 540-247:1080;
%test6: square30
stimXrange = 293:1080;
stimYrange = 293:1080;

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2;
gaborBankParamIdx.nlparamIdx = 1;
gaborBankParamIdx.dsparamIdx = 1;
gaborBankParamIdx.nrmparamIdx = 1;
gaborBankParamIdx.predsRate = 15; %Hz %mod(dsRate, predsRate) must be 0
%< sampling rate of gabor bank filter

expInfo = getExpInfoNatMov(expID);
dataPaths = getDataPaths(expInfo, rescaleFac, roiSuffix, stimSuffix);

%% load cic and stimInfo
load(dataPaths.imageSaveName,'cic','stimInfo');

%% motion-energy model computation from visual stimuli
if ~exist(dataPaths.stimSaveName,'file') 
    
    [stimInfo.stimXdeg, stimInfo.stimYdeg] = stimPix2Deg(stimInfo, stimXrange, stimYrange);
    screenPixNew = [max(stimYrange)-min(stimYrange)+1 max(stimXrange)-min(stimXrange)+1];
    stimInfo.width = stimInfo.width * screenPixNew(2)/stimInfo.screenPix(2);
    stimInfo.height = stimInfo.height * screenPixNew(1)/stimInfo.screenPix(1);
    stimInfo.screenPix = screenPixNew;
    
    %% prepare model output SLOW
    theseTrials = pen:narrays:cic.nrTrials;
    [S_fin, TimeVec_stim_cat] = saveGaborBankOut(dataPaths.moviePath, cic, ...
        dsRate, gaborBankParamIdx, 0, stimYrange, stimXrange, theseTrials);
        
    %% save gabor filter output as .mat
    save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', ...
        'gaborBankParamIdx', 'dsRate','cic','stimInfo');
else
    save( dataPaths.stimSaveName, 'cic','stimInfo','-append');
end


%% create stimuli for in-silico simulation. moved from wrapper_encoding
%stimInfo
%stimSz = [stimInfo.height stimInfo.width];
%gaborBankParamIdx
%dsRate

inSilicoRFStimName = [dataPaths.stimSaveName(1:end-4) '_insilicoRFstim.mat'];
inSilicoORSFStimName = [dataPaths.stimSaveName(1:end-4) '_insilicoORSFstim.mat'];
stimSz = [stimInfo.height stimInfo.width];

RF_insilico = struct;
RF_insilico.noiseRF.nRepeats = 80; %10 FIX
RF_insilico.noiseRF.dwell = 15; %frames
fac = mean(stimInfo.screenPix)/20;
RF_insilico.noiseRF.screenPix = round(stimInfo.screenPix/fac);%4 %[y x] %FIX %spatial resolution of noise stimuli
RF_insilico.noiseRF.maxRFsize = 10; %deg in radius

try
    [inSilicoRFStim] = ...
        getInSilicoRFstim(gaborBankParamIdx, RF_insilico, dsRate, 1);
catch err
    [inSilicoRFStim] = ...
        getInSilicoRFstim(gaborBankParamIdx, RF_insilico, dsRate, 0);
end
save(inSilicoRFStimName, 'inSilicoRFStim','gaborBankParamIdx',"RF_insilico",'-v7.3');


RF_insilico = struct;
RF_insilico.ORSF.screenPix = stimInfo.screenPix; %[y x]
nORs = 10;
oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
RF_insilico.ORSF.oriList = oriList(1:end-1);
SFrange_stim = getSFrange_stim(RF_insilico.ORSF.screenPix, stimSz);
%SFrange_mdl = getSFrange_mdl(RF_insilico.ORSF.screenPix, stimSz, gaborBankParamIdx.gparamIdx);
RF_insilico.ORSF.sfList = logspace(log10(SFrange_stim(1)), log10(SFrange_stim(2)), 5); %6 %[cycles/deg];
RF_insilico.ORSF.nRepeats = 10;%15;
RF_insilico.ORSF.dwell = 45; %#stimulus frames

try
    [inSilicoORSFStim] = ...
        getInSilicoORSFstim(gaborBankParamIdx, RF_insilico, dsRate, stimSz, 1);
catch err
    [inSilicoORSFStim] = ...
        getInSilicoORSFstim(gaborBankParamIdx, RF_insilico, dsRate, stimSz, 0);
end
save(inSilicoORSFStimName, 'inSilicoORSFStim','gaborBankParamIdx',"RF_insilico",'stimSz','-v7.3');
