%download data necessary for running wrapper_encoding in quetzal

ID = 1;
roiSuffix = '';
stimSuffix = '_part';
regressSuffix = '_nxv';

rescaleFac = 0.1;

%% copied from addDirPrefs.m
expInfo = getExpInfoNatMov(ID);

%dataPaths_server = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);
expDate = [expInfo.date(1:4) filesep expInfo.date(5:6) filesep expInfo.date(7:8)];
expName = num2str(expInfo.expID);

resizeDir = ['resize' num2str(rescaleFac*100)];
%saveDirBase = dirPref.saveDirBase;
saveDirBase = '/mnt/dshi0006_market/Massive/processed/';
dataPaths_server.imageSaveName = fullfile(saveDirBase,expDate,resizeDir,...
    ['imageData_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
    num2str(rescaleFac*100) '.mat']);
dataPaths_server.roiSaveName = [dataPaths_server.imageSaveName(1:end-4) roiSuffix '.mat'];
dataPaths_server.timeTableSaveName = [dataPaths_server.imageSaveName(1:end-4) roiSuffix '.csv'];
dataPaths_server.stimSaveName = fullfile(saveDirBase,expDate,resizeDir,...
    ['stimData_' regexprep(expDate, filesep,'_') '_' expName stimSuffix '.mat']);


dataPaths_local = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);



%% move data to local
copyfile(dataPaths_server.imageSaveName, dataPaths_local.imageSaveName);
copyfile(dataPaths_server.roiSaveName, dataPaths_local.roiSaveName);
copyfile(dataPaths_server.stimSaveName, dataPaths_local.stimSaveName);
copyfile(dataPaths_server.timeTableSaveName, dataPaths_local.timeTableSaveName);
