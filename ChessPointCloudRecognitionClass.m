classdef ChessPointCloudRecognitionClass
   
   properties
      X;
      Y;
      Z;
      ChessBoard;
   end
   
   methods
      function obj = ChessPointCloudRecognitionClass(X,Y,Z)
         obj.X = X;
         obj.Y = Y;
         obj.Z = Z;
         
         obj.ChessBoard = ChessBoard();
         
         obj.ChessBoard = obj.ChessBoard.Initialize();
      end
      function update(new_X,new_Y,new_Z)
          new_X;
          new_Y;
          new_Z;
      end
   end
end