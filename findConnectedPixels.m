function [connectedPixels, connectedMatrix] = findConnectedPixels(matrix)
    % Display the matrix as an image
    imagesc(matrix + 2); % Shifting the values to {1, 2, 3} for better visualization
    colormap('jet');
    colorbar;
    title('Matrix Image');
    
      
    disp('Click on pixels (Press Enter when done)');
    [x, y] = getpts;

    % Find connected pixels with the same value
    clickedValue = [];
    for i = 1:numel(x)
        clickedValue(i) = matrix(round(y(i)), round(x(i)));
    end
    [m, n] = size(matrix);
    visited = false(m, n); % Track visited pixels
    connectedPixels = [];
    
    % Recursive function to find connected pixels
    for i = 1:numel(x) 
        findConnectedPixelsRecursive(round(y(i)), round(x(i)), clickedValue(i));
    end
    
    % Recursive function to find connected pixels
    function findConnectedPixelsRecursive(row, col, clickedValue)
        if row < 1 || row > m || col < 1 || col > n % Check for boundary conditions
            return;
        end
        
        if visited(row, col) % Check if the pixel is already visited
            return;
        end
        
        visited(row, col) = true; % Mark the pixel as visited
        
        % Check if the pixel has the same value as the clicked pixel
        if matrix(row, col) == clickedValue
            connectedPixels = [connectedPixels; [row, col]]; % Add the connected pixel coordinates
            % Recursively find connected pixels in the four neighboring directions
            findConnectedPixelsRecursive(row-1, col, clickedValue); % Up
            findConnectedPixelsRecursive(row+1, col, clickedValue); % Down
            findConnectedPixelsRecursive(row, col-1, clickedValue); % Left
            findConnectedPixelsRecursive(row, col+1, clickedValue); % Right
        end
    end

    connectedMatrix = sub2mat(connectedPixels(:,2), ...
        connectedPixels(:,1), size(matrix));

end

function matrix = sub2mat(x,y,matrixSize)
matrix = zeros(matrixSize);
for idx = 1:numel(x)
    matrix(y(idx),x(idx)) = 1;
end
end
