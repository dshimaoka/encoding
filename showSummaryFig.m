function [fig_summary, figAxes] = showSummaryFig(summary)


mask = zeros(size(summary.thisROI));
mask(~isnan(summary.RF_Cx))=1;

fig_summary = figure;

figAxes(1)=subplot(251);
imagesc(summary.thisROI);
axis equal tight
colormap(gca,'gray');

figAxes(2)=subplot(252);
imagesc(summary.RF_Cx, 'alphadata',mask);
caxis(prctile(summary.RF_Cx(:),[10 90]));
title('Cx [deg]');
axis equal tight
gkrmap = customcolormap(linspace(0,1,3), ...
   [0 1 0; 0 0 0; 1 0 0]);
colormap(gca, gkrmap);
mcolorbar(gca,.5,'southoutside');

figAxes(3)=subplot(253);
imagesc(summary.RF_Cy, 'alphadata',mask)
Cymax=prctile(abs(summary.RF_Cy(:)),[99]);
caxis([-Cymax Cymax]);
title('Cy [deg]');
axis equal tight
gkrmap = customcolormap(linspace(0,1,3), ...
   [0 1 0; 0 0 0; 1 0 0]);
colormap(gca, gkrmap);
mcolorbar(gca,.5,'southoutside');

figAxes(4)=subplot(254);
imagesc(summary.vfs, 'alphadata',mask)
title('vfs');
caxis([-1 1]);
axis equal tight
bwrmap = customcolormap(linspace(0,1,11), ...
    {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
colormap(gca, bwrmap);
mcolorbar(gca,.5,'southoutside');

figAxes(5)=subplot(255);
imagesc(summary.RF_sigma, 'alphadata',mask)
title('sigma [deg]');
axis equal tight
mcolorbar(gca,.5,'southoutside');

figAxes(6)=subplot(256);
imagesc(summary.expVar, 'alphadata',mask);
title('explained variance [%]');
axis equal tight
colormap(gca,'gray');
mcolorbar(gca,.5,'southoutside');

figAxes(7)=subplot(257);
imagesc(summary.correlation, 'alphadata',mask);
title('correlation observed-mdl');
axis equal tight
colormap(gca,'gray');
mcolorbar(gca,.5,'southoutside');

figAxes(8)=subplot(258);
imagesc(log(summary.ridgeParam), 'alphadata',mask);
title('log(ridge param)');
axis equal tight
colormap(gca,'gray');
mcolorbar(gca,.5,'southoutside');

figAxes(9)=subplot(259);
imagesc(log(summary.bestSF), 'alphadata',mask);
%sfList = logspace(-1.1, 0.3, 5);
%caxis(log(prctile(sfList,[0 100])));
%caxis([-4 -1]);
title('log(spatial frequency) [cpd]');
axis equal tight
mcolorbar(gca,.5,'southoutside');

figAxes(10)=subplot(2,5,10);
imagesc(summary.bestOR, 'alphadata',mask);
colormap(gca, 'hsv');
caxis([0 180]);
title('orientation [deg]');
axis equal tight
mcolorbar(gca,.5,'southoutside');

linkaxes(figAxes);