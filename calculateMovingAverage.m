function movingAvgY = calculateMovingAverage(x, y, windowSize)
    [~, sortIdx] = sort(x); % Sort x in ascending order
    sortedX = x(sortIdx);
    sortedY = y(sortIdx);
    
    numPoints = numel(sortedX);
    movingAvgY = zeros(size(sortedY));
    
    for i = 1:numPoints
        lowerBound = max(1, i - windowSize);
        upperBound = min(numPoints, i + windowSize);
        movingAvgY(i) = mean(sortedY(lowerBound:upperBound));
    end
end
