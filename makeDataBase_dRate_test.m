%makeDataBase.m:
%this script process and save imaging and stimulus data(saveImageProcess & saveStimData), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m

if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end

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
procParam.lpFreq = []; %2

rebuildImageData = false;
makeMask = false;
uploadResult = true;

%downsample of stim & imaging data
%dsRate = procParam.lpFreq;%[Hz]

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2;
gaborBankParamIdx.nlparamIdx = 1;
gaborBankParamIdx.dsparamIdx = 1;
gaborBankParamIdx.nrmparamIdx = 1;
gaborBankParamIdx.predsRate = 15; %Hz %mod(dsRate, predsRate) must be 0
%< sampling rate of gabor bank filter

dataPaths = getDataPaths(expInfo, procParam.rescaleFac);



expDate = [expInfo.date(1:4) filesep expInfo.date(5:6) filesep expInfo.date(7:8)];

%% save image and processed data
%saveDir = fullfile(oeOriDir, fullOEName);
%imProc_fullpath = fullfile(saveDir, imDataName);
    
if exist(dataPaths.imageSaveName,'file') % && 
    load(dataPaths.imageSaveName,'imageProc');
else
    %save .mat and .csv files
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


%% TMP
roiIdx = 7618;
imageProc_s = imageProc;
imageProc_s.V = imageProc.V(roiIdx,:);
%%

dsRate = 3;% 10]; %sampling rate of hemodynamic coupling function
for ii = 1%1:numel(dsRate)
    suffix = ['_dsRate' num2str(dsRate(ii))];
    
        %% convert processed signal to a format compatible with fitting
        [observed, TimeVec_ds_c] = prepareObserved(imageProc_s, dsRate(ii));
        %observed: time x pixel
        %< TODO: BETTER WAY TO DO DOWNSAMPLING?
        %< observed is NOT saved
    
        %% save as timetable
        TT = timetable(seconds(TimeVec_ds_c), observed);%instantaneous
        writetimetable(TT, [dataPaths.timeTableSaveName(1:end-4) suffix '.csv']);%slow
    
        clear TT
    
    
    
    %% prepare stimulus (~5h in my PC)
    %DUMM THIS TAKES AGES!
%     [S_fin, TimeVec_stim_cat] = saveGaborBankOut(dataPaths.moviePath, imageProc.cic, ...
%         dsRate(ii), gaborBankParamIdx, 0);
%     
%     %dirPref = getpref('nsAnalysis','dirPref');
%     %oeOriServer = dirPref.oeOriServer; %direct ethernet connection
%     %saveDir = fullfile(oeOriDir, fullOEName);
%     
%     
%     %% save gabor filter output as .mat
%     save( [dataPaths.stimSaveName(1:end-4) suffix '.mat'], 'TimeVec_stim_cat',...
%         'S_fin', 'gaborBankParamIdx', 'dsRate');
end
