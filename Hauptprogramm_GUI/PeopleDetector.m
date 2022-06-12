classdef PeopleDetector
    %Klasse für Personenerkennung im Bild
    % evtl für jeweilige Typen vererben? Oder benutzen wir sowieso nur die
    % eine Art von Objekterkennung?
    
    properties (Access = private)
        Detector
        VisionType
        FiltLength
        Xact
        Yact
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
        OUTPUT_FILT = 'mean';
        % Konstanten für die Offsetverschiebung der detektierten Objektposition
        % Bezug: links oben, normiert
        % Typ CascadeDetection
        SC_X_CASCADE = 0.5;
        SC_Y_CASCADE = 1;
        % Typ PeopleACF
        SC_X_ACF = 0.5;
        % Brust liegt auf etwa 75% der Körpergröße
        SC_Y_ACF = 1 - 0.75;
        %Rückgabewert, fall keine Person erkannt
        DEF_POS = 0.5;
    end
    
    methods (Access = public)
        function obj = PeopleDetector(visionType, filterLength)
            %Konstruktor
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
            obj.Xact = zeros(filterLength,1);
            obj.Yact = zeros(filterLength,1);
        end
        
        function [image_out,person_detected,xbox_filt,ybox_filt] = ...
            doPeopleDetection(img)
            %Bilderkennung ausführen
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
                
            
        end
    end
end

