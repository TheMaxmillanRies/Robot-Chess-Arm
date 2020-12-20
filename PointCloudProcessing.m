classdef PointCloudProcessing < handle
    %Class which processes a given point cloud and forward kinematics
    %matrix to obtain the individual clusters representing chess pieces.
    
    properties
        %pointCloud data points
        X; Y; Z;
        
        %forward kinematics for clipping purposes
        fkine; %CURRENTLY HARDCODED/UNUSED
        
        %what does name stand for?
        loc;
        
        %pointCloud
        ptCloud;
        
        %minimum distance for cluster rendering. Default 0.0075
        minDistance = 0.0075;
        
        %number of clusters
        numClusters;
        
        %cluster labels
        labels;
        
        %Cluster coordinates
        coors;
        
        %Chessboard Distance to mirror image
        mirrorValue = 0.28;
    end
    
    methods
        function obj = PointCloudProcessing(X, Y, Z, fkine)
            %store the given data in the properties
            obj.X = X;
            obj.Y = Y;
            
            %             for i = Z
            %                 if i < obj.mirrorValue
            %                     Z(i) = Z(i) + obj.mirrorValue;
            %                 end
            %             end
            
            obj.Z = Z;
            obj.fkine = fkine;
        end
        
        %Printing function which displays the current pointCloud
        function Print(obj, figureNumber)
            figure(figureNumber);
            plot3(obj.X,obj.Y,obj.Z,'.');
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
        
        function range = getRange(obj, fkine)
            range = 0; %DELETE ME
        end
        
        %range contains the boundaries for X, Y and Z
        function obj = getValidIndex(obj, range)
            indexClipped = find((obj.Y<0.2) & (obj.Y>-0.2) &(obj.X<0.21) & (obj.X>-0.175) & (obj.Z<0.2555)& (obj.Z>0.20));
            obj.X = obj.X(indexClipped);
            obj.Y = obj.Y(indexClipped);
            obj.Z = obj.Z(indexClipped);
        end
        
        function [ptCloud, loc] = createPointCloud(obj)
            loc = [obj.X(:), obj.Y(:), obj.Z(:)];
            ptCloud = pointCloud(loc);
        end
        
        function [labels,numClusters] = getClusters(obj)
            [labels,numClusters] = pcsegdist(obj.ptCloud,obj.minDistance);
        end
        
        function colorClusters(obj)
            labelColorIndex = obj.labels+1;
            figure(3);
            pcshow(obj.ptCloud.Location,labelColorIndex);
            colormap([hsv(obj.numClusters+1);[0 0 0]]);
            title('Point Cloud Clusters');
        end
        
        function coors = getClusterCenter(obj)
            for i=1:obj.numClusters
                index = find(obj.labels == i);
                clusterCoors = obj.loc(index,:);
                coors(i,:) = mean(clusterCoors);
            end
        end
        
        function PrintClusterCenter(obj)
            figure(2);
            for i = 1:obj.numClusters
                hold on;
                plot3(obj.coors(i,1), obj.coors(i,2), obj.coors(i,3), 'O','LineWidth',3);
                hold off;
            end
        end
        
        function obj = fuseClusters(obj)
            for i=2:obj.numClusters
                for j = i:obj.numClusters
                    %if (i ~= j)
                        %calculate the distance between the two clusters
                        dis = sqrt( (obj.coors(i,1) - obj.coors(j,1))^2 + (obj.coors(i,2) - obj.coors(j,2))^2);
                        %fuse clusters, which are blow each other
                        if (dis<0.021) %default 0.02
                            index = find(obj.labels == j);
                            obj.labels(index) = i;
                        end
                    %end
                end
            end
            counter = 1;
            dummy_label = zeros(numel(obj.labels),1);
            for i=1:obj.numClusters
                index = find(obj.labels == i);
                if ( numel(index) > 1)
                    dummy_label(index) = counter;
                    counter=counter + 1;
                end
            end
            obj.labels = dummy_label;
            obj.numClusters = counter-1;
        end
    end
end

