%makeDataBase.m:
%this script process and save imaging and stimulus data(saveImageProcess & saveStimData), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m
% as of 24/2, took 1.5h to complete


if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


expInfo = getExpInfoNatMov(6);

procParam.rescaleFac = 0.10;%0.25;
procParam.cutoffFreq = 0.02;%0.1;
procParam.lpFreq = []; %2

rebuildImageData = false;
makeMask = true;
uploadResult = true;

%sampling rate of hemodynamic coupling function
dsRate = 1;%[Hz]

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2;
gaborBankParamIdx.nlparamIdx = 1;
gaborBankParamIdx.dsparamIdx = 1;
gaborBankParamIdx.nrmparamIdx = 1;
gaborBankParamIdx.predsRate = 15; %Hz %mod(dsRate, predsRate) must be 0
%< sampling rate of gabor bank filter

dataPaths = getDataPaths(expInfo, procParam.rescaleFac);


%% save image and processed data
if exist(dataPaths.imageSaveName,'file') % && 
    load(dataPaths.imageSaveName,'imageProc');
else
    imageProc = saveImageProcess(expInfo, procParam, rebuildImageData,...
        makeMask, uploadResult);
    
    [~,imDataName] = fileparts(dataPaths.imageSaveName);
    
    dirPref = getpref('nsAnalysis','dirPref');
    imageSaveName = fullfile(fullfile(dirPref.rootDir,expInfo.subject,'processed'), [imDataName '.mat']);
    
    
    mkdir(fileparts(dataPaths.imageSaveName))
    
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


%% extract data within mask
theseIdx = find(~isnan(imageProc.nanMask));
[Y,X,Z] = ind2sub(size(imageProc.nanMask), theseIdx);
observed = observed(:,theseIdx);
save(dataPaths.imageSaveName, 'X','Y','theseIdx','-append');

%% save as timetable
TT = timetable(seconds(TimeVec_ds_c), observed);%instantaneous
writetimetable(TT, dataPaths.timeTableSaveName);%slow
clear TT


%% prepare model output SLOW
[S_fin, TimeVec_stim_cat] = saveGaborBankOut(dataPaths.moviePath, imageProc.cic, ...
     dsRate, gaborBankParamIdx, 0);

 
%% save gabor filter output as .mat
save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', ...
    'gaborBankParamIdx', 'dsRate');

