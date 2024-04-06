subject = 'CJ231';
pen = 1;

imagingDir{1} = '\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\MarmosetData\2022\11\30\exp13';
imagingDir{2} = '\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\MarmosetData\2022\11\30\pen1';


%% load IOS data
imageData_c = buildImageDataOI(imagingDir{1},1,false);
baseImage = imageData_c.meanImage;

%% load image w probe
imageData_c = buildImageDataOI(imagingDir{2},1,false);
inputImage = imageData_c.meanImage;


%% align imag w probe to IOS data
[t_concord, input_points, base_points, fliplrCam1, fliplrCam2, ...
    flipudCam1, flipudCam2,cam1_registered, resultFig, scale_recovered, theta_recovered] = ...
    tools.rotate_flip_cams(inputImage, baseImage);

inputImage_registered = imtransform(inputImage,...
    t_concord,'XData',[1 size(baseImage,2)], 'YData',[1 size(baseImage,2)]);

%% load IOS resulting maps, rescale


%% save result
save(['ephys2Image_' subject '_pen' num2str(pen) '.mat'],'imagingDir','t_concord','inputImage',...
    'baseImage','inputImage_registered', 'input_points', 'base_points');

