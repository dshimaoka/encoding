if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


ID = 3;
useGPU = 1;
rescaleFac = 0.10;
dsRate = 1;


%% path
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally
%dataPaths.encodingSavePrefix = ['Z:\Shared\Daisuke\recording\processed\2022\11\30\resize10_obs\encoding_2022_11_30_16_resize10'];
encodingSavePrefix = [dataPaths.encodingSavePrefix];

load(dataPaths.imageSaveName, 'imageData','X','Y');%SLOOOOW!!!
thisROI = imageData.meanImage; %153x120
roiIdx = 1:numel(X);
clear imageData;

load(dataPaths.imageSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];
clear stimInfo;

load( dataPaths.stimSaveName, 'gaborBankParamIdx');

%[Y,X,Z] = ind2sub(size(thisROI), roiIdx);

scrSz = size(thisROI);
RF_Cx = nan(numel(thisROI),1);
RF_Cy = nan(numel(thisROI),1);
RF_sigma = nan(numel(thisROI),1);
RF_mean =cell(numel(thisROI),1);% nan(scrSz(1), scrSz(2),18,32);
expVal = nan(numel(thisROI),1);
bestSF = nan(numel(thisROI),1);
bestOR = nan(numel(thisROI),1);
bestAmp = nan(numel(thisROI),1);
ridgeParam = nan(numel(thisROI),1);
ngIdx = [];
tic; %18h for CJ224 @officePC
for ii = 1:numel(roiIdx)
    disp(ii)
    encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        encodingResult = load(encodingSaveName, 'RF_insilico','trained','trainParam');
        RF_insilico = encodingResult.RF_insilico;
        trained = encodingResult.trained;
        trainParam = encodingResult.trainParam;
    else
        disp(['MISSING ' encodingSaveName]);
        ngIdx = [ngIdx roiIdx(ii)];
        continue;
    end
    
    expVal(ii) = trained.expval;
    ridgeParam(ii) = trained.ridgeParam_optimal;

    %% RF
    analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
    %RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);
    %showInSilicoRF(RF_insilico, analysisTwin);
            
    RF_Cx(ii) = RF_insilico.noiseRF.RF_Cx;
    RF_Cy(ii) = RF_insilico.noiseRF.RF_Cy;
    RF_sigma(ii) = RF_insilico.noiseRF.sigma;
    
    trange = [0 trainParam.lagFrames(end)/dsRate];
    tidx = find(RF_insilico.noiseRF.RFdelay>=trange(1) & RF_insilico.noiseRF.RFdelay<=trange(2));
    RF_mean{ii} = mean(RF_insilico.noiseRF.RF(:,:,tidx),3);  
    
    
    %% ORSF ... too heavy for officePC
    try
        RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, ...
            [2 trainParam.lagFrames(end)/dsRate], 3);
        bestSF(ii) = RF_insilico.ORSF.bestSF;
        bestOR(ii) = RF_insilico.ORSF.bestOR;
    catch err
        ngIdx = [ngIdx ii];
    end
    %bestAmp(ii) = amp;   
end
t = toc;


%% convert to 2D
RF_Cx2 = nan(size(thisROI));
RF_Cy2 = nan(size(thisROI));
RF_sigma2 = nan(size(thisROI));
bestSF2 = nan(size(thisROI));
bestOR2 = nan(size(thisROI));
expVal2 = nan(size(thisROI));
ridgeParam2 = nan(size(thisROI));
RF_mean2 = nan(size(thisROI,1),size(thisROI,2),RF_insilico.noiseRF.screenPix(1),RF_insilico.noiseRF.screenPix(2));
for ii = 1:numel(roiIdx)
    try
        RF_Cx2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_Cx(ii);
        RF_Cy2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_Cy(ii);
        expVal2(Y(roiIdx(ii)),X(roiIdx(ii))) = expVal(ii);
        ridgeParam2(Y(roiIdx(ii)),X(roiIdx(ii))) = ridgeParam(ii);
        RF_mean2(Y(roiIdx(ii)),X(roiIdx(ii)),:,:) = RF_mean{ii};
        bestSF2(Y(roiIdx(ii)),X(roiIdx(ii))) = bestSF(ii);
        bestOR2(Y(roiIdx(ii)),X(roiIdx(ii))) = bestOR(ii);
        RF_sigma2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_sigma(ii);
    catch err
        continue
    end
end

summary.RF_Cx = RF_Cx2;
summary.RF_Cy = RF_Cy2;
summary.RF_sigma = RF_sigma2;
summary.RF_mean = RF_mean2;
summary.ridgeParam = ridgeParam2;
summary.RF_mean = RF_mean2;
summary.bestSF = bestSF2;
summary.bestOR = bestOR2;
summary.expVar = expVal2;
summary.thisROI = thisROI;
summary.roiIdx = roiIdx;

save([dataPaths.encodingSavePrefix '_summary'],'summary');

%% summary figure
subplot(241);
imagesc(summary.thisROI);
axis equal tight
colormap(gca,'gray');

subplot(242);
imagesc(summary.RF_Cx);
caxis(prctile(summary.RF_Cx(:),[10 90]));
title('Cx [deg]');
axis equal tight
mcolorbar;

subplot(243);
imagesc(summary.RF_Cy)
caxis(prctile(summary.RF_Cy(:),[10 90]));
title('Cy [deg]');
axis equal tight
mcolorbar;

subplot(244);
imagesc(summary.RF_sigma)
title('sigma [deg]');
axis equal tight
mcolorbar;

subplot(245);
imagesc(summary.expVar);
title('explained variance [%]');
axis equal tight
colormap(gca,'gray');
mcolorbar;

subplot(246);
imagesc(log(summary.ridgeParam));
title('log(ridge param)');
axis equal tight
colormap(gca,'gray');
mcolorbar;

subplot(247);
imagesc(log(summary.bestSF));
%sfList = logspace(-1.1, 0.3, 5);
%caxis(log(prctile(sfList,[0 100])));
%caxis([-4 -1]);
title('log(spatial frequency) [cpd]');
axis equal tight
mcolorbar;

subplot(248);
imagesc(summary.bestOR);
colormap(gca, 'hsv');
caxis([0 180]);
title('orientation [deg]');
axis equal tight
mcolorbar;

screen2png([dataPaths.encodingSavePrefix '_summary']);

%% visual field sign
sfFac = 1;
prefMaps_xy(:,:,1)=summary.RF_Cx;
prefMaps_xy(:,:,2)=summary.RF_Cy;

%test = interp2(i,j,prefMaps_xy(:,:,1), );
vfs=getVFS(prefMaps_xy, sfFac);

ax(1)=subplot(131);
imagesc(summary.RF_Cx);
axis equal tight
mcolorbar;

ax(2)=subplot(132);
imagesc(summary.RF_Cy);
axis equal tight
mcolorbar;

ax(3)=subplot(133);
imagesc(vfs);
axis equal tight;
caxis([-1 1]);
% colormap(gca,RedWhiteBlue);
mcolorbar;
linkaxes(ax);
screen2png([dataPaths.encodingSavePrefix '_vfs']);


%% show mRFs

yy = 46+(1:5);
xx = 33+(1:5);
stimXaxis = RF_insilico.noiseRF.xaxis;
stimYaxis = RF_insilico.noiseRF.yaxis;
[f_panel, f_location] = showRFpanels(summary, xx, yy, stimXaxis, stimYaxis);
