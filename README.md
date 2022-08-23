# Robot-Chess-Arm

Robotics side-project consisting of building and coding a robotic arm to play chess against a human opponent without the need of extra human labor (such as inputing moves or other). The code is made in Matlab and made use of several libraries such as the robotic toolbox of Peter Corke and the Intel RealSense SDK. 

The code is broken down into several sections, though currently messily put together.

### Motion Control

### Chess Board Detection
The chess board detection is a complicated ensemble of attempted techniques to recognize the state of the board. To do this, there are 2 kinds of datasets obtained, 1 RGB image from the board and 1 depth map from the Intel RealSense camera. In principle there are 2 schools of thought:

#### Single Shot Detection
The single shot detection is the harder of the two ideas to execute, as the goal is to infer the state of the board at any time instance t. The problem with this method is that it not only requires detecting the location of a piece, but also the type of piece it is. This is a very difficult task which is not perfectly done to this day. To do the detection, I have tried a simple neural net on the RGB images, which worked very well but started to fail due to lighting differences throught the course o a day. I also tried using the depth information as a point cloud to do some thresholding, but the pieces of my chess set were too similar and as such, things failed.

What I will eventually try to do is to finetune pointnet on my data after creating a proper dataset, to get an unbiased prediction with no dependency on lighting conditions.

#### Change-based Detection
Because of the lighting bias, I ended up going for a change-based detection mechanism, which, instead of predicting all the piece locations and types, I only detect the locations and use the previous board state to infer what has changed in the state of the game. I tried 2 algorithms which did not directly use traditional trained ML/DL algorithms, one based on segmentation and one based on clustering.
Since I know absolute positions within my chess board, I first tried segmenting each chess cell and detecting if a piece was present within. This method worked well, but failed when the pieces overlapped slightly into 2 cells, as the thresholds are not dynamic. 
Based on this failure, I opted for a k-means clustering based approach which worked very well, and had a 95% success rate detecting pieces, that even a human would have difficulty getting correct.

Either case, for normal chess playing with mild overlap of a piece over squares, everything worked and I could actually play a game of chess with the chess arm. Based on the 1 or 2 (if a piece is taken by the opponent) detected piece movements which occur between board states, the algorithm finds what has happened and can parse the new board state to the Stockfish AI.

### Chess AI
For the chess AI, the stockfish software was downloaded and a custom interface with the AI was created in matlab. To allow communication with the AI, the local board state which is stored using a combination of simple classes, is converted into Forsyth–Edwards Notation. This notation is used by stockfish, and is a notation which provides enough information so the next move can be played, even if no history is present.

