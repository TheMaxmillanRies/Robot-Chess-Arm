load('./ptcloud.mat');

figure(1);
plot3(Xr2,Yr2,Zr2,'.');
xlabel('X');
ylabel('Y');
zlabel('Z');


indexClipped = find((Yr2<0.30)&(Xr2<0.12) & (Xr2>-0.12) & (Zr2<0.12)& (Zr2>-0.12));

clippedX = Xr2(indexClipped);
clippedY = Yr2(indexClipped);
clippedZ = Zr2(indexClipped);

figure(2);
plot3(clippedX, clippedY, clippedZ,'.');
xlabel('X');
ylabel('Y');
zlabel('Z');

loc1 = [clippedX(:), clippedY(:), clippedZ(:)];
ptCloud = pointCloud(loc1);

figure(3);
pcshow(ptCloud)

% % filter the point cloud
% ptCloud = pcdenoise(ptCloud, 'Threshold', 1.5 );


minDistance = 0.0075;
[labels,numClusters] = pcsegdist(ptCloud,minDistance);

labelColorIndex = labels+1;
pcshow(ptCloud.Location,labelColorIndex)
colormap([hsv(numClusters+1);[0 0 0]])
title('Point Cloud Clusters')

coors = zeros(numClusters, 3);

for i=1:numClusters
    index = find(labels == i);
    clusterCoors = loc1(index,:);
    coors(i,:) = mean(clusterCoors);
    hold on;
    plot3(coors(i,1), coors(i,2), coors(i,3), 'O','LineWidth',3);
    hold off;
end


%fuse clusters, which are below each other,
%so fuse clusters with a x-z distance that is too small
for i=2:numClusters
    for j = i:numClusters
        if (i ~= j)
            %calculate the distance between the two clusters
            dis = sqrt( (coors(i,1) - coors(j,1))^2 + (coors(i,3) - coors(j,3))^2);
            %fuse clusters, which are blow each other
            if (dis<0.02)
                index = find(labels == j);
                labels(index) = i;
            end
        end
    end
end

counter = 1;
dummy_label = zeros(numel(labels),1);
for i=1:numClusters
    index = find(labels == i);
    if ( numel(index) > 1)
        dummy_label(index) = counter;
        counter=counter + 1;
    end
end
labels = dummy_label;
numClusters = counter-1;



figure(4);

labelColorIndex = labels+1;
pcshow(ptCloud.Location,labelColorIndex)
colormap([hsv(numClusters+1);[0 0 0]])
title('filtered Point Cloud Clusters')
for i=1:numClusters
    index = find(labels == i);
    clusterCoors = loc1(index,:);
    coors(i,:) = mean(clusterCoors);
    hold on;
    plot3(coors(i,1), coors(i,2), coors(i,3), 'O','LineWidth',3);
    hold off;
end
