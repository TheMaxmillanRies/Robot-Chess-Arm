classdef RealSensePointcloud < handle

    % Class that allows to obtain a point cloud over a field of view of the
    % build-in RGB camera (and the RGB camera imate itself).
    % optional hole filtering can be performed.
    % Important: The camera runs temporal filters, so run 5-10 frames for
    % the filters to stabilize.
    % Example usage:
    %     MyCamera = RealSensePointcloud();
    %     [X,Y,Z] = MyCamera.getPointcloud(10, 1);
    %     MyCamera.Disconnect();
    %     figure(1);
    %     plot3(X,Y,Z,'.');
    %     grid on
    %     hold off;
    %     view([45 30]);
    %     %xlim([-0.12 0.12])
    %     %ylim([0.2 0.4])
    %     %zlim([-0.12 0.12]) %depth axis
    %     xlabel('X');
    %     ylabel('Y');
    %     zlabel('Z');
            
            
    properties
        pipe        % this is the pipe to the real sense depth camera
        Hffc        % optional hole filter for pointcloud processing
        pointcloud  % pointcloud class with all the methods for depth-image to pointcloud processing
    end
    
    methods
        % constructor setting up the RealSense camera
        function obj = RealSensePointcloud()
            try
            % ===============================================
            % configure the depth camera
            ctx = realsense.context();
            cfg = realsense.config();
            cfg.enable_all_streams();
            obj.pipe = realsense.pipeline(ctx);
            profile = obj.pipe.start(cfg);
            fs = obj.pipe.wait_for_frames();
            %instanciate a hole filling filter
            obj.Hffc = realsense.hole_filling_filter(2);
            %instanciate the pointcloud class for processing
            obj.pointcloud = realsense.pointcloud();
            catch
                warning('No depth Camera found, check connection!');
            end
      
        end
        
        function Disconnect(obj)
            obj.pipe.stop();
        end
        
        % this method gets the RGB image from the camera
        function MyImage = getRGBframe(obj,aver)
            for i = 1:aver
                fs = obj.pipe.wait_for_frames();
                color = fs.get_color_frame();
                %Get actual data and convert into a format imshow can use
                data = color.get_data();
                %(Color data arrives as [R, G, B, R, G, B, ...] vector)
                MyImage = permute(reshape(data',[3,color.get_width(),color.get_height()]),[3 2 1]);
                %Display the image
            end
        end
        
        % aver is the number of frame averages for temporal filtering
        % filter = 1 apply a hole filter to the depth map
        function [X,Y,Z] = getPointcloud(obj,aver, filter)
            % Main loop
            for i = 1:aver
                % Obtain a fresh set of frames from the depth camera
                fs = obj.pipe.wait_for_frames();
                
                % Realign the depth camera image to the RGB camera image
                align_to_depth = realsense.align(2);
                % feed the fs into the a
                afs = align_to_depth.process(fs);
                % get the depth map from the aligned frame set
                depth = afs.get_depth_frame();
                if (depth.logical())
                    if (filter)
                        FiltDepth = obj.Hffc.process(depth);
                    else
                        FiltDepth = depth;
                    end
                    FiltDepthMap = FiltDepth.get_data();
                    %reorganize the the data in an image array
                    FiltDepthMap = permute(reshape(FiltDepthMap, [640, 480]),[2 1]);
                    % FiltDepthMap = permute(reshape(FiltDepthMap, [848, 480]),[2 1]);
                    % Produce pointcloud
                    points = obj.pointcloud.calculate(depth);
                    vertices = points.get_vertices();
                    X = vertices(:,1,1);
                    Y = vertices(:,2,1);
                    Z = vertices(:,3,1);
                end
            end
        end
        
    end
    
end


