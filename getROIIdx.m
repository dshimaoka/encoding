function [theseIdx, X,Y] = getROIIdx(nanMask)
%[theseIdx, X,Y] = getROIIdx(nanMask)
theseIdx = find(~isnan(nanMask));
[Y,X,Z] = ind2sub(size(nanMask), theseIdx);
