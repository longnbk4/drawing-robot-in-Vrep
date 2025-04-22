clearvars;
sim = remApi('remoteApi');
sim.simxFinish(-1);
clientID = sim.simxStart('127.0.0.1',19999,true,true,5000,5);

if (clientID > -1)
    disp('Connected to remote API server');
    [~, dum] = sim.simxGetObjectHandle(clientID, 'IRB140_target', sim.simx_opmode_blocking);

    % Đọc và chuyển đổi hình ảnh sang định dạng HSV
    RGB = imread('alec.jpg');
    I = rgb2hsv(RGB);

    % Định nghĩa ngưỡng cho các kênh HSV dựa trên thiết lập biểu đồ
    channel1Min = 0.022;
    channel1Max = 0.008;
    channel2Min = 0.000;
    channel2Max = 1.000;
    channel3Min = 0.000;
    channel3Max = 0.657;

    % Tạo mặt nạ nhị phân dựa trên các ngưỡng đã chọn
    sliderBW = ((I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max)) & ...
               (I(:,:,2) >= channel2Min) & (I(:,:,2) <= channel2Max) & ...
               (I(:,:,3) >= channel3Min) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Điều chỉnh hình ảnh để phù hợp với cách vẽ của robot
    BW = flip(BW, 1);
    BW = imrotate(BW, -90);

    % Hiển thị ảnh nhị phân
    figure(1);
    imshow(BW);

    % Tạo ảnh nhị phân đảo ngược để trích xuất biên
    ibw_white = 1 - BW;

    % Trích xuất các biên
    [B, L] = bwboundaries(ibw_white, 'noholes');

    % Hiển thị các biên trích xuất
    figure(2);
    imshow(ibw_white);
    hold on;
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
    end

    % Tạo quỹ đạo di chuyển cho cánh tay robot
    x = [];
    y = [];
    z = [];
    count = 0;

    for k = 1:length(B)
        boundary = B{k};
        for i = 1:length(boundary(:,2))
            count = count + 1;
            x(count) = boundary(i,2);
            y(count) = boundary(i,1);
            z(count) = 0;
        end
        count = count - 1;
        z(count) = 30;
    end

    % Hệ số tỷ lệ để điều chỉnh kích thước vẽ
    scaleFactor = 0.0005; % Tăng hệ số này để vẽ hình lớn hơn

    % Di chuyển cánh tay robot theo quỹ đạo
    for m = 1:length(x)
        [returnCode] = sim.simxSetObjectPosition(clientID, dum, -1, ...
            [-0.22 + (x(m) * scaleFactor), -0.175 + (y(m) * scaleFactor), (z(m) * 0.004) + 0.515], sim.simx_opmode_blocking);
    end

    % Di chuyển cánh tay robot ra khỏi khu vực vẽ
    [returnCode] = sim.simxSetObjectPosition(clientID, dum, -1, [-0.4, -0.45, 0.625], sim.simx_opmode_blocking);

    % Kết thúc kết nối
    sim.simxFinish(clientID);
end

% Xóa đối tượng sim để giải phóng bộ nhớ
sim.delete();
