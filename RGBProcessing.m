classdef RGBProcessing < handle
    
    properties
        tform;
        
        cfS = 50;
        
        beforeImage;
        afterImage;
        
        MotionOnBoard;
        
        max1 = 0;
        max1Index = 0;
        max2 = 0;
        max2Index = 0;
        
    end
    
    methods
        function obj = RGBProcessing()
            
            obj.Initialize();
            
            
            
        end
        
        function Initialize(obj)
            Image = obj.LoadImage('ptCloud_RGB_calibration.mat');
            [imagePoints,boardSize,pairsUsed] = detectCheckerboardPoints(Image, 'MinCornerMetric', 0.55);
            
            fixedPoints = [obj.cfS obj.cfS; 7*obj.cfS obj.cfS; 7*obj.cfS 7*obj.cfS; obj.cfS 7*obj.cfS];
            movingPoints = [imagePoints(7,:); imagePoints(1,:); imagePoints(43,:); imagePoints(49,:)];
            
            
            a = zeros(4,1);
            for i = 1:4
                a(i) = movingPoints(i,1) * movingPoints(i,2);
            end
            [a, indexI] = sort(a);
            
            movingPoints  = [ movingPoints(indexI(1),:); movingPoints(indexI(2),:); movingPoints(indexI(4),:); movingPoints(indexI(3),:) ];
            obj.tform = fitgeotrans(movingPoints, fixedPoints, 'projective');
            
        end
        
        function ProcessImages(obj, Image1, Image2)
            difference = double(Image1) - double(Image2);
            figure(1);
            imshow(abs(difference));
            
            obj.MotionOnBoard = zeros(8,8);
            for x = 1:8
                for y = 1:8
                    h = drawellipse('Center',[x*obj.cfS-obj.cfS/2 y*obj.cfS-obj.cfS/2],'SemiAxes',[obj.cfS/3 obj.cfS/3], 'RotationAngle',0 ,'StripeColor','m');
                    mask = createMask(h);
                    obj.MotionOnBoard(x,y) = sum(abs(difference(mask)));
                end
            end
        end
        
        function getMax(obj)
            for i = 1:8
                for j = 1:8
                    if(obj.MotionOnBoard(i,j) > obj.max1)
                        obj.max2 = obj.max1;
                        obj.max2Index = obj.max1Index;
                        obj.max1 = obj.MotionOnBoard(i,j);
                        obj.max1Index = [i,j];
                    elseif(obj.MotionOnBoard(i,j) > obj.max2)
                        obj.max2 = obj.MotionOnBoard(i,j);
                        obj.max2Index = [i,j];
                    end
                end
            end
        end
        
        function Image = FitCropAndBW(obj, Image)
            Image = imwarp(Image, obj.tform, 'OutputView', imref2d(size(Image)));
            Image = imcrop(Image, [0 0 398 398]);
            Image = rgb2gray(Image);
        end
        
        function Image = LoadImage(obj, String)
            Struct = load(String, 'MyRGB_Image');
            Image = Struct.MyRGB_Image;
        end
    end
end

