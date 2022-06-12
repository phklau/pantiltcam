%   Skript zur Initialisierung
%
%   Prof. Dr.-Ing. Tobias Weiser
%   HS Kempten
%   20.05.2022
%
%% Testvariable ==> Nur Standbild (muss im gleichen Verzeichnis wie diese
% Datei liegen!)
TEST = 0;

%% Kamera
% Kamera - als globale Variable
% Alle Kameras mit 
%   webcamlist
% abfragen.
global cam;
cam = webcam(1);


%% Arduino-Objekte generieren / bzw. eigenes Skript mit den Objekten

%Arduino_Init;


%% Default-Werte
DEF_POS = 0.5; % Mitte des Bildschirms
% MOUNTING = 180; % Montage: 0°: Boden, 180°, Decke

% Abtastrate in s;
DT = 0.2;

% Laufzeitvariablen
is_detected_ini = 0; % Flag, ob jemand erkannt wurde oder nicht
person_detected = 0;


% Filterlänge Objekterkennung
N_FILT = 0;
% Filter initialisieren
xact = zeros(N_FILT,1);
yact = zeros(N_FILT,1);

% Bilderkennungsmethode - PeopleDetector mit Oberkörpererkennung
% Empfehlung: peopleACF - cascade
VISION_TYP = 'peopleACF';
switch VISION_TYP
    % Erkennt Gesichter/Oberkörper gut: Rückgabe ist eher das Gesicht
    case 'cascade'
        detector = vision.CascadeObjectDetector(...
            'ClassificationModel', 'UpperBody');
    case 'people'
        % Erkennt Oberkörper
        detector = vision.PeopleDetector(...
            'ClassificationModel', 'UprightPeople_96x48');
    case 'peopleACF'
        % ACF-Algorithmus, erkennt ganze Personen oder Oberkörper
        detector = peopleDetectorACF;
end

%% Kamera konfigurieren
% mit dem Befehl webcamlist können alle angeschlossenen Kameras erfasst werden.
% Die gewünschte Kamera kann durch Angabe der entsprechenden Nummer aus der
% Liste verwendet werden.
% Auswertung und Darstellung
shapeInserter = vision.ShapeInserter('BorderColor','White');
% Video-Player
videoPlayer = vision.VideoPlayer();

%% Test-Case
if TEST == 1
    % Bild laden
    im = imread('Mann2.jpg');
end
    