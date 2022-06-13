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
% Kamera, Arduino.Objekte,...
Initialisierung;

% Ihre Initialisierung


%% Endlosschleife
while 1
    %% Bilderkennung
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
    
    %
    %% Ausgänge setzen
    % Bitte hier die Ausgänge für die Servomotoren setzen
    
    %    
    %% Bild im Player aktualisieren
    videoPlayer(out_img)
    pause(DT);
end