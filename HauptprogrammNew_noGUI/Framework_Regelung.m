function Framework_Regelung(MOUNTING)
%   
%   FUNCTION FRAMEWORK_REGELUNG(MOUNTING)
%
%   Eingang: MOUNTING: Orientierung der Montage: 0 Boden, 180: Decke
%
%   Framework zur Implementierung der Folgeregelung
%
%   Prof. Dr.-Ing. Tobias Weiser
%   HS Kempten
%   20.05.2022
%
%% Initialisierung
% Kamera, Arduino.Objekte,...
Initialisierung;

%Arduino
if ~exist('a', 'var')
    a = arduino('COM6','Nano33IoT');
end
    pan=servo(a,'D2');       
    tilt=servo(a,'D3');
% set the servos to middle position at startup
ti_mid = 0.35;
pan_mid=0.5;
writePosition(pan, pan_mid);
writePosition(tilt, ti_mid);
%Fehler und Ausgangsarrays
e_pan = zeros(3,1);
u_pan = zeros(3,1);
u_pan(:,1) = pan_mid;
e_tilt = zeros(2,1);
u_tilt = zeros(2,1);
u_tilt(:,1) = ti_mid;
y_pan = zeros(3,1);
y_tilt = zeros(3,1);
y_pan(:,1) = DEF_POS;
y_tilt(:,1) = DEF_POS;
%Reglerparameter abhängig von Abtastzeit
[ki_pan, kp_pan] = getControllerParams('pan', DT);
[ki_tilt, kp_tilt] = getControllerParams('tilt', DT);
%kp_pan = 0.5;
%kp_tilt = 0.25;
ki_pan= ki_pan*2; %ToDO: ki richtig bestimmen -> erhöht "Dynamik"
%ki_tilt = 1;

lastValid = DEF_POS;
%% Stabilisation
% ToDo:Mehrere Durchläufe ohne Regelung für richtige Werte in Arrays

%% Endlosschleife
% preview(cam)

while 1
    %% Bilderkennung
    if TEST == 0
        act_img = getsnapshot(vidobj);
        tic;
        [out_img,is_detected,x_Filt,y_Filt] = vision.doPeopleDetection(detector,act_img,xact,yact,DEF_POS,VISION_TYP);
        T_CV = toc
%         x_Filt = 0;
%         y_Filt = 0;
%         out_img = act_img;
    else
        act_img = imread('Mann2.jpg');
        [out_img,is_detected,x_Filt,y_Filt] = vision.doPeopleDetection(detector,act_img,xact,yact,DEF_POS,VISION_TYP);
    end
%    %Hold Filter Test
%    if is_detected
%        lastValid = x_Filt;
%    else
%        x_Filt = lastValid;
%    end
    % Aktuelle Position
    y_pan(1) = x_Filt
    y_tilt(1) = 1-y_Filt %ToDo: Richtig Montage
    
    %% Drehung des Bildes abhängig von der Aufstellung
    switch MOUNTING
        case 0
            % Do nothing
%             out_img = imrotate(out_img,0);
        case 180
            out_img = imrotate(out_img,180);
    end
    
    %% Regelgesetz
    % Bitte Differenzengleichung des Reglers hier implementieren
     % Pan-Regler:
        %Fehler
        e_pan(2) = e_pan(1);
        e_pan(1) = DEF_POS - y_pan(1);
        u_pan(2) = u_pan(1);
        
        %Ausgangswert durch Differenzengleichung berechnen(PI)
        %u_pan_unSaturation = u_pan(2) + (kp_pan+0.5*ki_pan*DT)*e_pan(1) + (0.5*ki_pan*DT-kp_pan)*e_pan(2);
        %PI 2DOF
        integralPart = DT*ki_pan*0.5*(e_pan(1)+e_pan(2));
        propPart = kp_pan*(y_pan(2) - y_pan(1));
        %Saturation
        u_pan_unSaturation = u_pan(2) +integralPart + propPart;
        u_pan(1) = min(1, (max(0, u_pan_unSaturation)));
    
    % Tilt-Regler(PI):
        %Fehler
        e_tilt(2) = e_tilt(1);
        e_tilt(1) = DEF_POS - y_tilt(1); 
        u_tilt(2) = u_tilt(1);
        %Ausgangswert durch Differenzengleichung berechnen
        %u_tilt_unSaturation = u_pan(2) + (kp_tilt+0.5*ki_tilt*DT)*e_tilt(1) + (0.5*ki_tilt*DT-kp_tilt)*e_tilt(2);
        %PI 2DOF
        integralPart = DT*ki_tilt*0.5*(e_tilt(1)+e_tilt(2));
        propPart = kp_tilt*(y_tilt(2)-y_tilt(1));
        %Saturation
        u_tilt_unSaturation = u_tilt(2) +integralPart + propPart;
        u_tilt(1) = min(1, max(0,u_tilt_unSaturation));

        y_pan(2) = y_pan(1);
        y_tilt(2) = y_tilt(1);
    %
    %% Ausgänge setzen
    % Bitte hier die Ausgänge für die Servomotoren setzen
        %Ausgabe nur für Einschätzung der Reglerfunktion, kann später weg
        is_detected
        xact(2)
        yact(2)
        e_tilt
        e_pan
        u_tilt
        u_pan
        writePosition(pan, u_pan(1));
        writePosition(tilt, u_tilt(1));

    %    
    %% Bild im Player aktualisieren
    videoPlayer(out_img)
    pauseTime = DT-T_CV;
    if pauseTime < 0
        pauseTime = 0;
    end
    pause(pauseTime);
end