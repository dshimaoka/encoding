function RF_insilico = analyzeInSilicoRF(RF_insilico, peakPolarity, trange, xlim, ylim)
%RF_insilico = analyzeInSilicoRF(RF_insilico, trange)
if nargin < 2
    peakPolarity = -1;
end

if nargin < 3
    trange = [-inf inf];
end

if nargin < 4
    xlim = [];
end

if nargin < 5
    ylim = [];
end

RF = RF_insilico.noiseRF.RF;
xaxis = RF_insilico.noiseRF.xaxis;
yaxis = RF_insilico.noiseRF.yaxis;

%% fit RF position and size
tic;
tidx = find(RF_insilico.noiseRF.RFdelay>=trange(1) & RF_insilico.noiseRF.RFdelay<=trange(2));
mRF = squeeze(mean(RF(:,:,tidx),3));
%RF_tmp = mat2cell(double(mRF), RF_insilico.screenPix(1), RF_insilico.screenPix(2));

%USELESS:
%[RF_contour, Cx_tmp, Cy_tmp, ok_tmp] = getRFContours(RF_tmp);
% < Index in position 3 exceeds array bounds. @ ii=10, jj=1
%computation time depends on screenPix_is
% RF_Cx = cell2mat(Cx_tmp);
% RF_Cy = cell2mat(Cy_tmp);
% RF_ok = cell2mat(ok_tmp);

RF_smooth = smooth2DGauss(mRF - mean(mRF(:)));

RF_smooth = peakPolarity * RF_smooth;
RF_smooth(RF_smooth<0) = 0;
  

if ~isempty(xlim)
    xidx = find(xaxis>=xlim(1) & xaxis <= xlim(2));
else
    xidx = 1:numel(xaxis);
end
if ~isempty(ylim)
    yidx = find(yaxis>=ylim(1) & yaxis <= ylim(2));
else
    yidx = 1:numel(yaxis);
end  
p = fitGauss2(xaxis(xidx),yaxis(yidx),RF_smooth(yidx,xidx));%need smoothing before this

%second fitting w limted pixels
if isfield(RF_insilico.noiseRF, 'maxRFsize')
    maxRFsize = RF_insilico.noiseRF.maxRFsize;
    winIdxLen = floor(maxRFsize/mean(diff(xaxis))/2);
    [~,xcent] = min(abs(p(1)-xaxis));
    [~,ycent] = min(abs(p(2)-yaxis));
    winXidx = max(xcent-winIdxLen,1):min(xcent+winIdxLen,numel(xaxis));
    winYidx = max(ycent-winIdxLen,1):min(ycent+winIdxLen,numel(yaxis));
    
    p = fitGauss2(xaxis(winXidx),yaxis(winYidx),RF_smooth(winYidx,winXidx));%need smoothing before this
end

RF_insilico.noiseRF.RF_Cx = p(1);
RF_insilico.noiseRF.RF_Cy = p(2);
RF_insilico.noiseRF.sigma = (p(3)+p(4))/2;
if (min(xaxis) < p(1)) && (max(xaxis) > p(1)) && (min(yaxis) < p(2)) && (max(yaxis) > p(2))
    RF_insilico.noiseRF.RF_ok = 1;
else
    RF_insilico.noiseRF.RF_ok = 0;
end
