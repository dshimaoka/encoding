function RF_insilico = analyzeInSilicoRF(RF_insilico, stimInfo)
%RF_insilico = analyzeInSilicoRF(RF_insilico, stimInfo)

RF_is = RF_insilico.RF;

xpix = 1:RF_insilico.screenPix(2);
xaxis = stimInfo.width*(xpix - mean(xpix))./numel(xpix);
ypix = 1:RF_insilico.screenPix(1);
yaxis = stimInfo.height*(ypix - mean(ypix))./numel(ypix);

%% fit RF position and size
tic;
mRF = squeeze(mean(RF_is,3));
%RF_tmp = mat2cell(double(mRF), RF_insilico.screenPix(1), RF_insilico.screenPix(2));

%USELESS:
%[RF_contour, Cx_tmp, Cy_tmp, ok_tmp] = getRFContours(RF_tmp);
% < Index in position 3 exceeds array bounds. @ ii=10, jj=1
%computation time depends on screenPix_is
% RF_Cx = cell2mat(Cx_tmp);
% RF_Cy = cell2mat(Cy_tmp);
% RF_ok = cell2mat(ok_tmp);

RF_smooth = smooth2DGauss(mRF - mean(mRF(:)));
RF_smooth(RF_smooth<0) = 0;
p = fitGauss2(xaxis,yaxis,RF_smooth);%need smoothing before this


RF_insilico.RF_Cx = p(1);
RF_insilico.RF_Cy = p(2);
RF_insilico.RF_ok = 1; %FIX ME

