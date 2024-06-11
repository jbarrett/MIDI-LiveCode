package MIDI::LiveCode::Config;

use v5.40;

use meta;
no warnings 'meta::experimental';

my $config = {
    channel   => 1,
    midi_bits => 7,
    ppqn      => 24,
    trigger   => 10, #ms
    velocity  => 127,
};

my $meta = meta::get_this_package;

for my $val ( keys $config->%* ) {
    $meta->add_symbol(
        "&$val" => sub {
            $config->{ $val } = $_[1] if $_[1];
            $config->{ $val };
        }
    )
}
