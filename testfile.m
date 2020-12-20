MyRGBProcessor = RGBProcessing();

BeforeImage = MyRGBProcessor.LoadImage('ptCloud_before_move.mat');
AfterImage = MyRGBProcessor.LoadImage('ptCloud_after_move.mat');

BeforeImage = MyRGBProcessor.FitCropAndBW(BeforeImage);
AfterImage = MyRGBProcessor.FitCropAndBW(AfterImage);

MyRGBProcessor.ProcessImages(BeforeImage, AfterImage);

MyRGBProcessor.getMax();

MyRGBProcessor.max1
MyRGBProcessor.max1Index
MyRGBProcessor.max2
MyRGBProcessor.max2Index