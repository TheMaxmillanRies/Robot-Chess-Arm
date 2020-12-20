ctx = realsense.context();
% devices = ctx.query_devices()
% devices{1}.get_info()

cfg = realsense.config();
cfg.enable_all_streams();
pipe = realsense.pipeline(ctx);
profile = pipe.start(cfg);

% Get a depth map
    %%pipe = realsense.pipeline();
    colorizer = realsense.colorizer();
    % try to connect to the depth camera
    %%profile = pipe.start();
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
    
    % test aligning
    align_to_depth = realsense.align(2);
    afs = align_to_depth.process(fs);
    
    % Select depth frame
    depth = afs.get_depth_frame();
    
    %create a hole filling filter
    Hffc = realsense.hole_filling_filter(2);
    FiltDepth = Hffc.process(depth);
    
    FiltDepthMap = FiltDepth.get_data();
    FiltDepthMap = permute(reshape(FiltDepthMap, [640, 480]),[2 1]);
    figure(7);
    imshow(FiltDepthMap);
    %     surf(FiltDepthMap);
    
    
    RGBframe = afs.get_color_frame();
    imgVec = RGBframe.get_data();
    xdim = RGBframe.get_width();
    ydim = RGBframe.get_height();
    img = reshape(imgVec, [3,xdim, ydim]);
    %test = reshape(img(3,:,:), [xdim, ydim]);
    RGBImg = permute(reshape(img,[3,xdim,ydim]),[3 2 1]);
    figure(1);
    imshow(RGBImg);
    
    % Colorize depth frame
    color = colorizer.colorize(FiltDepth);
    % Get actual data and convert into a format imshow can use
    % (Color data arrives as [R, G, B, R, G, B, ...] vector)
    data = color.get_data();
    DepthImg = permute(reshape(data',[3,color.get_width(),color.get_height()]),[3 2 1]);
    
    % Display image
    figure(3)
    imshow(DepthImg);
    title(sprintf("Colorized depth frame from %s", name));
    
    [imagePoints,boardSize,pairsUsed] = detectCheckerboardPoints(RGBImg, 'MinCornerMetric', 0.25);
    %
    figure(3);
    imshow(RGBImg);
    hold on;
    plot(imagePoints(:,1,1), imagePoints(:,2,1),'ro');
    hold off;
    %
    cfS = 50;
    RimSize = 45;
    
    fixedPoints = [cfS+RimSize cfS+RimSize; 7*cfS+RimSize cfS+RimSize; 7*cfS+RimSize 7*cfS+RimSize; cfS+RimSize 7*cfS+RimSize];
    movingPoints = [imagePoints(7,:); imagePoints(1,:); imagePoints(43,:); imagePoints(49,:)];
    % sort the moving points by size to prevent ambigious rotations
    a = zeros(4,1);
    for i = 1:4
        a(i) = movingPoints(i,1) * movingPoints(i,2);
    end
    [a, indexI] = sort(a); %this crap causes it all
    movingPoints  = [ movingPoints(indexI(1),:); movingPoints(indexI(2),:); movingPoints(indexI(4),:); movingPoints(indexI(3),:) ];
    tform = fitgeotrans(movingPoints, fixedPoints, 'projective');
    
    
    %load('tform');
    tRgbImage = imwarp(RGBImg, tform, 'OutputView', imref2d(size(RGBImg)));
    tRgbImage = imcrop(tRgbImage, [0 0 8*cfS+2*RimSize 8*cfS+2*RimSize]);
    
    figure(3);
    imshow(tRgbImage);
    
    
    tFiltDepthMap = imwarp(FiltDepthMap, tform, 'OutputView', imref2d(size(FiltDepthMap))); %FiltDepthMAp = 480 x 640
    tFiltDepthMap = imcrop(tFiltDepthMap, [0 0 8*cfS+2*RimSize 8*cfS+2*RimSize]); % tFiltDepthMAp = 480 x 490
    figure(2);
    imshow(tFiltDepthMap);
    surf(tFiltDepthMap)
    
    % ================================================================================================================
    % Add board pieces
    % ================================================================================================================
    
    xvec = linspace(1, 480, 480);
    yvec = linspace(1, 490, 490);
    %zarray = ones(640, 480);
    [XOut, YOut, ZOut] = prepareSurfaceData(xvec, yvec, tFiltDepthMap);
    
    figure(10);
    surf(reshape(XOut, [480, 490]),reshape(YOut, [480, 490]),reshape(ZOut, [480, 490]));
    
        
    figure(1)
    f = fit([XOut, YOut],ZOut,'poly11');
    plot( f, [XOut, YOut],ZOut );
    
    theta =  - atan(f.p01);
    omega =  - atan(f.p10);
    
    % xaxis rotation
    Xr1 = XOut;
    Yr1 = YOut*cos(theta) - ZOut*sin(theta);
    Zr1 = YOut*sin(theta) + ZOut*cos(theta);
    
    % yaxis rotation
    Xr2 = Xr1*cos(omega) + Zr1*sin(omega);
    Yr2 = Yr1;
    Zr2 = Zr1*cos(omega) - Xr1*sin(omega);
    
    figure(11);
    surf(reshape(Xr2, [480, 490]),reshape(Yr2, [480, 490]),reshape(Zr2, [480, 490]));
    
    test = abs(Zr2 - f.p00);   %+ f.p10*XOut + f.p01*YOut));
    %test = test/ max(test);
    surf(reshape(test, [480, 490]));
    
    % take a new frame with chesspieces
    profile = pipe.start(cfg);
    dev = profile.get_device();
    name = dev.get_info(realsense.camera_info.name);
    % Get frames. We discard the first couple to allow
    % the camera time to settle
    for i = 1:5
        fs = pipe.wait_for_frames();
    end
    % Stop streaming
    pipe.stop();
    
    %align images
    afs = align_to_depth.process(fs);
    % Select depth frame
    depth = afs.get_depth_frame();
    
    %process depth image
    FiltDepth = Hffc.process(depth);
    
    % pull the data and reshape
    FiltDepthMap = FiltDepth.get_data();
    FiltDepthMap = permute(reshape(FiltDepthMap, [640, 480]),[2 1]);
    
    figure(1);
    imshow(FiltDepthMap);
    
    
    % apply the transformation for dewarping
    tFiltDepthMap = imwarp(FiltDepthMap, tform, 'OutputView', imref2d(size(FiltDepthMap)));
    tFiltDepthMap = imcrop(tFiltDepthMap, [0 0 8*cfS+2*RimSize 8*cfS+2*RimSize]);
    
    % subtract the "tilted floor"
    [XOut, YOut, ZOut] = prepareSurfaceData(xvec, yvec, tFiltDepthMap);
    
    % xaxis rotation
    Xr1 = XOut;
    Yr1 = YOut*cos(theta) - ZOut*sin(theta);
    Zr1 = YOut*sin(theta) + ZOut*cos(theta);
    
    % yaxis rotation
    Xr2 = Xr1*cos(omega) + Zr1*sin(omega);
    Yr2 = Yr1;
    Zr2 = Zr1*cos(omega) - Xr1*sin(omega);
     
    test = abs(Zr2 - f.p00);   %+ f.p10*XOut + f.p01*YOut));
    test = test/ max(test);
    figure(3);
    surf(reshape(test, [400, 400]));
    
    testbild = zeros(800,800);
    
    for i=1:160000
        i = 5;
        [px,py,pz]=projection(0,0,0,0,Xr2(i),Yr2(i),test(i));
        testbild(400 - round(px), 400 - round(py)) = pz;        
    end
    figure(1);
    imshow(testbild);
    
    figure(1);
    view(0,90)  % XY
    surf(reshape(XOut, [400, 400]),reshape(YOut, [400, 400]),reshape(ZOut, [400, 400]));
    view(0,90)  % XY
    colormap gray;
    %imshow(reshape(test, [400, 400]));
    %surf(reshape(test, [400, 400]));
    
    
    %========================== test projection code
    [XOut, YOut, ZOut] = prepareSurfaceData(xvec, yvec, tFiltDepthMap);
    
    %setup camera with focal length 200, centre 500,500
    cam = [500,0,500;0,500,500;0,0,1];
    
    z = reshape(ZOut, [480, 490]);
    x = reshape(XOut, [480, 490]);
    y = reshape(YOut, [480, 490]);
    c = z - min(z(:));
    c = c./max(c(:));
    c = round(255*c) + 1;
    cmap = colormap(jet(256));
    c = cmap(c,:);
    
    points = [x(:),y(:),z(:),c];
    
    
    imageSize = [1000,1000];
    tform = eye(4);
    position = [50,-300,100];
    tform = eye(4);
    tform(1:3,4) = position;
    %add a little lens distortion
    dist = [0.0,0.000];
    %project the points into image coordinates
    [projected, valid] = projectPoints(points, cam, tform, dist, imageSize,true);
    projected = projected(valid,:);
    
    figure(2);
    %show the projection
    subplot(1,2,1);
    scatter3(points(:,1),points(:,2),points(:,3),20,points(:,4:6),'fill');
    axis equal;
    title('Original Points');
    
    subplot(1,2,2);
    scatter(projected(:,1),projected(:,2),20,projected(:,3:5),'fill');
    axis equal;
    title('Points projected with camera model');
    %========================== end test projection code
    
    
    test1 = abs(ZOut - (f.p00 + f.p10*XOut + f.p01*YOut));
    test1 = test/ max(test);
    figure(3);
    imshow(reshape(test1, [400, 400]));
    
     for x = 1:8
        for y = 1:8
            h = drawellipse('Center',[x*cfS-cfS/2 y*cfS-cfS/2],'SemiAxes',[cfS/3 cfS/3], 'RotationAngle',0 ,'StripeColor','m');
        end
    end
    
    %pull the RGB frame
    RGBframe = afs.get_color_frame();
    imgVec = RGBframe.get_data();
    xdim = RGBframe.get_width();
    ydim = RGBframe.get_height();
    img = reshape(imgVec, [3,xdim, ydim]);
    %test = reshape(img(3,:,:), [xdim, ydim]);
    RGBImg = permute(reshape(img,[3,xdim,ydim]),[3 2 1]);
    
    % morph the RGB image
    tRgbImage = imwarp(RGBImg, tform, 'OutputView', imref2d(size(RGBImg)));
    tRgbImage = imcrop(tRgbImage, [0 0 8*cfS 8*cfS]);
    
    figure(2);
    imshow(tRgbImage);
    for x = 1:8
        for y = 1:8
            h = drawellipse('Center',[x*cfS-cfS/2 y*cfS-cfS/2],'SemiAxes',[cfS/3 cfS/3], 'RotationAngle',0 ,'StripeColor','m');
        end
    end
    
    
    
    