% Load data containing pointcloud object
load("PTC_Starting_Pos.mat"); 

pointcloud_processor = PointCloudAnalysis("point_cloud", My_pointCloud);
pointcloud_processor.PlotPointCloud(1);
pointcloud_processor.ClipPointCloud([0.2, -0.125], [0.175, -0.175], [0.40625, 0]);
pointcloud_processor.PlotPointCloud(2);

%Get Min and Max Of a Pawn Piece
%MaxPawnPoint = max(PawnData,[], 1);
%MinPawnPoint = min(PawnData,[], 1);

%lineX = zeros(1, 351);
%lineX(:) = 0.045;
%lineY = -0.175:0.001:0.175;
%lineZ = zeros(1, 351);
%lineZ(:) = 0.4;
% % line = [X; Y];
%line = zeros(351, 3);
%line(:,1) = lineX;
%line(:,2) = lineY;
%line(:,3) = lineZ;

%Points = [Points; line];


for i = 0.2:-0.0375:-0.125
    
    % define line values over 3D space
    lineX = zeros(1, 351);
    lineX(:) = i;
    lineY = -0.175:0.001:0.175;
    lineZ = zeros(1, 351);
    lineZ(:) = 0.4;
    
    line = zeros(351, 3);
    line(:,1) = lineX;
    line(:,2) = lineY;
    line(:,3) = lineZ;
    
    pointcloud_processor.X = [pointcloud_processor.X; lineX'];
    pointcloud_processor.Y = [pointcloud_processor.Y; lineY'];
    pointcloud_processor.Z = [pointcloud_processor.Z; lineZ'];
end

pointcloud_processor.CreatePointCloud();
pointcloud_processor.PlotPointCloud(3);


[xq, yq] = meshgrid(0.08:0.001:0.1, -0.02:0.001:0.005);
vq = griddata(PawnData(:,1), PawnData(:,2), PawnData(:,3), xq, yq);

figure(5);
mesh(xq, yq, vq);
hold on
plot3(PawnData(:,1), PawnData(:,2), PawnData(:,3), 'o');

figure(4);
PawnPointCloud = pointCloud(PawnData);
pcshow(PawnPointCloud);
xlabel('X');
ylabel('Y');
zlabel('Z');




