% if ~ispc
%     addpath(genpath('~/git'));
%     addDirPrefs;
% end
% 
% 
% ID = 8;
% rescaleFac = 0.10;
% roiSuffix = '';
% stimSuffix = '_square';
% regressSuffix = '_nxv';
% 
% 
% %% path
% expInfo = getExpInfoNatMov(ID);
% dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);
% encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];
% 
% load(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');

function ngIdx = detectNGidx(encodingSavePrefix, numIdx)
% ngIdx = detectNGidx(encodingSavePrefix, numIdx)

roiIdx = 1:numIdx;
ngIdx = [];
for ii = 1:numel(roiIdx)
    %disp(ii)
    encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        try
            encodingResult = load(encodingSaveName, 'RF_insilico','trained','trainParam');
           catch err
            disp(['MISSING ' encodingSaveName]);
            ngIdx = [ngIdx roiIdx(ii)];
            continue;
        end
    else
        disp(['MISSING ' encodingSaveName]);
        ngIdx = [ngIdx roiIdx(ii)];
        continue;
    end
end
 