ID=2;
gparamIdx = 2;
%screenPix = [144 256];%/4; %Y-X %gaborparams is identical irrespective of the denominator
stimXrange = 161:238;
stimYrange = 29:108;
screenPix = [numel(stimYrange) numel(stimXrange)];
rescaleFac = 0.10;
thisIdx = 1086;%297;
roiSuffix = '';
stimSuffix = '_part';
regressSuffix = '_nxv';
[fvY, fvX] = getFoveaPix(ID, rescaleFac);


expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac,roiSuffix, stimSuffix);
encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];
%dataPaths.encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];

encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(thisIdx) '.mat'];
load(encodingSaveName,'trained','trainParam','RF_insilico');
load([encodingSavePrefix '_summary.mat'],'summary','summary_adj');

load(dataPaths.stimSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];

[gaborparams_real, gaborparams, S] = getFilterParams(gparamIdx, screenPix, stimSz);
[sumCoefs,allIdx] = sort(sum(abs(trained.rre)), 'descend');
showFiltIdx = allIdx(1:9);
showFiltParams(gaborparams, S, showFiltIdx);

%%
figure
stimXaxis = RF_insilico.noiseRF.xaxis - summary.RF_Cx(fvY,fvX);
stimYaxis = -(RF_insilico.noiseRF.yaxis - summary.RF_Cy(fvY,fvX));

filtContours = squeeze(S(:,:,round(size(S,3)/2),:));
for ii = 1:numel(showFiltIdx)
    subplot_tight(3,3,ii,0.01);
    thisImage = filtContours(:,:,showFiltIdx(ii));
    imagesc(stimXaxis, stimYaxis, thisImage);
    vline(0,gca,'-'); hline;
    caxis([-max(abs(thisImage(:))) max(abs(thisImage(:)))]);
    axis equal off;
end
colormap(1-gray);
axis equal tight on;
savePaperFigure(gcf,'kernel_panels');

%%
figure;
histogram(sumCoefs);
set(gca,'tickdir','out');
xlabel('sum(|Kernel coefficient|)');
ylabel('# Kernels');
savePaperFigure(gcf,'kernel_hist');

% figure;
% paramNames = {'pos_x' 'pos_y' 'direction' 's_freq' 't_freq' 's_size' 't_size' 'phasevalue'};
% for ii = 1:4
%     ax(ii)=subplot(4,1,ii);
%     histogram(gaborparams_real(ii,allIdx(1:100)),10);
%     ylabel(paramNames{ii});
%     grid on;
%     axis tight padded
% end