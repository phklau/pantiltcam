function Sprungantwort_Aufzeichnung(MOUNTING,step_start,step_width,servo_name)
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

sampels = 13; % sampels*DT = Laufzeit hier 8s
stabi = 50;
sprung = zeros(sampels, 2);
switch servo_name
    case 'tilt'
        servo = tilt;
    case 'spin'
        servo = spin;
end
writePosition(servo,step_start)
%Sprung auf Servo
%% Bilderkennung stabilisieren lassen
for i = 1:stabi
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
    videoPlayer(out_img)
    t = toc;
    if t <= DT
        pause(DT-t);
    end
end
%% Sprungantwort aufzeichnen
disp("Sprung gestartet")
globTime = tic;
writePosition(servo,step_start+step_width);
for i = 1:sampels
    %% Bilderkennung
    %tic;
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
    
   sprung(i,1) = toc(globTime); %Zeit in erste Spalte schreiben
   sprung(i,2) = y_Filt;        %x_Position in zweite

    %% Bild im Player aktualisieren
    videoPlayer(out_img)
    %t = toc;
    %if t <= DT
    %    pause(DT-t);
    %end
end
%Daten sichern in CSV File
sprung
Dateiname = append('sprung_',servo_name,'_',datestr(now,'HHMMSS'),'.txt');
writematrix(sprung, Dateiname);
%%Plotten
figure;
plot(sprung(:,1),sprung(:,2))