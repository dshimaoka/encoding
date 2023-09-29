function dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix)
%dataPaths = getDataPaths(expInfo)
%returns full paths to the processed data used in encoding modeling of
%imaging data
if nargin<4
    stimSuffix = '';
end
if nargin<3
    roiSuffix = '';
end

%try
    dirPref = getpref('nsAnalysis','dirPref');
% catch err
%         addDirPrefs;
%         dirPref = getpref('nsAnalysis','dirPref');
% end

expDate = [expInfo.date(1:4) filesep expInfo.date(5:6) filesep expInfo.date(7:8)];
expName = num2str(expInfo.expID);

resizeDir = ['resize' num2str(rescaleFac*100)];
saveDirBase = dirPref.saveDirBase;
dataPaths.imageSaveName = fullfile(saveDirBase,expDate,resizeDir,...
    ['imageData_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
    num2str(rescaleFac*100) '.mat']);
% dataPaths.roiSaveName = [dataPaths.imageSaveName(1:end-4) roiSuffix '.mat'];
dataPaths.roiSaveName =  fullfile(saveDirBase,expDate,resizeDir,...
    ['roiData_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
    num2str(rescaleFac*100)  roiSuffix '.mat']); %13/6/2023
dataPaths.timeTableSaveName = [dataPaths.imageSaveName(1:end-4) roiSuffix '.csv'];
dataPaths.stimSaveName = fullfile(saveDirBase,expDate,resizeDir,...
    ['stimData_' regexprep(expDate, filesep,'_') '_' expName stimSuffix '.mat']);
dataPaths.encodingSavePrefix = fullfile(saveDirBase,expDate,resizeDir,...
    ['encoding_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
    num2str(rescaleFac*100) roiSuffix stimSuffix]);% '_' num2str(roiIdx(pen)) '.mat']);

switch getenv('COMPUTERNAME')
    case 'MU00175834'
        if sum(strcmp(expInfo.date, {'20230919','20230920'})) %high-res
            dataPaths.moviePath = 'E:\nishimoto2023\15Hz_120_skip1';
        else
            dataPaths.moviePath = 'Z:\Shared\Daisuke\natural\nishimoto2011';
        end
    case 'MU00011697'
        if sum(strcmp(expInfo.date, {'20230919','20230920'})) %high-res
            dataPaths.moviePath = '/mnt/syncitium/Daisuke/natural/nishimoto2023/15Hz_120_skip1';
        else
            dataPaths.moviePath = '/mnt/syncitium/Daisuke/natural/nishimoto2011';
        end
    case ''
        dataPaths.moviePath = 'TO BE FIXED';
end
