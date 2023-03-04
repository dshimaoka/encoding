expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

rescaleFac = 0.10;
roiIdx = 1:2070;
dsRate = 1;


%% path
dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally


load(dataPaths.imageSaveName, 'imageData','X','Y');%SLOOOOW!!!
thisROI = imageData.meanImage; %153x120
clear imageData;

load(dataPaths.imageSaveName,'stimInfo')

load( dataPaths.stimSaveName, 'gaborBankParamIdx');

%[Y,X,Z] = ind2sub(size(thisROI), roiIdx);

scrSz = size(thisROI);
RF_Cx = nan(size(thisROI));
RF_Cy = nan(size(thisROI));
RF_sigma = nan(size(thisROI));
RF_mean = nan(scrSz(1), scrSz(2),18,32);
expVal = nan(size(thisROI));
bestSF = nan(size(thisROI));
bestOR = nan(size(thisROI));
bestAmp = nan(size(thisROI));
ridgeParam = nan(size(thisROI));
ngidx = [];
for ii = 1:numel(roiIdx)
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        load(encodingSaveName, 'RF_insilico','trained','trainParam');
    else
        disp(['MISSING ' encodingSaveName]);
        ngidx = [ngidx roiIdx(ii)];
        continue;
    end
    expVal(Y(roiIdx(ii)),X(roiIdx(ii))) = trained.expval;
    ridgeParam(Y(roiIdx(ii)),X(roiIdx(ii))) = trained.ridgeParam_optimal;

    %% RF
    analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
    %RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);

    RF_Cx(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_insilico.noiseRF.RF_Cx;
    RF_Cy(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_insilico.noiseRF.RF_Cy;
    RF_sigma(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_insilico.noiseRF.sigma;
    
    trange = [0 trainParam.lagFrames(end)/dsRate];
    tidx = find(RF_insilico.noiseRF.RFdelay>=trange(1) & RF_insilico.noiseRF.RFdelay<=trange(2));
    RF_mean(Y(roiIdx(ii)),X(roiIdx(ii)),:,:) = mean(RF_insilico.noiseRF.RF(:,:,tidx),3);
    
    
    
    %% ORSF
%     RF_insilico.ORSF.screenPix = [144 256]/2;
%     RF_insilico.ORSF.nRepeats = 15;
%     nORs=10;
%     oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
%     RF_insilico.ORSF.oriList = oriList(1:end-1);
%     RF_insilico.ORSF.sfList = logspace(-1.1, 0.3, 5); %[cycles/deg]
%     RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, ...
%         RF_insilico, [stimInfo.height stimInfo.width]);
%     %showInSilicoORSF(RF_insilico);
%     RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, [0 RF_insilico.ORSF.dwell/RF_insilico.ORSF.Fs_visStim]);
% 
%     bestSF(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_insilico.ORSF.bestSF;
%     bestOR(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_insilico.ORSF.bestOR;
    %bestAmp(Y(roiIdx(ii)),X(roiIdx(ii))) = amp;
    
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

%%
xx = 21:30;
yy = (21:40)-20;
figure;
all = RF_mean(yy, xx,:,:);
for ix = 1:numel(xx)
    for iy = 1:numel(yy)
        subplot_tight(numel(yy), numel(xx), ix + numel(xx)*(iy-1), 0.01);
        imagesc(squeeze(RF_mean(yy(iy), xx(ix),:,:))); axis off
        %title(['x: ' num2str(xx(ix)) ', y: ' num2str(yy(iy))])
        %caxis(prctile(all(:),[1 99])); %better not to impose same color range
    end
end

% rectangle('position', [min(xx) min(yy) numel(xx) numel(yy)]);
