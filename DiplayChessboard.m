classdef DiplayChessboard < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        im_wKing, alpha_wKing;
        im_bKing, alpha_bKing ;
        im_wBishop, alpha_wBishop;
        im_bBishop, alpha_bBishop;
        im_wRook, alpha_wRook;
        im_bRook, alpha_bRook;
        im_wQueen, alpha_wQueen;
        im_bQueen, alpha_bQueen;
        im_wKnight, alpha_wKnight;
        im_bKnight, alpha_bKnight;
        im_wPawn, alpha_wPawn;
        im_bPawn, alpha_bPawn;
        picW = 55*1.2;
        picH = 110*1.2;
        im_Chessboard;
        fieldsize = 140;
        
        viewport

    end
    
    methods
        function obj = DiplayChessboard(viewport)
            [obj.im_wKing, map, obj.alpha_wKing] = imread('wKing.png');
            [obj.im_bKing, map, obj.alpha_bKing] = imread('bKing.png');
            [obj.im_wBishop, map, obj.alpha_wBishop] = imread('wBishop.png');
            [obj.im_bBishop, map, obj.alpha_bBishop] = imread('bBishop.png');
            [obj.im_wRook, map, obj.alpha_wRook] = imread('wTurret.png');
            [obj.im_bRook, map, obj.alpha_bRook] = imread('bTurret.png');
            [obj.im_wQueen, map, obj.alpha_wQueen] = imread('wQueen.png');
            [obj.im_bQueen, map, obj.alpha_bQueen] = imread('bQueen.png');
            [obj.im_wKnight, map, obj.alpha_wKnight] = imread('wKnight.png');
            [obj.im_bKnight, map, obj.alpha_bKnight] = imread('bKnight.png');
            [obj.im_wPawn, map, obj.alpha_wPawn] = imread('wPawn.png');
            [obj.im_bPawn, map, obj.alpha_bPawn] = imread('bPawn.png');
            obj.viewport = viewport;
        end
        
        function RefreshBoard(obj)
            MyCheckerboard = checkerboard(obj.fieldsize);
            obj.im_Chessboard = (MyCheckerboard > 0.5);
            imshow( obj.im_Chessboard, 'Parent', obj.viewport);
        end
        
        function DisplayFigure(obj, posx, posy, type, color)
            X1 = ((posx-1)*obj.fieldsize+obj.fieldsize/2-obj.picW/2);
            X2 = ((posx-1)*obj.fieldsize+obj.fieldsize/2+obj.picW/2);
            Y1 = ((posy-1)*obj.fieldsize+obj.fieldsize/2-obj.picH/2); 
            Y2 = ((posy-1)*obj.fieldsize+obj.fieldsize/2+obj.picH/2);
            

            hold(obj.viewport, 'on')
            % diplay pawns
            if (type == 1)
                if strcmp(color, 'w')
                    image(obj.viewport, obj.im_wPawn, 'AlphaData', obj.alpha_wPawn, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                else
                    image(obj.viewport, obj.im_bPawn, 'AlphaData', obj.alpha_bPawn, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                end
            end
            %display knights
            if (type == 2)
                if strcmp(color, 'w')
                    image(obj.viewport, obj.im_wKnight, 'AlphaData', obj.alpha_wKnight, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                else
                    image(obj.viewport, obj.im_bKnight, 'AlphaData', obj.alpha_bKnight, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                end
            end
             % diplay Bishops
            if (type == 3)
                if strcmp(color, 'w')
                    image(obj.viewport, obj.im_wBishop, 'AlphaData', obj.alpha_wBishop, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                else
                    image(obj.viewport, obj.im_bBishop, 'AlphaData', obj.alpha_bBishop, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                end
            end
            % diplay Rooks
            if (type == 4)
                if strcmp(color, 'w')
                    image(obj.viewport, obj.im_wRook, 'AlphaData', obj.alpha_wRook, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                else
                    image(obj.viewport, obj.im_bRook, 'AlphaData', obj.alpha_bRook, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                end
            end
            % diplay Queens
            if (type == 5)
                if strcmp(color, 'w')
                    image(obj.viewport, obj.im_wQueen, 'AlphaData', obj.alpha_wQueen, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                else
                    image(obj.viewport, obj.im_bQueen, 'AlphaData', obj.alpha_bQueen, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                end
            end
            % diplay Kings
            if (type == 6)
                if strcmp(color, 'w')
                    image(obj.viewport, obj.im_wKing, 'AlphaData', obj.alpha_wKing, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                else
                    image(obj.viewport, obj.im_bKing, 'AlphaData', obj.alpha_bKing, 'XData', [ X1 X2 ], 'YData', [Y1 Y2]);
                end
            end
            hold(obj.viewport, 'on')
            
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        

    end
end

