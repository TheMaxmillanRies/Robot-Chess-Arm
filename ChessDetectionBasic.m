% load images
% tform
% apply tform
% crop
% get difference
% loop of paps code
% sort

load('ptCloud_RGB_calibration.mat');

[imagePoints,boardSize,pairsUsed] = detectCheckerboardPoints(MyRGB_Image, 'MinCornerMetric', 0.55);
% figure(1);
% imshow(MyRGB_Image);
% hold on;
% plot(imagePoints(:,1,1), imagePoints(:,2,1),'ro');
% hold off;

cfS = 50;

fixedPoints = [cfS cfS; 7*cfS cfS; 7*cfS 7*cfS; cfS 7*cfS];
movingPoints = [imagePoints(7,:); imagePoints(1,:); imagePoints(43,:); imagePoints(49,:)];
% sort the moving points by size to prevent ambigious rotations
a = zeros(4,1);
for i = 1:4
    a(i) = movingPoints(i,1) * movingPoints(i,2);
end
[a, indexI] = sort(a); %this crap causes it all
movingPoints  = [ movingPoints(indexI(1),:); movingPoints(indexI(2),:); movingPoints(indexI(4),:); movingPoints(indexI(3),:) ]; 
tform = fitgeotrans(movingPoints, fixedPoints, 'projective');
save('tform.mat', 'tform');

tImage = imwarp(MyRGB_Image, tform, 'OutputView', imref2d(size(MyRGB_Image)));
tImage = imcrop(tImage, [0 0 398 398]);

% figure(2);
% imshow(tImage);

load('ptCloud_before_move.mat');
beforeImage = imwarp(MyRGB_Image, tform, 'OutputView', imref2d(size(MyRGB_Image)));
beforeImage = imcrop(beforeImage, [0 0 398 398]);
bwBeforeImage = rgb2gray(beforeImage);
imshow(bwBeforeImage);

load('ptCloud_after_move.mat');
afterImage = imwarp(MyRGB_Image, tform, 'OutputView', imref2d(size(MyRGB_Image)));
afterImage = imcrop(afterImage, [0 0 398 398]);
bwAfterImage = rgb2gray(afterImage);
imshow(bwAfterImage);

difference = double(bwBeforeImage) - double(bwAfterImage);
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
    
    %[B,I] = sort(MotionOnBoard, 'descend');
    
    %finds maximum of matrix
    max1 = 0;
    max1Index = 0;
    max2 = 0;
    max2Index = 0;
    MotionOnBoardCopy = MotionOnBoard;
    for i = 1:8
        for j = 1:8
            if(MotionOnBoardCopy(i,j) > max1)
                max2 = max1;
                max2Index = max1Index;
                max1 = MotionOnBoardCopy(i,j);
                max1Index = [i,j];
            elseif(MotionOnBoardCopy(i,j) > max2)
                max2 = MotionOnBoardCopy(i,j);
                max2Index = [i,j];
            end
        end
    end
    