clearvars;
close all;

% Constants
serverIP = '127.0.0.1';
serverPort = 19999;
timeout = 5000;
retries = 5;

% Connect to the remote API server
sim=remApi('remoteApi');
sim.simxFinish(-1);
clientID=sim.simxStart('127.0.0.1',19999,true,true,5000,5);
if (clientID>-1)
       disp('Connected to remote API server');
    
    % Get object handle
    [returnCode, targetHandle] = simxGetObjectHandle(clientID, 'IRB140_target', simx_opmode_blocking);
    
    % Read the image and convert it to grayscale
    RGB = imread('jerry.jpg');
    I = rgb2gray(RGB);
    
    % Threshold the image to create a binary image
    BW = I > 128; % You can adjust this threshold value based on your image
    
    % Adjust the binary image
    BW = flip(BW, 1);
    BW = imrotate(BW, -90);
    
    % Display the binary image
    figure;
    imshow(BW);
    
    % Find boundaries
    [B, L] = bwboundaries(BW, 'noholes');
    
    % Display boundaries
    figure;
    imshow(BW);
    hold on;
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:, 2), boundary(:, 1), 'g', 'LineWidth', 2);
    end
    hold off;
    
    % Prepare the motion trajectory
    x = [];
    y = [];
    z = [];
    count = 0;
    
    for k = 1:length(B)
        boundary = B{k};
        for i = 1:length(boundary)
            count = count + 1;
            x(count) = boundary(i, 2);
            y(count) = boundary(i, 1);
            z(count) = 0;
        end
        count = count - 1;
        z(count) = 30;
    end
    
    % Move the robot arm along the trajectory
    for m = 1:length(x)
        simxSetObjectPosition(clientID, targetHandle, -1, [-0.22 + (x(m) * 0.0003), -0.175 + (y(m) * 0.0003), (z(m) * 0.004) + 0.515], simx_opmode_blocking);
    end
    
    % Move the robot arm away from the drawing area
    simxSetObjectPosition(clientID, targetHandle, -1, [-0.4, -0.45, 0.625], simx_opmode_blocking);
    
    % Close the connection to the remote API server
    simxFinish(clientID);
else
    disp('Failed connecting to remote API server');
end

% Cleanup
simxFinish(-1);
clear sim;
