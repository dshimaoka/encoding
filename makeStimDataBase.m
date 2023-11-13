
%makeStimDataBase.m:
%this script process and save stimulus data(saveGaborBankOut), together with in-silico simulation 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m

if isempty(getenv('COMPUTERNAME'))
    addpath(genpath('~/git'));
    % addDirPrefs; %BAD IDEA TO write matlabprefs.mat in a batch job!!    
    [~,narrays] = getArray('script_makeStimDataBase.sh');
    setenv('LD_LIBRARY_PATH', '/usr/local/matlab/r2021a/sys/opengl/lib/glnxa64:/usr/local/matlab/r2021a/bin/glnxa64:/usr/local/matlab/r2021a/extern/lib/glnxa64:/usr/local/matlab/r2021a/cefclient/sys/os/glnxa64:/usr/local/matlab/r2021a/runtime/glnxa64:/usr/local/matlab/r2021a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/matlab/r2021a/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/libjpeg-turbo/1.4.2/lib64:/opt/munge-0.5.14/lib:/opt/slurm-22.05.9/lib:/opt/slurm-22.05.9/lib/slurm:/usr/lib64:');
    addpath('/usr/bin/');

else
    narrays = 1;
end

%% draw slurm ID for parallel computation specifying stimulus ID    
pen = getPen; 


expID = 9;


roiSuffix = '';
stimSuffix = '_square30_2';

%% imaging parameters
rescaleFac = 0.1;
procParam.cutoffFreq = 0.02; %0.1
procParam.lpFreq = []; %2
rotateInfo = [];
rebuildImageData = false;
makeMask = false;%true;
uploadResult = true;
dsRate = 1;%[Hz] %sampling rate of hemodynamic coupling function
useGPU = 0;

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
%stimXrange = 293:1080;
%stimYrange = 293:1080;
%test7: square20
% y: [-13 +7]
% x: [12 +8]
%stimXrange = 631:1171;
%stimYrange = 351:891;
%test8: square24
% y: [-17 ~ +7]
% x: [-16 ~ +8]
%stimXrange = 493:1141;
%stimYrange = 324:972;
%test9 for left hem
%y = [-19~+9]
%x = [-4~+24]
% stimXrange = [850:(850+756)];
% stimYrange = [297:1053];
stimXrange = [816:1616];
stimYrange = [280:1080];

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2; %4 for only small RFs
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
        dsRate, gaborBankParamIdx, 0, stimYrange, stimXrange, theseTrials, useGPU);
        
    %% save gabor filter output as .mat
    save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', ...
        'gaborBankParamIdx', 'dsRate','cic','stimInfo');
else
    save( dataPaths.stimSaveName, 'cic','stimInfo','-append');
end


