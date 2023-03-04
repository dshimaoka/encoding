function dataPaths = getDataPaths(expInfo,rescaleFac)
%dataPaths = getDataPaths(expInfo)
%returns full paths to the processed data used in encoding modeling of
%imaging data

dirPref = getpref('nsAnalysis','dirPref');

expDate = [expInfo.date(1:4) filesep expInfo.date(5:6) filesep expInfo.date(7:8)];
expName = num2str(expInfo.expID);

resizeDir = ['resize' num2str(rescaleFac*100)];
saveDirBase = dirPref.saveDirBase;
dataPaths.imageSaveName = fullfile(saveDirBase,expDate,resizeDir,...
    ['imageData_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
    num2str(rescaleFac*100) '.mat']);
dataPaths.timeTableSaveName = [dataPaths.imageSaveName(1:end-4) '.csv'];
dataPaths.stimSaveName = fullfile(saveDirBase,expDate,resizeDir,...
    ['stimData_' regexprep(expDate, filesep,'_') '_' expName '.mat']);
dataPaths.encodingSavePrefix = fullfile(saveDirBase,expDate,resizeDir,...
    ['encoding_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
    num2str(rescaleFac*100)]);% '_' num2str(roiIdx(pen)) '.mat']);

switch getenv('COMPUTERNAME')
    case 'MU00175834'
        dataPaths.moviePath = 'Z:\Shared\Daisuke\natural\nishimoto2011';
    case ''
        dataPaths.moviePath = 'TO BE FIXED';
end
