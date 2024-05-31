package FourFour;

use MIDI::LiveCode;

device qr/wavetable|timidity/i;
tempo 120;
midi_bits 7;

loop kick => sub {
    every 'qn';
    trigger;
    channel 10;
    note 'c5';
    vel 127;
};

loop snare => sub {
    every 'hn';
    offset 'qn';
    trigger;
    channel 10;
    note 'c#5';
    vel random 110 => 127;
};

loop hat => sub {
    every 'sn';
    trigger;
    channel 10;
    note 'd5';
    vel random 80 => 127;
};

finalize;
