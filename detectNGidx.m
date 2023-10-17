function ngIdx = detectNGidx(encodingSavePrefix, numIdx)
% ngIdx = detectNGidx(encodingSavePrefix, numIdx)

verbose = 0; 

roiIdx = 1:numIdx;
ngIdx = [];
for ii = 1:numel(roiIdx)
    %disp(ii)
    encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        try
            encodingResult = load(encodingSaveName, 'RF_insilico','trained','trainParam');
           catch err
            if verbose
               disp(['MISSING ' encodingSaveName]);
            end
            ngIdx = [ngIdx roiIdx(ii)];
            continue;
        end
    else
        if verbose
            disp(['MISSING ' encodingSaveName]);
        end
        ngIdx = [ngIdx roiIdx(ii)];
        continue;
    end
end
 