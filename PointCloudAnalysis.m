classdef PointCloudAnalysis < handle
    % Class used to analyze and process a given pointcloud
    
    
    properties
        X; Y; Z; % Point Cloud Data
        
        point_cloud; % Point Cloud MatLab object
        
        board_middle; %Array with XY median values
    end
    
    methods
        
        % Constructor of the Point Cloud Analysis Class
        function obj = PointCloudAnalysis(data_type, data)
            
            if data_type == "raw_data"
                obj.AssignRawData(data(:,1), data(:,2), data(:,3));
                obj.point_cloud = obj.CreatePointCloud(obj.X, obj.Y, obj.Z);
            end
            
            if data_type == "point_cloud"
                obj.AssignPointCloud(data);
                obj.GetPointCloudData();
            end
            
        end
        
        % Assigns input to XYZ data
        function AssignRawData(obj, X, Y, Z)
            % Store given coordinates in class properties
            obj.X = X;
            obj.Y = Y;
            obj.Z = Z;
        end
        
        % Assigns input to point cloud
        function AssignPointCloud(obj, input_point_cloud)
            obj.point_cloud = input_point_cloud;
        end
        
        % Creates point cloud based on object's current XYZ data
        function point_cloud = CreatePointCloud(obj, X, Y, Z)
            point_cloud = pointCloud([X, Y, Z]);
        end
        
        % Displays Point Cloud on desired figure
        function PlotPointCloud(obj, point_cloud, figureNumber)
            figure(figureNumber); % Set figure number

            data = point_cloud.Location;
            for row = 0.148:-0.037:-0.148
                for column = -0.148:0.005:0.148
                    data = vertcat(data, [column, row, 0.38]);
                end
            end
            
            for column = -0.148:0.037:0.148
                for row = 0.148:-0.005:-0.148
                    data = vertcat(data, [column, row, 0.38]);
                end
            end
            
            point_cloud = obj.CreatePointCloud(data(:,1), data(:,2), data(:,3));
            
            pcshow(point_cloud); % Display Point Cloud
            
            % Set axis labels
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
        
        % Plot current class point cloud
        function PlotCurrentPointCloud(obj, figureNumber)
            obj.PlotPointCloud(obj.point_cloud, figureNumber);
        end
        
        % Update XYZ to current point cloud data
        function GetPointCloudData(obj)
            % Obtain matrix containing pointcloud X Y and Z coordinates
            data_matrix = obj.point_cloud.Location;
            
            % Split matrix into 3 respective component vectors
            obj.X = data_matrix(:,1);
            obj.Y = data_matrix(:,2);
            obj.Z = data_matrix(:,3);
        end
        
        % Clip point cloud XYZ based on given boundaries
        function [X, Y, Z] = ClipPointCloud(obj, X, Y, Z, x_bounds, y_bounds, z_bounds)
            % Get index of objects which fullfill given condition
            clipIndex = find((X < x_bounds(1) & X > x_bounds(2)) & ...
                (Y < y_bounds(1) & Y > y_bounds(2)) & ...
                (Z < z_bounds(1) & Z > z_bounds(2)));
            
            % Update XYZ to clipped values
            X = X(clipIndex);
            Y = Y(clipIndex);
            Z = Z(clipIndex);
        end
        
        % Use calibration file to get middle of the board and center the data
        function Calibrate(obj)
            % Load calibration pointcloud
            calibration_data = load("ptCloud_Depth_camera_calibration.mat");
            
            % Get Center Piece XYZ information
            [calibration_data.X, calibration_data.Y, calibration_data.Z] = ...
                obj.ClipPointCloud(calibration_data.X, calibration_data.Y, calibration_data.Z, [0.1, 0], [0.05, -0.05], [0.4, 0.3]);
            
            % Get Median of the pointcloud -> Center of the board
            obj.board_middle.X = median(calibration_data.X);
            obj.board_middle.Y = median(calibration_data.Y);
            
            % Center data
            obj.X = obj.X - obj.board_middle.X;
            obj.Y = obj.Y - obj.board_middle.Y;
            
            % Clip pointcloud using size of board and center information and update point cloud
            [obj.X, obj.Y, obj.Z] = obj.ClipPointCloud(obj.X, obj.Y, obj.Z, [0.148, -0.148], [0.148, -0.148], [0.385, 0.3]);
            
            obj.point_cloud = obj.CreatePointCloud(obj.X, obj.Y, obj.Z);
        end
        
        % Process data using clustering techniques
        function ClusterProcessing(obj)
            
            % Min Distance between points for clustering
            min_distance = 0.005; %0.0075;
            
            sizeZ = size(obj.Z);
            newZ = zeros(sizeZ(1), 1);
            
            p = pointCloud([obj.X, obj.Y, newZ]);
            figure(3);
            pcshow(p);
            
            [labels, numClusters] = pcsegdist(p, min_distance);
            %disp(numClusters);
            
            obj.ColorClusters(p, labels, numClusters);
            
            cluster_center_list = zeros(numClusters, 3);
            
            for i = 1:numClusters
                index  = find(labels == i);
                newX = obj.X(index);
                newY = obj.Y(index);
                newZ = obj.Z(index);
                
                data = [newX, newY, newZ];
                [~,idx] = sort(data(:,3)); % sort just the third column
                data = data(idx,:);   % sort the whole matrix using the sort indices
                
                d_size = size(data);
                data = data(1:round(d_size(1)/20), :);
                
                cluster_center = mean(data);
                
                figure(1)
                hold on;
                plot3(cluster_center(1), cluster_center(2), cluster_center(3), 'O','LineWidth',3);
                hold off;
                
                cluster_center_list(i,:) = cluster_center;
            end
            
            board_state = "";
            
            % Outer Loop: Rows. Inner loop: Columns.
            for row = 0.148:-0.037:-0.111
                for column = -0.148:0.037:0.111
                    
                    [tmpX, tmpY, tmpZ] = obj.ClipPointCloud(cluster_center_list(:,1), cluster_center_list(:,2), cluster_center_list(:,3), [column+0.037, column],...
                        [row, row-0.037],...
                        [0.4, 0.3]);
                    
                    % Get number of data points
                    d_size = size(tmpX);
                    
                    
                    % Append to string if a piece is there or not
                    if d_size(1) > 0
                        board_state = board_state + "1";
                    else
                        board_state = board_state + "0";
                    end
                end
                board_state = board_state + "/";
            end
            % DEBUG: Display final string
            disp(board_state);
            
            
        end
        
        % Colors Clusters
        function ColorClusters(obj, point_cloud, labels, numClusters)
            labelColorIndex = labels+1;
            
            % Currently Plot on figure 2. To be changed
            figure(2);
            pcshow(point_cloud.Location, labelColorIndex);
            
            % Change background to white. Black cluster invisible on black
            % background and label axis
            set(gca,'color','w');
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
            
            % Make colormap using number of clusters
            colormap([hsv(numClusters+1);[0 0 0]]);
        end
        
        
        
        % Process the data with a "Rolling Mask"
        function SegmentationProcessing(obj)
            
            % Board string and offset
            board_state = "";
            shrink_offset = 0.002;
            
            % Outer Loop: Rows. Inner loop: Columns.
            for row = 0.148:-0.037:-0.111
                for column = -0.148:0.037:0.111
                    
                    % Clip data
                    [tmpX, tmpY, tmpZ] = obj.ClipPointCloud(obj.X, obj.Y, obj.Z, [column+0.037-shrink_offset, column+shrink_offset],...
                        [row-shrink_offset, row-0.037+shrink_offset],...
                        [0.4, 0.3]);
                    
                    %---------------Clustering Addon--------------%
                    if size(tmpX) > 0
                        min_distance = 0.005;
                        
                        sizeZ = size(tmpZ);
                        newZ = zeros(sizeZ(1), 1);
                        
                        p = pointCloud([tmpX, tmpY, newZ]);
                        
                        [labels, numClusters] = pcsegdist(p, min_distance);
                                                
                        largest_cluster = [0 0 0];
                        for cluster = 1:numClusters
                            index  = find(labels == cluster);
                            if size(index) > size(largest_cluster)
                                largest_cluster = index;
                            end
                        end
                    end
                    
                    
                    %---------------------END---------------------%                    
                    
                    % Get number of data points
                    d_size = size(tmpX);
                    
                    % Append to string if a piece is there or not
                    if d_size(1) > 225
                        board_state = board_state + "1";
                    else
                        board_state = board_state + "0";
                    end
                end
                board_state = board_state + "/";
            end
            % DEBUG: Display final string
            disp(board_state);
        end
        
    end
    
end