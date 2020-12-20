load("PTC_VeryTightGrouping.mat");

point_cloud_processor = PointCloudAnalysis("point_cloud", My_pointCloud);
point_cloud_processor.Calibrate();
point_cloud_processor.PlotCurrentPointCloud(1);

point_cloud_processor.SegmentationProcessing();
point_cloud_processor.ClusterProcessing();