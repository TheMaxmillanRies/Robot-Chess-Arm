function pointcloud_example()
    % Make Pipeline object to manage streaming
    %pipe = realsense.pipeline();
    
    ctx = realsense.context();
    % devices = ctx.query_devices()
    % devices{1}.get_info()
    
    cfg = realsense.config();
    cfg.enable_all_streams();
    pipe = realsense.pipeline(ctx);
    profile = pipe.start(cfg);
    
    %create a hole filling filter
    Hffc = realsense.hole_filling_filter(2);
    
    pointcloud = realsense.pointcloud();

    % Start streaming on an arbitrary camera with default settings
    %profile = pipe.start();

%     figure('visible','on');  hold on;
%     figure('units','normalized','outerposition',[0 0 1 1])

    % Main loop
    for i = 1:10

        % Obtain frames from a streaming device
        fs = pipe.wait_for_frames();
        
        % Mario test aligning to the RGB camera
        align_to_depth = realsense.align(2);
        afs = align_to_depth.process(fs);
        
        % Select depth frame
        %depth = fs.get_depth_frame();
        depth = afs.get_depth_frame();
        %color = fs.get_color_frame();
        
        FiltDepth = Hffc.process(depth);
        FiltDepthMap = FiltDepth.get_data();
        FiltDepthMap = permute(reshape(FiltDepthMap, [640, 480]),[2 1]);
    
%         figure(2);
%         imshow(FiltDepthMap);
%         
%         figure(3);
%         surf(FiltDepthMap);
        
        % Produce pointcloud
        if (depth.logical())% && color.logical())

            %pointcloud.map_to(color);
            points = pointcloud.calculate(depth);
            
            % Adjust frame CS to matlab CS
            vertices = points.get_vertices();
            X = vertices(:,1,1);
            Y = vertices(:,2,1);
            Z = vertices(:,3,1);

            
            % Mario: test a rotation:
            % xaxis rotation
            
%             omega = -0.0000;
%             theta =  0.0;
%             
%             Xr1 = X;
%             Yr1 = Y*cos(theta) - Z*sin(theta);
%             Zr1 = Y*sin(theta) + Z*cos(theta);
%     
%             % yaxis rotation
%             Xr2 = Xr1*cos(omega) + Zr1*sin(omega);
%             Yr2 = Yr1;
%             Zr2 = Zr1*cos(omega) - Xr1*sin(omega);
            
            % rotate into a convient frame of refernce for matlab
            Xr2 = X;
            Yr2 = Z;
            Zr2 = -Y;
            
            
            figure(1);
            plot3(Xr2,Yr2,Zr2,'.');
            
            %plot3(X,Z,-Y,'.');
            grid on
            hold off;
            view([45 30]);

            xlim([-0.12 0.12])
            ylim([0.2 0.4])
            zlim([-0.12 0.12]) %depth axis

            
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
            
            pause(0.01);
        end
        % pcshow(vertices); Toolbox required
    end

     % Stop streaming
    pipe.stop();
    
end