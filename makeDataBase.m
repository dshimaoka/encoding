%makeDataBase.m:
%this script process and save imaging and stimulus data(saveImageProcess & saveStimData), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m
% as of 24/2, took 1.5h to complete


if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


expInfo = getExpInfoNatMov(7);

roiSuffix = '_v1v2_s_015hz';
rescaleFac = 0.5;%0.25;
procParam.cutoffFreq = 0.15;
procParam.lpFreq = []; %2

rotateInfo = [];

rebuildImageData = false;
makeMask = false;%true;
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

dataPaths = getDataPaths(expInfo, rescaleFac, roiSuffix);


%% save image and processed data
if exist(dataPaths.imageSaveName,'file') % && 
    disp(['Loading ' dataPaths.imageSaveName]);
    load(dataPaths.imageSaveName,'imageProc');
else
    
    [imageProc, cic, stimInfo] = saveImageProcess(expInfo, rescaleFac, rebuildImageData);
    
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

%% extract data within mask
if makeMask
    imagesc(imageData.meanImage);colormap(gray);
    roiAhand = images.roi.AssistedFreehand;
    draw(roiAhand);
    roi = createMask(roiAhand);
    nanMask = nan(size(roi));
    nanMask(roi) = 1;
    
    imageData.imstack = imageData.imstack.*(nanMask==1);
    imageData.imageMeans = squeeze(mean(mean(imageData.imstack)));
else
    %nanMask = nan(size(imageData.meanImage));
    %nanMask(226:275,101:150) = 1;
    nanMask = nan(318,300);
    nanMask(246:255,121:130) = 1;
end
imageProc.nanMask = nanMask;

theseIdx = find(~isnan(imageProc.nanMask));
[Y,X,Z] = ind2sub(size(imageProc.nanMask), theseIdx);
meanImage = imageData.meanImage;
save(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');

%% temporal filtering of pixels within mask
Fs = 1/median(diff(imageProc.OETimes.camOnTimes));
imageProc.V = filtV(imageProc.V(theseIdx,:), Fs, procParam.cutoffFreq, procParam.lpFreq);

%% convert processed signal to a format compatible with fitting
[observed, TimeVec_ds_c] = prepareObserved(imageProc, dsRate);
%< TODO: BETTER WAY TO DO DOWNSAMPLING?
%< observed is NOT saved

%% save as timetable
TT = timetable(seconds(TimeVec_ds_c), observed);%instantaneous
writetimetable(TT, dataPaths.timeTableSaveName);%slow
clear TT

if ~exist(dataPaths.stimSaveName,'file') 
    %% prepare model output SLOW
    [S_fin, TimeVec_stim_cat] = saveGaborBankOut(dataPaths.moviePath, imageProc.cic, ...
        dsRate, gaborBankParamIdx, 0);
        
    %% save gabor filter output as .mat
    save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', ...
        'gaborBankParamIdx', 'dsRate','cic','stimInfo');
end
