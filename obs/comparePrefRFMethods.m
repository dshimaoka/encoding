subplot(2,6,1);
imagesc(summary.RF_Cx);caxis([-12 5])
axis equal tight;
title('original');
ylabel('Cx [deg]');

subplot(2,6,2);
imagesc(RF_Cx3_nolim);caxis([-12 5])
axis equal tight;
title('subtract gnd avg');

subplot(2,6,3);
imagesc(RF_Cx3_noFilt);caxis([-12 5])
axis equal tight;
title('no smooth2DGauss');

subplot(2,6,4);
imagesc(RF_Cx3_swin);caxis([-12 5])
axis equal tight;
title('fit w small window around the peak');

subplot(2,6,5);
imagesc(RF_Cx3_p0);caxis([-12 5])
axis equal tight;
title('use previous result as initial parameter');

subplot(2,6,6);
imagesc(RF_Cx3_2steps);caxis([-12 5])
axis equal tight;
title('smooth2DGauss coarse then fine');
mcolorbar;

subplot(2,6,7);
imagesc(summary.RF_Cy);caxis([-5 5])
axis equal tight;
title('original');
ylabel('Cy [deg]');

subplot(2,6,2+6);
imagesc(RF_Cy3_nolim);caxis([-5 5])
axis equal tight;
title('subtract gnd avg');

subplot(2,6,3+6);
imagesc(RF_Cy3_noFilt);caxis([-5 5])
axis equal tight;
title('no smooth2DGauss');

subplot(2,6,4+6);
imagesc(RF_Cy3_swin);caxis([-5 5])
axis equal tight;
title('fit w small window around the peak');

subplot(2,6,5+6);
imagesc(RF_Cy3_p0);caxis([-5 5])
axis equal tight;
title('use previous result as initial parameter');

subplot(2,6,6+6);
imagesc(RF_Cy3_2steps);caxis([-5 5])
axis equal tight;
title('smooth2DGauss coarse then fine');
mcolorbar;