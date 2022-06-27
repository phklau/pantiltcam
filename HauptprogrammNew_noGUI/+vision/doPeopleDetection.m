function [image_out,person_detected,xbox_filt,ybox_filt] = ...
    doPeopleDetection(detector,img,xact,yact, def_pos, VISION_TYP)
%
%   FUNCTION [image_out,person_detected,xact,yact] = ...
%       doPeopleDetection(cam,xact,yact)
%
%   Prof. Dr.-Ing. Tobias Weiser
%   HS Kempten
%   20.05.2022
%
%% Konstanten
% Gewichtung der Bilderkennung: 
% Use-Case Projekt: Nur eine Person
% Manchmal werden aber im Hintergrund weitere Objekte erkannt:
%   'none': Erster Eintrag wird gewählt (später wird gefiltert)
%   'mean': Mittelwert aus allen Einträgen
XY_WEIGHT = 'none';

% Gewichtung der Ausgabewerte
% 'none': Keine Filterung
% 'mean': Mittelwertfilterung
OUTPUT_FILT = 'mean';
%OUTPUT_FILT = 'hold';


% Konstanten für die Offsetverschiebung der detektierten Objektposition
% Bezug: links oben, normiert
% Typ CascadeDetection
SC_X_CASCADE = 0.5;
SC_Y_CASCADE = 1;
% Typ PeopleACF
SC_X_ACF = 0.5;
% Brust liegt auf etwa 75% der Körpergröße
SC_Y_ACF = 1 - 0.75;


%% Bild holen
% Referenzwerte
[img_height,img_width,~] = size(img);
% Erkennung - bboxes =
switch VISION_TYP
    case 'cascade'
        bbox = step(detector, img);
    case 'people'
        [bbox, ~] = detector(img);
    case 'peopleACF'
        [bbox, ~] = detect(detector,img);
end
% Boxen dem Bild hinzufügen - Debugging
% im2 = insertObjectAnnotation(img, 'rectangle', bbox, 'person', 'Color', 'red');

%% Filterung der Werte
% Schieberegister
xact(2:end) = xact(1:end-1);
yact(2:end) = yact(1:end-1);

if isempty(bbox)
    xact(1) = def_pos;
    yact(1) = def_pos;
    person_detected = 0;
    
else
%     bbox
    %% Offset-Verschiebung je nach Art der Bildverarbeitung
    % Zielpunkt: Brust
    % Das Positionsergebnis aus der Bilderkennung wird um einen
    % spezifischen Offset verschoben.
    switch VISION_TYP
        case 'cascade'
            % Hier wird eher das Gesicht erkannt -> Mitte der unteren Kante
            bbox_off(:,1) = (bbox(1,1)) + bbox(1,3) * SC_X_CASCADE;
            % Komplette Höhe hinzu
            bbox_off(:,2) = (bbox(1,2)) + bbox(1,4) * SC_Y_CASCADE;
        case {'people','peopleACF'}
            % Hier wird der komplette Körper erkannt - 75% der Körperhöhe
            bbox_off(:,1) = (bbox(1,1)) + bbox(1,3) * SC_X_ACF;
            bbox_off(:,2) = (bbox(1,2)) + bbox(1,4) * SC_Y_ACF;
    end
    
    %% Mittelwertbildung der möglichen Boxen
    % Da der Mittelpunkt der Person ausgegeben werden soll muss die Breite
    % mit beachtet werden. bbox hat folgenden Aufbau, Bezug linke obere
    % Ecke des Bilds:
    %   [x y Breite Höhe]
    switch XY_WEIGHT
        case 'none'
            % Ansatz 0 - Erster Eintrag
            x_box_mean = bbox_off(1,1);
            y_box_mean = bbox_off(1,2);
        case 'mean'
            % Ansatz 1 - Mittelwert: Bezug links oben
            x_box_mean = mean(bbox_off(:,1));
            y_box_mean = mean(bbox_off(:,2));
    end
    % Offset auf links unten
    xbox = x_box_mean;
    ybox = img_height - y_box_mean;
    
    % Ausgabe
    xact(1) = xbox/img_width;
    yact(1) = ybox/img_width;
    
    person_detected = 1;
end

%% Filterung der Werte

% Var 1: Aktuellster Wert
switch OUTPUT_FILT
    case 'none'
        xbox_filt = xact(1);
        ybox_filt = yact(1);
    case 'mean'
        % Var 2: Mittelwert
        xbox_filt = mean(xact);
        ybox_filt = mean(yact);
    case 'hold'
           %Hold Filter 
       if person_detected
           xbox_filt = xact(1);
           ybox_filt = yact(1);
       else
           xbox_filt = xact(2);
           ybox_filt = yact(2);
       end
%     case 'LowPass'
%             xbox_filt = 
%             y(i) = y(i-2)*(6*Tf/T-1)/A +y(i-1)*(8*Tf/T-2)/A + u(i-2) + 2*u(i-1) + u(i);
%             y(i) = y(i)/kor;
end

%% Rechteck einfügen - Bezug links oben
x_actbox = xbox_filt - 0.05*img_height;
y_actbox = img_height - ybox_filt - 0.05*img_height;
br_actbox = 0.1*img_height;
actbox = [x_actbox,y_actbox,br_actbox,br_actbox];
image_out = insertShape(img,'Rectangle',actbox);
image_out = insertObjectAnnotation(image_out, 'rectangle', bbox, 'person', 'Color', 'red');