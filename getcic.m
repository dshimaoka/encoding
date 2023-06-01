function c = getcic(expInfo)
% under construction

dirPref = getpref('nsAnalysis','dirPref');

YYYYMMDD = expInfo.date;

expDate = sprintf('%s\\%s\\%s',YYYYMMDD(1:4),YYYYMMDD(5:6), YYYYMMDD(7:8));

DirBase = fullfile(dirPref.rootDir,expDate);%,expName);
%ephysDirBase = fullfile(DirBase,fullOEName,'Record Node 103\experiment1\recording1');
%saveDirBase = fullfile(rootDir,subject,'processed');
%OEInfo.jsonFile = fullfile(ephysDirBase,'structure.oebin');
stimName = [fullOEName(1:end-20) '.mat'];
stimFile = fullfile(DirBase, stimName);
load(stimFile,'c');