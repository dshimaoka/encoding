function [coef] = fitByEccentricity(areaStats, statName)
%[mebins, coef] = fitByEccentricityBin(ebins, areaStats, statName)
nAreas = numel(areaStats.eccentricity);
coef = nan(2, nAreas);
for iarea = 1:nAreas
    try
        coef(:,iarea) = robustfit(areaStats.eccentricity{iarea}, areaStats.(statName){iarea});
    catch
    end
end
