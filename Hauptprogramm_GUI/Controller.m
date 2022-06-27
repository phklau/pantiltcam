classdef Controller < handle
    %Klasse für Regler
    
    properties (Access = public)
        e = zeros(3,1);   %Regelfehler
        u = zeros(3,1);  %Stellgröße
        y = zeros(3,1);  %Instgröße
        r = zeros(1,1);   %Sollgröße
        ki
        kp
        kd
        sampleTime
        type = 'PI';
    end
    
    methods (Access = public)
        function obj = Controller(type, K, T, sampleTime, servoMid)
            %Konstruktor -> Regelparmas initalisieren, Arrays beschreiben
            obj.type = type;
            obj.sampleTime = sampleTime;
            %get ControllerParams
            T_t = sampleTime;
            switch type
                case 'PI'
                obj.kp = (0.9/K)*(T/T_t);
                obj.ki = obj.kp/(3.33*T_t);
                obj.kd = 0;
                case 'PID'
                obj.kp = (1.2/K)*(T/T_t);
                obj.ki = obj.kp/(3.33*T_t);
                obj.kd = obj.kp*0.5*T_t;
            end    
            obj.u(:,1) = servoMid;
            %update DesPos
            obj.e(:,1) = 0;
            obj.y(:,1) = 0.5;
            obj.r(1) = 0.5;
        end
        
        function obj = getControllerParams(obj, K, T, T_t)
            %Auslegung nach Ziegler Nichols
            switch obj.type
                case 'PI'
                obj.kp = (0.9/K)*(T/T_t);
                obj.ki = obj.kp/(3.33*T_t);
                obj.kd = 0;
                case 'PID'
                obj.kp = (1.2/K)*(T/T_t);
                obj.ki = obj.kp/(3.33*T_t);
                obj.kd = obj.kp*0.5*T_t;
            end    
        end
        %Regelung
        function output = getOutput(obj,yNow)
            %vergangene Werte weiterschieben
            obj.e(2) = obj.e(1);
            obj.u(2) = obj.u(1);
            obj.y(2) = obj.y(1);
            %Neue Istgröße schreiben
            obj.y(1) = yNow;
            %Regelfehler berechnen
            obj.e(1) = obj.r(1) - obj.y(1);
            %Regelgesetz 2DOFPI (bisher nur PI)
            integralPart = obj.sampleTime*obj.ki*0.5*(obj.e(1)+obj.e(2));
            propPart = obj.kp*(obj.y(2) - obj.y(1));
            %Saturation
            u_pan_unSaturation = obj.u(2) +integralPart + propPart;
            u_pan_Saturation = min(1, (max(0, u_pan_unSaturation)));
            obj.u(1) = u_pan_Saturation;
            output = obj.u(1);
        end
        %Sollgröße aktualisieren
        function obj = updateDesOutput(obj, defPos)
            obj.e(:,1) = 0;
            obj.y(:,1) = defPos;
            obj.r(1) = defPos;
        end
        function obj = setParams(obj,param,type)
            switch type
                case 'ki'
                    obj.ki = param;
                case 'kp'
                    obj.kp = param;
            end
        end
    end
end

