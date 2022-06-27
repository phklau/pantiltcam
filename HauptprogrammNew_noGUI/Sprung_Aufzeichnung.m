function Sprung_Aufzeichnung(MOUNTING,step_start,step_width,servo_name)
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
if ~exist('a', 'var')
    a = arduino('COM6','Nano33IoT');
end
pan=servo(a,'D2');       
tilt=servo(a,'D3');
writePosition(pan, 0.5);
writePosition(tilt, 0.4);
sampels = 40; % sampels*DT = Laufzeit
stabi = 200;
sprung = zeros(sampels, 2);
switch servo_name
    case 'tilt'
        servoSel = tilt;
    case 'pan'
        servoSel = pan;
end

%% Bilderkennung stabilisieren lassen
for i = 1:stabi
     act_img = getsnapshot(vidobj);
     tic;
    [out_img,is_detected,x_Filt,y_Filt] = vision.doPeopleDetection(detector,act_img,xact,yact,DEF_POS,VISION_TYP);
    T_CV = toc
    xact = x_Filt(1)
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
    if i > stabi/2
        writePosition(servoSel,step_start);
        stepStartValues(i-stabi/2) = xact;
    end
    %% Bild im Player aktualisieren
    videoPlayer(out_img)
    pauseTime = DT-T_CV;
    if pauseTime < 0
        pauseTime = 0;
    end
    pause(pauseTime);
end
writePosition(servoSel,step_start);
%% Sprung aufzeichnen
disp("Sprung gestartet")
stepStartValues
stepStartValues(stepStartValues(:,1)==0.5,:)=[];
sprung(1,1) = 0; 
sprung(1,2) = mean(stepStartValues);        
globTime = tic;
writePosition(servoSel,step_start+step_width);
% preview(cam)
for i = 2:sampels
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
        sprung(i,2) = x_Filt;        %x_Position in zweite

    %% Bild im Player aktualisieren
    videoPlayer(out_img)
    pauseTime = DT-T_CV;
    if pauseTime < 0
        pauseTime = 0;
    end
    pause(pauseTime);
end

%Daten sichern in CSV File
%sprung(sprung(:,1)==0.5,:)=[]; %Daten bereinigen um nichterkannte Bilder
sprung
Dateiname = append('sprung_',servo_name,'_',datestr(now,'HHMMSS'),'_',string(step_width),'.txt');
writematrix(sprung, Dateiname);
%%Plotten
figure;
plot(sprung(:,1),sprung(:,2))