
%Read picture and store into I
%I = imread('chessBoard.jpg');

% alternatively use the Intel D435 for acquisition
try
    % get the RGB image
    MyCameras = webcamlist;
    MyIntelRGB = MyCameras(2);
    MyIntelRGBCamHandle = webcam(MyIntelRGB{1});
    MyIntelRGBCamHandle.Resolution = '1920x1080';
    % preview(MyIntelRGBCamHandle)
    for i = 1:5
        I = snapshot(MyIntelRGBCamHandle);
    end
    clear('MyIntelRGBCamHandle');
    figure(1);
    imshow(I);
    
    % Get a depth map
    pipe = realsense.pipeline();
    colorizer = realsense.colorizer();
    % try to connect to the depth camera
    profile = pipe.start();
    % Get streaming device's name
    dev = profile.get_device();
    name = dev.get_info(realsense.camera_info.name);
    % Get frames. We discard the first couple to allow
    % the camera time to settle
    for i = 1:5
        fs = pipe.wait_for_frames();
    end
    % Stop streaming
    pipe.stop();
    
    % Select depth frame
    depth = fs.get_depth_frame();
    % Colorize depth frame
    color = colorizer.colorize(depth);
    % Get actual data and convert into a format imshow can use
    % (Color data arrives as [R, G, B, R, G, B, ...] vector)
    data = color.get_data();
    DepthImg = permute(reshape(data',[3,color.get_width(),color.get_height()]),[3 2 1]);
    
    % Display image
    figure(2)
    imshow(DepthImg);
    title(sprintf("Colorized depth frame from %s", name));
    
catch
    
end


%Detect the checkered points, stores dimension of board and the position
%of the points
[imagePoints,boardSize,pairsUsed] = detectCheckerboardPoints(I, 'MinCornerMetric', 0.55);
% 
figure(3);
imshow(I);
hold on;
plot(imagePoints(:,1,1), imagePoints(:,2,1),'ro');
hold off;
% 
cfS = 100;

fixedPoints = [cfS cfS; 7*cfS cfS; 7*cfS 7*cfS; cfS 7*cfS];
movingPoints = [imagePoints(7,:); imagePoints(1,:); imagePoints(43,:); imagePoints(49,:)];   

% sort the moving points by size to prevent ambigious rotations
a = zeros(4,1);
for i = 1:4
    a(i) = movingPoints(i,1) * movingPoints(i,2);
end
[a, indexI] = sort(a); %this crap causes it all
movingPoints  = [ movingPoints(indexI(1),:); movingPoints(indexI(2),:); movingPoints(indexI(4),:); movingPoints(indexI(3),:) ]; 

%tform = fitgeotrans(movingPoints, fixedPoints, 'projective');

%save('tform.mat', 'tform');
load('tform');

tImage = imwarp(I, tform, 'OutputView', imref2d(size(I)));
tImage = imcrop(tImage, [0 0 801 801]);
%     0.0000    0.0013   -0.0000
%    -0.0013    0.0001    0.0000
%     1.0686   -0.9156    0.0010
figure(4);
imshow(tImage);

disp("Set up the board pieces please ! (and press a key)");



% ===========================================================================================
% take a second image before the move
try
    % get the RGB image
    MyCameras = webcamlist;
    MyIntelRGB = MyCameras(2);
    MyIntelRGBCamHandle = webcam(MyIntelRGB{1});
    MyIntelRGBCamHandle.Resolution = '1920x1080';
    for i = 1:5
        ImgBeforeMove = snapshot(MyIntelRGBCamHandle);
    end
    clear('MyIntelRGBCamHandle');
catch
end
% apply the old transformation to the image
tImgBeforeMove = imwarp(ImgBeforeMove, tform, 'OutputView', imref2d(size(ImgBeforeMove)));
tImgBeforeMove = imcrop(tImgBeforeMove, [0 0 801 801]);
tImgBeforeMoveGRAY = rgb2gray(tImgBeforeMove);
figure(4);
imshow(tImgBeforeMoveGRAY);


% who's move is this, white starts
NumOfMoves = 0;     % even = white, odd = black

% initialize the board positions:
% 1 = pawn, 2 = turret, 3 = knight, 4 = bishop, 5 = queen , 6 = king
OccupiedOnBoardBlack = zeros(8,8);
OccupiedOnBoardBlack(:,1) = [2 3 4 6 5 4 3 2];
OccupiedOnBoardBlack(:,2) = 1;
OccupiedOnBoardWhite = zeros(8,8);
OccupiedOnBoardWhite(:,8) = [2 3 4 6 5 4 3 2];
OccupiedOnBoardWhite(:,7) = 1;


while (1 == 1)
    
    disp("Make a move");
    % w = waitforbuttonpress;
    
    a = 5;
    
    % MOVE a chesspiece
    % ===========================================================================================
    % take a third image after the move
    try
        % get the RGB image
        MyCameras = webcamlist;
        MyIntelRGB = MyCameras(2);
        MyIntelRGBCamHandle = webcam(MyIntelRGB{1});
        MyIntelRGBCamHandle.Resolution = '1920x1080';
        for i = 1:5
            ImgAfterMove = snapshot(MyIntelRGBCamHandle);
        end
        clear('MyIntelRGBCamHandle');
    catch
    end
    % apply the old transformation to the image
    tImgAfterMove = imwarp(ImgAfterMove, tform, 'OutputView', imref2d(size(ImgAfterMove)));
    tImgAfterMove = imcrop(tImgAfterMove, [0 0 801 801]);
    tImgAfterMoveGRAY = rgb2gray(tImgAfterMove);
    figure(5);
    imshow(tImgAfterMoveGRAY);
    
    % ===============================================================================================
    
    difference = double(tImgAfterMoveGRAY) - double(tImgBeforeMoveGRAY);
    figure(6);
    imshow(abs(difference));
    
    MotionOnBoard = zeros(8,8);
    x1 = 0;
    x2 = 0;
    val1 = 0;
    val2 = 0;
    y1 = 0;
    y2 = 0;
    
    for x = 1:8
        for y = 1:8
            h = drawellipse('Center',[x*cfS-cfS/2 y*cfS-cfS/2],'SemiAxes',[cfS/3 cfS/3], 'RotationAngle',0 ,'StripeColor','m');
            mask = createMask(h);
            MotionOnBoard(x,y) = sum(abs(difference(mask)));
            if (MotionOnBoard(x,y) > val1)
                val2 = val1;
                x2 = x1;
                y2 = y1;
                val1 = MotionOnBoard(x,y);
                x1 = x;
                y1 = y;
            elseif (MotionOnBoard(x,y) > val2 && MotionOnBoard(x,y) < val1)
                val2 = MotionOnBoard(x,y);
                x2 = x;
                y2 = y;
            end
        end
    end
    
%     figure(10);
%     plot( reshape(MotionOnBoard, numel(MotionOnBoard), 1));
%     
    if rem(NumOfMoves,2) == 0
        if (OccupiedOnBoardWhite(x1,y1) > 0)
            OccupiedOnBoardWhite(x2,y2) = OccupiedOnBoardWhite(x1,y1);
            OccupiedOnBoardWhite(x1,y1) = 0;
            % check if we took a piece
            if (OccupiedOnBoardBlack(x2,y2) > 0)
                OccupiedOnBoardBlack(x2,y2) = 0;
            end
        else
            OccupiedOnBoardWhite(x1,y1) = OccupiedOnBoardWhite(x2,y2);
            OccupiedOnBoardWhite(x2,y2) = 0;
            % check if we took a piece
            if (OccupiedOnBoardBlack(x1,y1) > 0)
                OccupiedOnBoardBlack(x1,y1) = 0;
            end
        end
    else
        if (OccupiedOnBoardBlack(x1,y1) > 0)
            OccupiedOnBoardBlack(x2,y2) = OccupiedOnBoardBlack(x1,y1);
            OccupiedOnBoardBlack(x1,y1) = 0;
            % check if we took a piece
            if (OccupiedOnBoardWhite(x2,y2) > 0)
                OccupiedOnBoardWhite(x2,y2) = 0;
            end
        else
            OccupiedOnBoardBlack(x1,y1) = OccupiedOnBoardBlack(x2,y2);
            OccupiedOnBoardBlack(x2,y2) = 0;
            % check if we took a piece
            if (OccupiedOnBoardWhite(x1,y1) > 0)
                OccupiedOnBoardWhite(x1,y1) = 0;
            end
        end
    end
    
    OccupiedOnBoardWhite
    OccupiedOnBoardBlack
    
    NumOfMoves = NumOfMoves + 1;
    tImgBeforeMoveGRAY = tImgAfterMoveGRAY;
end


% tImageGRAY = rgb2gray(tImage);
% figure(5);
% imshow(tImageGRAY);
% % points = detectORBFeatures(tImageGRAY); So so
% % points = detectBRISKFeatures(tImageGRAY); not good
% % points = detectSURFFeatures(tImageGRAY, 'NumScaleLevels', 6, 'NumOctaves', 5);  good
% points = detectKAZEFeatures(tImageGRAY, 'NumScaleLevels', 5, 'NumOctaves', 4);
% hold on
% plot(points,'ShowScale',false);
% hold off
% 
% % the camera motion involves little or no in-plane rotation.
% prevFeatures = extractFeatures(tImageGRAY, points, 'Upright', true);
% 
% % Match features between the previous and the current image.
% % get a new image
% try
%     % get the RGB image
%     MyCameras = webcamlist;
%     MyIntelRGB = MyCameras(2);
%     MyIntelRGBCamHandle = webcam(MyIntelRGB{1});
%     MyIntelRGBCamHandle.Resolution = '1920x1080';
%     ImgAfterMovemove = snapshot(MyIntelRGBCamHandle);
%     ImgAfterMovemoveGRAY = rgb2gray(ImgAfterMovemove);
%     clear('MyIntelRGBCamHandle');
% catch
% end
% tImageAfterMovemove = imwarp(ImgAfterMovemove, tform, 'OutputView', imref2d(size(ImgAfterMovemove)));
% tImageAfterMovemove = imcrop(tImageAfterMovemove, [0 0 801 801]);
% tImageAfterMovemoveGRAY = rgb2gray(tImageAfterMovemove);
% figure(5);
% imshow(tImageAfterMovemoveGRAY);
% 
% [currPoints, currFeatures, indexPairs] = helperDetectAndMatchFeatures(...
%     prevFeatures, tImageAfterMovemoveGRAY);
% 
% 
% 
% 
% % corners = detectFASTFeatures(tImageGRAY);
% % corners = detectHarrisFeatures(tImageGRAY);
% % corners = detectMinEigenFeatures(tImageGRAY);
% % hold on
% % plot(corners.selectStrongest(50));
% % hold off
% 
% % regions = detectMSERFeatures(tImageGRAY); good to get chessboard squares
% % hold on
% % plot(regions,'showPixelList',true,'showEllipses',false);
% % hold off

