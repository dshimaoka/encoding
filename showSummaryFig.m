function [fig_summary, figAxes] = showSummaryFig(summary, flipLR)
%[fig_summary, figAxes] = showSummaryFig(summary)
%shows figure of a result of all the pixels analyzed in summaryAcrossPix.m

if nargin < 2
    flipLR = false;
end

fig_summary = figure;

figAxes(1)=subplot(261);
if flipLR
    imagesc(fliplr(summary.thisROI));
else
    imagesc(summary.thisROI);
end
axis equal tight off
colormap(gca,'gray');

figAxes(2)=subplot(262);
if flipLR
    imagesc(fliplr(summary.RF_Cx), 'alphadata', fliplr(summary.mask));
else
    imagesc(summary.RF_Cx, 'alphadata',summary.mask);
end
caxis(prctile(summary.RF_Cx(:),[10 90]));
title('Cx [deg]');
axis equal tight off
% gkrmap = customcolormap(linspace(0,1,3), ...
%    [0 1 0; 0 0 0; 1 0 0]);
% colormap(gca, gkrmap);
mcolorbar(gca,.5,'southoutside');

figAxes(3)=subplot(263);
if flipLR
    imagesc(fliplr(summary.RF_Cy), 'alphadata', fliplr(summary.mask))
else
    imagesc(summary.RF_Cy, 'alphadata',summary.mask)
end
Cymax=prctile(abs(summary.RF_Cy(:)),[99]);
caxis([-Cymax Cymax]);
title('Cy [deg]');
axis equal tight off
rkgmap = customcolormap(linspace(0,1,3), ...
   [1 0 0; 0 0 0; 0 1 0]);
colormap(gca, rkgmap);
mcolorbar(gca,.5,'southoutside');

figAxes(4)=subplot(264);
if flipLR
    imagesc(fliplr(summary.vfs), 'alphadata', fliplr(summary.mask));
else
    imagesc(summary.vfs, 'alphadata',summary.mask)
end
title('vfs');
caxis([-1 1]);
axis equal tight off
bwrmap = customcolormap(linspace(0,1,11), ...
    {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
colormap(gca, flipud(bwrmap));
mcolorbar(gca,.5,'southoutside');

figAxes(5)=subplot(265);
if flipLR
    imagesc(fliplr(summary.RF_sigma), 'alphadata',fliplr(summary.mask))
else
    imagesc(summary.RF_sigma, 'alphadata',summary.mask)
end
title('sigma [deg]');
axis equal tight off
mcolorbar(gca,.5,'southoutside');

figAxes(6)=subplot(266);
if flipLR
    imagesc(fliplr(summary.expVar), 'alphadata', fliplr(summary.mask));
else
    imagesc(summary.expVar, 'alphadata',summary.mask);
end
title('explained variance [%]');
axis equal tight off
colormap(gca,'gray');
mcolorbar(gca,.5,'southoutside');

figAxes(7)=subplot(267);
if flipLR
    imagesc(fliplr(summary.correlation), 'alphadata', fliplr(summary.mask));
else
    imagesc(summary.correlation, 'alphadata',summary.mask);
end
title('correlation observed-mdl');
axis equal tight off
colormap(gca,'gray');
mcolorbar(gca,.5,'southoutside');

figAxes(8)=subplot(268);
if flipLR
    imagesc(fliplr(log(summary.ridgeParam)), 'alphadata', fliplr(summary.mask));
else
    imagesc(log(summary.ridgeParam), 'alphadata',summary.mask);
end
title('log(ridge param)');
axis equal tight off
colormap(gca,'gray');
mcolorbar(gca,.5,'southoutside');

figAxes(9)=subplot(2,6,9);
if flipLR
    imagesc(fliplr(log(summary.bestSF)), 'alphadata', fliplr(summary.mask));
else
    imagesc(log(summary.bestSF), 'alphadata',summary.mask);
end
caxis(prctile(log(summary.bestSF(:)),[1 99]));
title('log(spatial frequency) [cpd]');
axis equal tight off
mcolorbar(gca,.5,'southoutside');

figAxes(10)=subplot(2,6,10);
if flipLR
    imagesc(fliplr(summary.bestOR), 'alphadata', fliplr(summary.mask));
else
    imagesc(summary.bestOR, 'alphadata',summary.mask);
end
colormap(gca, 'hsv');
caxis([0 180]);
title('orientation [deg]');
axis equal tight off
mcolorbar(gca,.5,'southoutside');

figAxes(11)=subplot(2,6,11);
if flipLR
    imagesc(fliplr(log(summary.bestSFF)), 'alphadata', fliplr(summary.mask));
else
    imagesc(log(summary.bestSFF), 'alphadata',summary.mask);
end
colormap(gca, 'parula');
title('log(SF) by DIRSFTF [cpd]');
axis equal tight off
mcolorbar(gca,.5,'southoutside');

figAxes(12)=subplot(2,6,12);
if flipLR
    imagesc(fliplr(log(summary.bestTF)), 'alphadata', fliplr(summary.mask));
else
    imagesc(log(summary.bestTF), 'alphadata',summary.mask);
end
colormap(gca, 'parula');
title('log(TF) by DIRSFTF [Hz]');
axis equal tight off
mcolorbar(gca,.5,'southoutside');

linkaxes(figAxes);