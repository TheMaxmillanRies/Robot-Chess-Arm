classdef ArmKinematics < handle
    % --------------------
    % |                  |         inverse kenmatics coordinate system (world coordinates) 
    % |                  |
    % |                  |            ^
    % |    chessboard    |            | +y
    % |                  |            |         0 = origin at the center of the robot
    % |                  |            |             up is +z
    % |                  |            o------->
    % --------------------                    +x
    %        /  \
    %       |    | robot location
    %        \__/
    % %  
    %                Ellbow to wrist distance
    %                        EtW = 227mm
    %                        
    %                   MMM RRR           MMM
    %                   MMM-RRR-----------MMM
    % distance joint    MMM RRR           MMM\  
    % axis o rot axis    /     rot            \   wrist to wrist roattion  WtWR = 15mm 
    % dja = 68.5mm      /      servo           \
    %                   \                      MM
    % desitance axis     \                     MM
    % shoulder to ellbow  \                      \
    % StE = 179mm          \                      \    wrist rotation to gripper tip WRtG = 107mm 
    %                       \
    %                        MMM
    %                        MMM
    %                        MMM
    %                         |    distance rotation base to acis should servo
    %                         |    RtS = 35mm
    %                        MMM
    %                        MMM
    %                        MMM
    properties
        EtW = 227;
        RtS = 25;
        StE = 179;
        WRtG = 107;
        WtWR = 15;
        dja = 68.5;
             
        L                 % this hilds the link chain instance describing the arm
        MyArm             % this is the arm object itself
        MyPosDevice       % this is the position in motor coordinates (i.e. in degrees of each motor axis)
        MyPosWorld       % this is the position in motor coordinates (i.e. in degrees of each motor axis)
        
        MyServo           % class with the low level motor drivers (in device coordinates only)
        overwatchPose
        suspendPose
    end
    
    methods
        function obj = ArmKinematics()
            % ============= Initialize the Link-Chain in Hardenberg-Levit notation to decribe our arm            
            % base plate rotation link, with offset to the shoulder servo
            L(1) = Revolute('d', obj.RtS, 'alpha', pi/2, 'offset', deg2rad(-90), 'qlim', [deg2rad(90) deg2rad(270)]);
            
            % shoulder servo link, which is mounted invered
            % carful, the phantomX has an L-shaped bracket as the upper arm and the rotation axis of the
            % ellbow servo is not aligened
            %
            % >>>>------- rotation axis of forearm
            % |26mm
            % |
            % x end of bracket
            % |                                         Therefore the default angle of the servo needs to be corrected
            % |36mm                                     offset = pi/2-atan(36/146)
            % |                146mm
            % X-------------------------------x shoulder servo
            % ellbow servo
            L(2) = Revolute('a', -obj.StE, 'offset', deg2rad(90), 'alpha', pi, 'qlim', [deg2rad(101.1) deg2rad(248.88)]);
            
            %ellbow servo link
            L(3) = Revolute('a', obj.dja, 'offset', deg2rad(0), 'alpha', -pi/2, 'qlim', [deg2rad(91.2) deg2rad(270)]);
            
            %forearm rotation link
            L(4) = Revolute('a', -10,'d', obj.EtW, 'alpha', pi/2, 'offset', deg2rad(-182), 'qlim', [deg2rad(19) deg2rad(345)]);
            
            % wrist link
            L(5) = Revolute('d', 0, 'a', 0, 'offset', deg2rad(180-153.3), 'alpha', pi/2, 'qlim', [deg2rad(43) deg2rad(219)]);
            
            %wrist rotation link
            L(6) = Revolute('d', obj.WRtG, 'alpha', pi/2, 'offset', deg2rad(180-150), 'qlim', [deg2rad(60) deg2rad(240)]);
            
            % create the robot
            obj.MyArm = SerialLink(L, 'name', 'Robby', 'manufacturer', 'Buuugsmashers ....');
            
            % init as meaningful starting values the rest position of the
            % robot
            obj.MyPosDevice  = [deg2rad(180) deg2rad(261.9) deg2rad(272.3) deg2rad(180) deg2rad(217) deg2rad(150) ];
            %Use inverse kinematics to update the world coordinates
            obj.MyPosWorld = obj.MyArm.fkine(obj.MyPosDevice);
            
            
            % priveledged poses for the joints
            obj.overwatchPose = [deg2rad(180) deg2rad(176) deg2rad(154.7) deg2rad(181.9) deg2rad(247.65) deg2rad(151) deg2rad(205)]        
            obj.suspendPose = [ deg2rad(180) deg2rad(262) deg2rad(272) deg2rad(180) deg2rad(157) deg2rad(150) deg2rad(204)]
   
        end
        
        function Close(obj)
            obj.MyServo.Close();
        end
        
        function StrobeLEDs(obj)
            for i=0:5
                pause('on');
                obj.MyServo.ToggleLED(1);
                pause(0.2);
                obj.MyServo.ToggleLED(0);
                pause(0.2);
            end
        end
        
        function StartUpRobot(obj)
           % init communication with the motors ======================================
            obj.MyServo = SixDOFDynamixelDriver();
            % ENABLE TORQUE ================================
            error = obj.MyServo.ToggleTorque(1);
            % SET DEFAULT SPEED ===============
            error = obj.MyServo.SetDefaultSpeed();
            % lift the gripper in order to prevent entanglements with the base rotation
            error = obj.MyServo.SetSingleGoalPosition(5, deg2rad(157), 1);
            pause(5);
        end
        
        function outputArg = PowerDownRobot(obj)
           % set the robot in parking position
            error = obj.MyServo.SetGoalPositionSyncMove(obj.suspendPose,1,1);
            % DISABLE TORQUE ================================
            error = obj.MyServo.ToggleTorque(0);
            
            
        end 
        
        function error = SuspendRobot(obj)
           % set the robot in parking position
            error = obj.MyServo.SetGoalPositionSyncMove(obj.suspendPose,1,1);
            % DISABLE TORQUE ================================
            error = obj.MyServo.ToggleTorque(0);
            
        end     
        
        function error = WakeUpFromSuspend(obj)
            % ENABLE TORQUE ================================
            error = obj.MyServo.ToggleTorque(1); 
        end 
      
        function error = SetOverwatch(obj)
            % move to overwatch position
            error = obj.MyServo.SetGoalPositionSyncMove(obj.overwatchPose,1,1);
        end
        
        function error = FetchAt3D(obj, x, y, z)
            
            %move the grabber over the position
            obj.MoveTo3D( x, y, 70);
            obj.MoveTo3D( x, y, z);
            obj.MyServo.CloseGrabber2();
            error = 0;
        end
        
        function error = PlaceAt3D(obj, x, y, z)
            
            %move the grabber over the position
            obj.MoveTo3D( x, y, 70);
            obj.MoveTo3D( x, y, z);
            obj.MyServo.OpenGrabber();
             error = 0;
        end
        
        function error = MoveTo3D(obj, x, y, z)
            %this method keeps the gripper vertical and approaches all
            %positions "from above"
            
            refpos=[deg2rad(180), deg2rad(212), deg2rad(225), deg2rad(180), deg2rad(227), deg2rad(150)];
            Tref = obj.MyArm.fkine(refpos);
            
            Tn = Tref;
            Tn(1,4)= x;
            Tn(2,4)= y;
            Tn(3,4)= z;
            
            % translate from world to device coordinates
            q = obj.MyArm.ikcon(Tn, obj.MyPosDevice);
            
            % use forwards kinetics to check if we can reach this position
            Tres = obj.MyArm.fkine(q);

            sum((Tn - Tres), 'all')
            
            obj.MyArm.plot( q );
            obj.MyServo.grabberOverride = 1;
            
            error = obj.MyServo.SetGoalPositionSyncMove(q,1,1);

        end
    end
end






















