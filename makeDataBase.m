%makeDataBase.m:
%this script process and save imaging and stimulus data(saveImageProcess & saveStimData), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m

% expInfo.nsName = 'CJ229.oriXYZc.170024';%'CJ229.runPassiveMovies.024114';
% expInfo.expID = 5; %21;
% expInfo.subject = 'CJ229';
% expInfo.date = '202210310';%'20221101';

if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end

expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

procParam.rescaleFac = 0.25;
procParam.cutoffFreq = 0.01;%0.1;
procParam.lpFreq = 2; %2

rebuildImageData = false;
makeMask = false;
uploadResult = true;

%downsample of stim & imaging data
dsRate = procParam.lpFreq;%[Hz]

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2;
gaborBankParamIdx.nlparamIdx = 1;
gaborBankParamIdx.dsparamIdx = 1;
gaborBankParamIdx.nrmparamIdx = 1;


dataPaths = getDataPaths(expInfo, procParam.rescaleFac);


expDate = [expInfo.date(1:4) filesep expInfo.date(5:6) filesep expInfo.date(7:8)];

%% save image and processed data
%saveDir = fullfile(oeOriDir, fullOEName);
%imProc_fullpath = fullfile(saveDir, imDataName);
    
if exist(dataPaths.imageSaveName,'file') % && 
    load(dataPaths.imageSaveName,'imageProc');
else
    imageProc = saveImageProcess(expInfo, procParam, rebuildImageData,...
        makeMask, uploadResult);
    
    [~,imDataName] = fileparts(dataPaths.imageSaveName);
    
    dirPref = getpref('nsAnalysis','dirPref');
    imageSaveName = fullfile(fullfile(dirPref.rootDir,expInfo.subject,'processed'), [imDataName '.mat']);
    
    status = movefile(imageSaveName, dataPaths.imageSaveName);
    if status==1
        disp([imDataName ' was successfully uploaded']);
    else
        disp([imDataName ' was NOT uploaded']);
    end

end

%% convert processed signal to a format compatible with fitting
[observed, TimeVec_ds_c] = prepareObserved(imageProc, dsRate);
%< TODO: BETTER WAY TO DO DOWNSAMPLING?
%< observed is NOT saved

%% save as timetable
TT = timetable(seconds(TimeVec_ds_c), observed);%instantaneous
writetimetable(TT, dataPaths.timeTableSaveName);%slow

clear TT





%% prepare model output (~5h in my PC)
[S_fin, TimeVec_stim_cat] = saveGaborBankOut(moviePath, imageProc.cic, ...
     dsRate, gaborBankParamIdx, 0);
%TimeVec_stim_cat = TimeVec_ds_c; %HACK


%% prepare hdr
%TODO: replace w fitIRF.m
n1 =3;
k1 = 2000/1000;
delay1 = 2000/1000;

a = .2728;%.15;
n2 =5;
k2 = 2000/1000;
delay2 = 7000/1000;

%tHDR = TimeVec_stim_cat(1:20);%t(1:20)-min(t); %20x1 array
tHDR = (0:1/120:30)';
%hdr = gammaPDF(n1,k1,tHDR-delay1)- a*gammaPDF(n2,k2,tHDR-delay2);%gammaPDF is missing
hdr = -(pdf('gamma',tHDR-delay1, n1, k1) - a*pdf('gamma',tHDR-delay2, n2, k2));%20x1 array
%plot(tHDR, hdr);

PRFparam.hdr = hdr;%hemodynamic impulse response function
PRFparam.phi = imageProc.stimInfo.screenPix(2);
PRFparam.theta = imageProc.stimInfo.screenPix(1);
PRFparam.nAng = 16;  %number of polar angles
PRFparam.radList = linspace(.1,2,16);  %number of eccentricities
PRFparam.cparamIdx = 1;

 [S_fin, TimeVec_stim_cat] = savePRFOut(moviePath, imageProc.cic, ...
    dsRate, PRFparam, 0);
%dirPref = getpref('nsAnalysis','dirPref');
%oeOriServer = dirPref.oeOriServer; %direct ethernet connection
%saveDir = fullfile(oeOriDir, fullOEName);


%% save gabor filter output as .mat
save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', 'gaborBankParamIdx', 'dsRate');

