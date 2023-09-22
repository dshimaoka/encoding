ID = 2;
rescaleFac = 0.1;
roiSuffix = '';
stimSuffix = '_part';
regressSuffix = '_nxv';
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);

gparamIdx = 2;

load( dataPaths.stimSaveName, 'stimInfo');
screenPix = stimInfo.screenPix;
screenDeg = [stimInfo.height stimInfo.width];

S = zeros(screenPix(1), screenPix(2), 20); %X-Y-T???

gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
gparams.show_or_preprocess = 0; %necessary to obtain gaborparams
[S, gparams] = preprocWavelets_grid(S, gparams);%filter assumes no time delay
gaborparams = gparams.gaborparams;
pix2deg = mean(screenDeg./screenPix); %[deg/pix]
gaborparams_r = gaborparams;
[gaborparams_r(1,:),gaborparams_r(2,:)] = relpos2deg(gaborparams(1,:), ...
    gaborparams(2,:), screenDeg(2),screenDeg(1));

gaborparams = mean(screenDeg) * gaborparams(6,:); %s_size [deg]

sigmaRange = [min(gaborparams) max(gaborparams)];