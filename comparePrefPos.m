ID = 3;
rescaleFac = 0.1;

%% encoding model
%result of git/encoding/summaryAcrossPix.m
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac);
encodingSavePrefix = [dataPaths.encodingSavePrefix];% '_nxv'];

load([encodingSavePrefix '_summary'],'summary');
prefMap_mdl = summary.RF_Cy;
prefMap_mdl_adj = -prefMap_mdl;

%% traditional method
%result of CJ229_xypos_figures.m
load('\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\2022ANSposter_analysis\cj229_ypos_retinotopy.mat',...
    'prefMap','stimValues');
prefMap_resize = imresize(prefMap, size(summary.thisROI));

%convert from stimulus number to visual field (assume the inter-stimulus
%interval is constant)
prefMap_adj = (stimValues(end) - stimValues(1))/(numel(stimValues)-1)*(prefMap_resize - 1) + stimValues(1);


theseROI = (summary.correlation > 0.5);
theseIdx = find(theseROI);

ax(1)=subplot(221);
imagesc(prefMap_adj, 'alphadata', theseROI);
axis equal tight;
colorbar

ax(2)=subplot(222);
imagesc(prefMap_mdl_adj, 'alphadata', theseROI);
axis equal tight;
colorbar
linkcaxes(ax(1:2));

ax(3) = subplot(223);
plot(prefMap_adj(theseIdx), prefMap_mdl_adj(theseIdx),'.');
squareplot;
marginplot;
xlabel('altidude by flash stim [deg]');
ylabel('altidude by model [deg]');

savePaperFigure(gcf, ['comparePrefPos_' expInfo.subject]);

