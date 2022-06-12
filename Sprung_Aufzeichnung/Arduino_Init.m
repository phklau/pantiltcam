% Arduino-Objekte
if ~exist('a')
    % instantiate arduino object
    a = arduino('COM6','Nano33IoT')
    % attach servos for tilt and rotation at your prefered pins
    global spin;
    global tilt;
    spin=servo(a,'D2');       
    tilt=servo(a,'D3');
end

% set the servos to middle position at startup (depends on you hardware)
ti_mid=0.35;
sp_mid=0.5;
writePosition(tilt, ti_mid)
writePosition(spin,sp_mid);

