classdef ChessBoardCell
    properties
        %Definition of the pieces in the same manner as the Chess Engine
        %Pawn = 1;
        %Knight = 2;
        %Bishop = 3;
        %Rook = 4;
        %Queen = 5;
        %King = 6;
        
        %Current square piece ID, 0 if none
        CurrentPiece = 0;
        ColorOfPiece
        
        %Coordinates of a cell
        X;
        Y;
        Z;
    end
    
    methods
        function obj = ChessBoardCell(coordinates)
            obj.X = coordinates(1);
            obj.Y = coordinates(2);
            obj.Z = coordinates(3);
        end
   end
end