package FourFour;

use MIDI::LiveCode;

tempo 120;
midi_bits 7;

loop kick => sub {
    every 'qn';
    trigger;
    channel 1;
    note 'c5';
    vel 127;
};

loop hat => sub {
    every 'sn';
    trigger;
    channel 1;
    note 'd5';
    vel random 80,  127;
};

finalize;
