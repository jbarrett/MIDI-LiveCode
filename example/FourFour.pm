package FourFourV2;

use MIDI::LiveCode;

device qr/loopmidi|timidity/i;
tempo 120;
midi_bits 7;

loop bar => kick =>
#stop
every qn,
dur trigger,
channel 10,
note c3,
vel 127;

loop snare =>
every hn,
offset qn,
dur trigger,
channel 10,
note cs3,
vel random 110 => 127;

loop hat => return
every sn,
channel 10,
dur trigger,
note d3,
vel sub {
    state @vels = 70, 80, 60, 90;
    push @vels, shift @vels;
    $vels[-1]
};

finalize;
