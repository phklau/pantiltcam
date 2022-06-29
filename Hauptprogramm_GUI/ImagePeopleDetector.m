classdef ImagePeopleDetector < handle
    %Klasse für Personenerkennung im Bild
    % evtl für jeweilige Typen vererben? Oder benutzen wir sowieso nur die
    % eine Art von Objekterkennung?
    
    properties (Access = private)
        Detector
        VisionType
        filterType = 'hold';
        %Eingangswerte für Filter
        Xact_raw 
        Yact_raw
        %Ausgangswerte von Filter
        Xact_filter
        Yact_filter
        defPos_pan = 0.5;
        defPos_tilt = 0.5; 
        filtLength = 2; % mind. 3 für LoPass, mind 4 für FIR
    end

    properties (Constant)
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
        
        % Konstanten für die Offsetverschiebung der detektierten Objektposition
        % Bezug: links oben, normiert
        % Typ CascadeDetection
        SC_X_CASCADE = 0.5;
        SC_Y_CASCADE = 1;
        % Typ PeopleACF
        SC_X_ACF = 0.5;
        % Brust liegt auf etwa 75% der Körpergröße
        SC_Y_ACF = 1 - 0.75;
    end
    
    methods (Access = public)
        function obj = ImagePeopleDetector(visionType, filterType)
            %Konstruktor
            obj.VisionType = visionType;
            switch visionType
                % Erkennt Gesichter/Oberkörper gut: Rückgabe ist eher das Gesicht
                case 'cascade'
                    obj.Detector = vision.CascadeObjectDetector(...
                        'ClassificationModel', 'UpperBody');
                case 'people'
                    % Erkennt Oberkörper
                    obj.Detector = vision.PeopleDetector(...
                        'ClassificationModel', 'UprightPeople_96x48');
                case 'peopleACF'
                    % ACF-Algorithmus, erkennt ganze Personen oder Oberkörper
                    obj.Detector = peopleDetectorACF;
            end
            %Filter Initalisieren
            switch filterType
                case 'LowPass'
                    obj.filtLength = 3;
                case 'FIR'
                    obj.filtLength = 4;
            end
            obj.filterType = filterType;
            obj.Xact_raw = zeros(obj.filtLength, 1);
            obj.Yact_raw = zeros(obj.filtLength, 1);
            obj.Xact_raw(:,1) = obj.defPos_pan;
            obj.Yact_raw(:,1) = obj.defPos_tilt;
            obj.Xact_filter = zeros(obj.filtLength, 1);
            obj.Yact_filter = zeros(obj.filtLength, 1);
            obj.Xact_filter(:,1) = obj.defPos_pan;
            obj.Yact_filter(:,1) = obj.defPos_tilt;
        end
        
        function [image_out,person_detected, xact_filt, yact_filt] = ...
            doPeopleDetection(obj,img)
            %Bilderkennung ausführen
            %% Bild holen
            % Referenzwerte
            [img_height,img_width,~] = size(img);
            % Erkennung - bboxes =
            switch obj.VisionType
                case 'cascade'
                    bbox = step(obj.Detector, img);
                case 'people'
                    [bbox, ~] = obj.Detector(img);
                case 'peopleACF'
                    [bbox, ~] = detect(obj.Detector,img);
            end
            %% Filterung der Werte
            % Schieberegister
            obj.Xact_raw(2:end) = obj.Xact_raw(1:end-1);
            obj.Yact_raw(2:end) = obj.Yact_raw(1:end-1);
            obj.Xact_filter(2:end) = obj.Xact_filter(1:end-1);
            obj.Yact_filter(2:end) = obj.Yact_filter(1:end-1);
            
            if isempty(bbox) %Falls keine Person erkannt
                %obj.Xact_raw(1) = 0.5;
                obj.Xact_raw(1) = obj.Xact_raw(2);
                %obj.Yact_raw(1) = 0.5;
                obj.Yact_raw(1) = obj.Yact_raw(2);
                person_detected = 0; 
            else %Falls doch
                %% Offset-Verschiebung je nach Art der Bildverarbeitung
                % Zielpunkt: Brust
                % Das Positionsergebnis aus der Bilderkennung wird um einen
                % spezifischen Offset verschoben.
                switch obj.VisionType
                    case 'cascade'
                        % Hier wird eher das Gesicht erkannt -> Mitte der unteren Kante
                        bbox_off(:,1) = (bbox(1,1)) + bbox(1,3) * obj.SC_X_CASCADE;
                        % Komplette Höhe hinzu
                        bbox_off(:,2) = (bbox(1,2)) + bbox(1,4) * obj.SC_Y_CASCADE;
                    case {'people','peopleACF'}
                        % Hier wird der komplette Körper erkannt - 75% der Körperhöhe
                        bbox_off(:,1) = (bbox(1,1)) + bbox(1,3) * obj.SC_X_ACF;
                        bbox_off(:,2) = (bbox(1,2)) + bbox(1,4) * obj.SC_Y_ACF;
                end
                
                %% Mittelwertbildung der möglichen Boxen
                % Da der Mittelpunkt der Person ausgegeben werden soll muss die Breite
                % mit beachtet werden. bbox hat folgenden Aufbau, Bezug linke obere
                % Ecke des Bilds:
                %   [x y Breite Höhe]
                switch obj.XY_WEIGHT
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
                % Normierung
                obj.Xact_raw(1) = xbox / img_width;
                obj.Yact_raw(1) = ybox / img_height;
                person_detected = 1;
            end
            %% Filterung der Werte
            switch obj.filterType
                case 'none'
                    xact_filt = obj.Xact_raw(1);
                    yact_filt = obj.YactYact_raw(1);
                case 'mean'
                    xact_filt = mean(obj.Xact_raw);
                    yact_filt = mean(obj.Yact_raw);
                case 'hold'
                   if person_detected
                       xact_filt = obj.Xact_raw(1);
                       yact_filt = obj.Yact_raw(1);
                   else
                       xact_filt = obj.Xact_raw(2);
                       yact_filt = obj.Yact_raw(2);
                   end
                case 'LowPass'
                    obj.Xact_filter(1) = obj.Xact_filter(3)*0.1919 + obj.Xact_filter(2)*0.2442 + obj.Xact_raw(3) + obj.Xact_raw(2) + obj.Xact_raw(1);
                    obj.Xact_filter(1) = obj.Xact_filter(1)/3.5; %Gainkorrektur
                    xact_filt = obj.Xact_filter(1);
                    obj.Yact_filter(1) = obj.Yact_filter(3)*0.1919 + obj.Yact_filter(2)*0.2442 + obj.Yact_raw(3) + obj.Yact_raw(2) + obj.Yact_raw(1);
                    obj.Yact_filter(1) = obj.Yact_filter(1)/3.5; %Gainkorrektur
                    yact_filt = obj.Yact_filter(1);
                case 'FIR'
                    obj.Xact_filter(1) = 0.28399418430782136*obj.Xact_raw(2)+0.574008723538268*obj.Xact_raw(3)+0.28399418430782136*obj.Xact_raw(4);
                    xact_filt = obj.Xact_filter(1);
                    obj.Yact_filter(1) = 0.28399418430782136*obj.Yact_raw(2)+0.574008723538268*obj.Yact_raw(3)+0.28399418430782136*obj.Yact_raw(4);
                    yact_filt = obj.Yact_filter(1);
            end
            %% Rechteck einfügen - Bezug links oben
            x_actbox = xact_filt - 0.05*img_height;
            y_actbox = img_height - yact_filt - 0.05*img_height;
            br_actbox = 0.1*img_height;
            actbox = [x_actbox,y_actbox,br_actbox,br_actbox];
            image_out = insertShape(img,'Rectangle',actbox);
            image_out = insertObjectAnnotation(image_out, 'rectangle', bbox, 'person', 'Color', 'red');
        end
        
        function obj = updateDefValues(obj, xDef, yDef)
        %Neuer Reglersollwert
            obj.defPos_pan = xDef;
            obj.defPos_tilt = yDef;
        end
    end
end
