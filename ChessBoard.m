classdef ChessBoard < handle
    properties
        ChessBoardCellArray  %Coordinates used are the "center of mass"
        ChessBoardCellSize = 0.037; %in meter (!)
        MyCBDisp %Class for visualization
        PointCloudOffset        % translstional offset between the camera and the chess board center
        debug
    end
    
    methods
        function obj = ChessBoard(MyCBDisp)

            storeAt = 0;
            for i = 1:8
                for j = 1:8
                    storeAt = storeAt + 1;
                    coors = obj.GetSquareCenter(i,j);
                    obj.ChessBoardCellArray(storeAt).CurrentPiece = 0;
                    obj.ChessBoardCellArray(storeAt).ColorOfPiece = 0;
                    obj.ChessBoardCellArray(storeAt).Xpos = coors(1);
                    obj.ChessBoardCellArray(storeAt).Ypos = coors(2);
                    obj.ChessBoardCellArray(storeAt).Zpos = coors(3);
                    obj.ChessBoardCellArray(storeAt).DetectedAsStillOccupied = 0;
                    obj.ChessBoardCellArray(storeAt).DetectedAsNewlyOccupied = 0;
                end
            end
            obj.MyCBDisp = MyCBDisp;
        end
        
        function SendPointCloudOffset(obj, PointCloudOffset)
            obj.PointCloudOffset = PointCloudOffset;  
        end
        
        
        function CompareDetectorWithBoard(obj, ClusterCoordinates, numClusters)
            % loop over each (non)occupied field
            
            debugDist=[0];
            
            figure(4);
            clf('reset')
            xlabel('X'); 
            ylabel('Y'); 
            zlabel('Z');
            hold on;
            % visualisation for debug
            for j = 1:64
                % plot the center of the board field
                plot3(obj.ChessBoardCellArray(j).Xpos,obj.ChessBoardCellArray(j).Ypos,obj.ChessBoardCellArray(j).Zpos,'b.');
                text(obj.ChessBoardCellArray(j).Xpos+0.005,obj.ChessBoardCellArray(j).Ypos,obj.ChessBoardCellArray(j).Zpos, num2str(j), 'FontSize', 8 );
            end
            for i = 1:numClusters
                
                plot3(ClusterCoordinates(i,1) - obj.PointCloudOffset(1), ClusterCoordinates(i,2)- obj.PointCloudOffset(2), ClusterCoordinates(i,3)- obj.PointCloudOffset(3),'ro');
                text(ClusterCoordinates(i,1) - obj.PointCloudOffset(1), ClusterCoordinates(i,2)- obj.PointCloudOffset(2), ClusterCoordinates(i,3)- obj.PointCloudOffset(3), num2str(i), 'FontSize', 6 );
            end
            hold off;
            
            
            
            figure(6);

            clf('reset');
            hold on;
            axis manual;
            axis([-0.15 0.15 -0.15 0.15 -5 5]);
            xlabel('X'); 
            ylabel('Y'); 
            zlabel('Z');
            for j = 1:64
                
                % if there has been a piece on this field before, we check
                % if it is still occupied by comparing if any of the
                % clusters is here
                figure(6);
                plot3(obj.ChessBoardCellArray(j).Xpos,obj.ChessBoardCellArray(j).Ypos,obj.ChessBoardCellArray(j).Zpos,'b.');
                text(obj.ChessBoardCellArray(j).Xpos+0.005,obj.ChessBoardCellArray(j).Ypos,obj.ChessBoardCellArray(j).Zpos, num2str(j), 'FontSize', 8 );
                
                if (obj.ChessBoardCellArray(j).CurrentPiece > 0)
                    obj.ChessBoardCellArray(j).DetectedAsOccupied = 0;
                    for i = 1:numClusters
                        dis = sqrt( (ClusterCoordinates(i,1) - obj.PointCloudOffset(1) - obj.ChessBoardCellArray(j).Xpos)^2 + (ClusterCoordinates(i,2) - obj.PointCloudOffset(2) - obj.ChessBoardCellArray(j).Ypos)^2);
                            
                        if (j == 18 && i == 17)
                           a=5; 
                        end
                        
                        if (dis <= obj.ChessBoardCellSize/2)
                                dis
                                figure(6);
                                obj.ChessBoardCellArray(j).DetectedAsStillOccupied = 1;
                                plot3(ClusterCoordinates(i,1) - obj.PointCloudOffset(1), ClusterCoordinates(i,2)- obj.PointCloudOffset(2), ClusterCoordinates(i,3)- obj.PointCloudOffset(3),'go');
                                text(ClusterCoordinates(i,1) - obj.PointCloudOffset(1), ClusterCoordinates(i,2)- obj.PointCloudOffset(2), ClusterCoordinates(i,3)- obj.PointCloudOffset(3), num2str(i), 'FontSize', 6 );
                                plot3(ClusterCoordinates(i,1) - obj.PointCloudOffset(1), ClusterCoordinates(i,2)- obj.PointCloudOffset(2), ClusterCoordinates(i,3)- obj.PointCloudOffset(3),'ro');
                            end
                    end
                else
                    % if it has not been previously occupied, we detect if
                    % it is newly occupied
                    obj.ChessBoardCellArray(j).DetectedAsOccupied = 0;
                    obj.ChessBoardCellArray(j).DetectedAsNewlyOccupied = 0;
                    for i = 1:numClusters
                        dis = sqrt( (ClusterCoordinates(i,1) - obj.PointCloudOffset(1) - obj.ChessBoardCellArray(j).Xpos)^2 + (ClusterCoordinates(i,2) - obj.PointCloudOffset(2) - obj.ChessBoardCellArray(j).Ypos)^2);
                            if (dis <= obj.ChessBoardCellSize/2)
                                obj.ChessBoardCellArray(j).DetectedAsNewlyOccupied = 1;
                            end
                    end
                end
            end
            
            hold off;
            a=5;
            
        end
        
        
        function coordinates = GetSquareCenter(obj, i,j)
            x_center = (i-1)*obj.ChessBoardCellSize + (obj.ChessBoardCellSize / 2) - 4*obj.ChessBoardCellSize;
            y_center = (j-1)*obj.ChessBoardCellSize + (obj.ChessBoardCellSize / 2) - 4*obj.ChessBoardCellSize;
            z_center = 0;
            coordinates = [x_center, y_center, z_center];
        end 
        
        function Initialize(obj)
            %set pawns
            for i = 1:8
                obj.ChessBoardCellArray((i-1)*8+2).CurrentPiece = 1;
                obj.ChessBoardCellArray((i-1)*8+2).ColorOfPiece = 'w';
            end
            for i = 1:8
                obj.ChessBoardCellArray((i-1)*8+7).CurrentPiece = 1;
                obj.ChessBoardCellArray((i-1)*8+7).ColorOfPiece = 'b';
            end
            
            %set rooks
            obj.ChessBoardCellArray(1).CurrentPiece = 4;
                obj.ChessBoardCellArray(1).ColorOfPiece = 'w';
            obj.ChessBoardCellArray(57).CurrentPiece = 4;
                obj.ChessBoardCellArray(57).ColorOfPiece = 'w';
            obj.ChessBoardCellArray(8).CurrentPiece = 4;
                obj.ChessBoardCellArray(8).ColorOfPiece = 'b';
            obj.ChessBoardCellArray(64).CurrentPiece = 4;
                obj.ChessBoardCellArray(64).ColorOfPiece = 'b';
            
            %set bishops
            obj.ChessBoardCellArray(17).CurrentPiece = 3;
                obj.ChessBoardCellArray(17).ColorOfPiece = 'w';
            obj.ChessBoardCellArray(41).CurrentPiece = 3;
                obj.ChessBoardCellArray(41).ColorOfPiece = 'w';
            obj.ChessBoardCellArray(24).CurrentPiece = 3;
                obj.ChessBoardCellArray(24).ColorOfPiece = 'b';
            obj.ChessBoardCellArray(48).CurrentPiece = 3;
                obj.ChessBoardCellArray(48).ColorOfPiece = 'b';
            
            %set knights
            obj.ChessBoardCellArray(9).CurrentPiece = 2;
                obj.ChessBoardCellArray(9).ColorOfPiece = 'w';
            obj.ChessBoardCellArray(49).CurrentPiece = 2;
                obj.ChessBoardCellArray(49).ColorOfPiece = 'w';
            obj.ChessBoardCellArray(16).CurrentPiece = 2;
                obj.ChessBoardCellArray(16).ColorOfPiece = 'b';
            obj.ChessBoardCellArray(56).CurrentPiece = 2;
                obj.ChessBoardCellArray(56).ColorOfPiece = 'b';
            
            %set king
            obj.ChessBoardCellArray(25).CurrentPiece = 6;
                obj.ChessBoardCellArray(25).ColorOfPiece = 'b';
            obj.ChessBoardCellArray(32).CurrentPiece = 6;
                obj.ChessBoardCellArray(32).ColorOfPiece = 'w';
            
            %set queen
            obj.ChessBoardCellArray(33).CurrentPiece = 5;
                obj.ChessBoardCellArray(33).ColorOfPiece = 'b';
            obj.ChessBoardCellArray(40).CurrentPiece = 5;
                obj.ChessBoardCellArray(40).ColorOfPiece = 'w';
            
            obj.debug = 5;
        end
        
        function chessMatrix = DisplayBoard(obj)
            positionAt = 1;
            chessMatrix = zeros(8,8);
            for i = 1:8
                for j = 1:8
                    piece = obj.ChessBoardCellArray(positionAt).CurrentPiece;
                    color = obj.ChessBoardCellArray(positionAt).ColorOfPiece;
                    obj.MyCBDisp.DisplayFigure(i, j, piece, color)
                    
                    positionAt = positionAt + 1;
%                     piece = obj.ChessBoardCellArray(positionAt).CurrentPiece;
                     chessMatrix(i,j) = piece
                end
            end
        end
    end
end