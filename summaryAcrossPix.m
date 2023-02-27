expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

rescaleFac = 0.25;
roiIdx = 7601:7719+430;


%% path
dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally


load(dataPaths.imageSaveName, 'imageData');%SLOOOOW!!!
thisROI = imageData.meanImage; %153x120
clear imageData;

%% create mask
% imagesc(thisROI);colormap(gray);axis equal tight;
% roiAhand = images.roi.AssistedFreehand;
% draw(roiAhand);
% roi = createMask(roiAhand);
% nanMask = nan(size(roi));
% nanMask(roi) = 1;
% save(dataPaths.imageSaveName, 'nanMask','-append');


[Y,X,Z] = ind2sub(size(thisROI), roiIdx);

RF_Cx = nan(size(thisROI));
RF_Cy = nan(size(thisROI));
RF_sigma = nan(size(thisROI));
expVal = nan(size(thisROI));
bestSF = nan(size(thisROI));
bestOR = nan(size(thisROI));
bestAmp = nan(size(thisROI));
ridgeParam = nan(size(thisROI));
for ii = 1:numel(roiIdx)
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        load(encodingSaveName, 'RF_insilico','trained','trainParam');
    else
        disp(['MISSING ' encodingSaveName]);
    end
    
    dsRate = 1;
    analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
    RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);

    RF_Cx(Y(ii),X(ii)) = RF_insilico.noiseRF.RF_Cx;
    RF_Cy(Y(ii),X(ii)) = RF_insilico.noiseRF.RF_Cy;
    RF_sigma(Y(ii),X(ii)) = RF_insilico.noiseRF.sigma;
    
    expVal(Y(ii),X(ii)) = trained.expval;
    
    [amp, idx] = min(RF_insilico.ORSF.resp(:));
    [sfidx, oridx, tidx] = ind2sub(size(RF_insilico.ORSF.resp), idx);
    bestSF(Y(ii),X(ii)) = RF_insilico.ORSF.sfList(sfidx);
    bestOR(Y(ii),X(ii)) = 180/pi*RF_insilico.ORSF.oriList(oridx);
    bestAmp(Y(ii),X(ii)) = amp;
    
    ridgeParam(Y(ii),X(ii)) = trained.ridgeParam_optimal;
end

subplot(241);
imagesc(thisROI);
axis equal tight
colormap(gca,'gray');

subplot(242);
imagesc(RF_Cx);
title('Cx [deg]');
axis equal tight
mcolorbar;

subplot(243);
imagesc(RF_Cy)
title('Cy [deg]');
axis equal tight
mcolorbar;

subplot(244);
imagesc(RF_sigma)
title('sigma [deg]');
axis equal tight
mcolorbar;

subplot(245);
imagesc(expVal);
title('explained variance [%]');
axis equal tight
colormap(gca,'gray');

subplot(246);
imagesc(bestSF);
title('spatial frequency');
axis equal tight
mcolorbar;

subplot(247);
imagesc(bestOR);
colormap(gca, 'hsv');
caxis([0 180]);
title('orientation [deg]');
axis equal tight
mcolorbar;



