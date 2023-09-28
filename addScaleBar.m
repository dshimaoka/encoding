function thisAx = addScaleBar(rescaleFac, thisAx, color, location)

if nargin < 4
    location = 'left bottom';
end
if nargin < 3
    color = 'w';
end

if nargin < 2 | isempty(thisAx)
    thisAx = gca;
end

marginPix = 5;
pixPermm = getPixPerMm(rescaleFac);

switch location
    case 'left bottom'
        line(thisAx, [marginPix marginPix+pixPermm], [marginPix marginPix],'color',color, 'linewidth',1);
end

