
            ctx = realsense.context();
            cfg = realsense.config();
            cfg.enable_all_streams();
            pipe = realsense.pipeline(ctx);
            profile = pipe.start(cfg);
            
            %instanciate a hole filling filter
            obj.Hffc = realsense.hole_filling_filter(2);
            %instanciate the pointcloud class for processing
            pointcloud = realsense.pointcloud();
            catch
                warning('No depth Camera found, check connection!');
            end

            for i = 1:10
                % Obtain a fresh set of frames from the depth camera
                fs = pipe.wait_for_frames();
                
                % Realign the depth camera image to the RGB camera image
                align_to_depth = realsense.align(2);
                % feed the fs into the a
                afs = align_to_depth.process(fs);
                % get the depth map from the aligned frame set
                depth = afs.get_depth_frame();
                if (depth.logical())
                     FiltDepth = depth;
                    FiltDepthMap = FiltDepth.get_data();
                    %reorganize the the data in an image array
                    FiltDepthMap = permute(reshape(FiltDepthMap, [640, 480]),[2 1]);
                    % Produce pointcloud
                    points = pointcloud.calculate(depth);
                    vertices = points.get_vertices();
                    X = vertices(:,1,1);
                    Y = vertices(:,2,1);
                    Z = vertices(:,3,1);
                end
            end


MyCamera = RealSensePointcloud();

[X,Y,Z] = MyCamera.getPointcloud(10, 0);

 MyCamera.Disconnect();