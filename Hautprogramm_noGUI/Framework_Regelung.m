function Framework_Regelung(MOUNTING)
%   
%   FUNCTION FRAMEWORK_REGELUNG(MOUNTING)
%
%   Eingang: MOUNTING: Orientierung der Montage: 0 Boden, 180: Decke
%
%   Framework zur Implementierung der Folgeregelung
%
%   Status: PeopleACF funktioniert gut.
%       Folgen auf Grund des Mittelwertfilter mit DT = 0.1 etwas träge. ==>
%       DT = 0.05
%       Ggf. anderen Filter einsetzen!
%
%   Prof. Dr.-Ing. Tobias Weiser
%   HS Kempten
%   20.05.2022
%
%% Initialisierung
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
e_pan = zeros(2,1);
u_pan = zeros(2,1);
u_pan(1) = DEF_POS;
e_tilt = zeros(2,1);
u_tilt = zeros(2,1);
u_pan(1) = DEF_POS;
%Reglerparameter abhängig von Abtastzeit
[ki_pan, kp_pan] = getControllerParams('pan', DT);
[ki_tilt, kp_tilt] = getControllerParams('tilt', DT);
%% Endlosschleife
while 1
    %% Bilderkennung
    tic;
    if TEST == 0
        act_img = snapshot(cam);
        [out_img,is_detected,x_Filt,y_Filt] = vision.doPeopleDetection(detector,act_img,xact,yact,DEF_POS,VISION_TYP);
    else
        act_img = imread('Mann2.jpg');
        [out_img,is_detected,x_Filt,y_Filt] = vision.doPeopleDetection(detector,act_img,xact,yact,DEF_POS,VISION_TYP);
    end
    % Aktuelle Position - erster Wert
    xact = x_Filt(1);
    yact = y_Filt(1);
    
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
        e_pan(1) = DEF_POS - xact;
        u_pan(2) = u_pan(1);
        %Ausgangswert durch Differenzengleichung berechnen
        %TODO: Saturation!
        u_pan(1) = u_pan(2) + (kp_pan+0.5*ki_pan*DT)*e_pan(1) + (0.5*ki_pan*DT-kp_pan)*e_pan(2);
    
    % Tilt-Regler:
        %Fehler
        e_tilt(2) = e_tilt(1);
        e_tilt(1) = DEF_POS - yact;
        u_tilt(2) = u_tilt(1);
        %Ausgangswert durch Differenzengleichung berechnen
        %TODO: Saturation!
        u_tilt(1) = u_pan(2) + (kp_tilt+0.5*ki_tilt*DT)*e_tilt(1) + (0.5*ki_tilt*DT-kp_tilt)*e_tilt(2);

    %% Ausgänge setzen
    % Bitte hier die Ausgänge für die Servomotoren setzen
    %Ausgabe nur für Einschätzung der Reglerfunktion, kann später weg
        e_tilt
        e_pan
        u_tilt
        u_pan
        writePosition(pan, u_pan(1));
        writePosition(tilt, u_tilt(1));
    %    
    %% Bild im Player aktualisieren
    videoPlayer(out_img)
    t = toc
    if t < DT
       pause(DT-t);
    end
end