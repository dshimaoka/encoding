%makeDataBase.m:
%this script process and save imaging and stimulus data(saveImageProcess & saveStimData), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m

% expInfo.nsName = 'CJ229.oriXYZc.170024';%'CJ229.runPassiveMovies.024114';
% expInfo.expID = 5; %21;
% expInfo.subject = 'CJ229';
% expInfo.date = '202210310';%'20221101';

expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

procParam.rescaleFac = 0.25;
procParam.cutoffFreq = 0.01;%0.1;
procParam.lpFreq = 2; %1

rebuildImageData = false;
makeMask = false;
uploadResult = true;

%downsample of stim & imaging data
dsRate = 1;%[Hz]

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2;
gaborBankParamIdx.nlparamIdx = 1;
gaborBankParamIdx.dsparamIdx = 1;
gaborBankParamIdx.nrmparamIdx = 1;


dataPaths = getDataPaths(expInfo, procParam.rescaleFac);
moviePath = 'Z:\Shared\Daisuke\natural\nishimoto2011';



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
    imageSaveName = fullfile(fullfile(dirPref.rootDir,expInfo.subject,'processed'), [imDataName '.mat']);
    
    status = movefile(imageSaveName, dataPaths.imageSaveName);
    if status==1
        disp([imDataName ' was successfully uploaded']);
    else
        disp([imDataName ' was NOT uploaded']);
    end

end

observed = prepareObserved(imageProc, dsRate);


%% save as timetable
TT = timetable(seconds(TimeVec_ds_c), observed);%instantaneous
writetimetable(TT, dataPaths.timeTableSaveName);%slow

clear TT

%% prepare stimulus (~5h in my PC)
[S_fin, TimeVec_stim_cat] = saveStimData(moviePath, imageProc.cic, ...
    imageProc.stimInfo, dsRate, gaborBankParamIdx, 0);
%TimeVec_stim_cat = TimeVec_ds_c; %HACK

%dirPref = getpref('nsAnalysis','dirPref');
%oeOriServer = dirPref.oeOriServer; %direct ethernet connection
%saveDir = fullfile(oeOriDir, fullOEName);


%% save gabor filter output as .mat
save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', 'gaborBankParamIdx', 'dsRate');

