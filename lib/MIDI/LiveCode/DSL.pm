package MIDI::LiveCode::DSL;

use v5.38;
use experimental qw/ defer for_list /;

use Carp qw/ carp croak /;

my @config = qw/
    device
    signature
    tempo
    ppqn
    watch
/;

my @defines = qw/
    loop
    oneshot
/;

my @parameters = qw/
    cc
    channel
    every
    note
    offset
    probability
    quantize
    swing
    trigger
    velocity
/;

my @specials = qw/
    copy
    finalize
    midi_bits
    random
/;

my $aliases = { qw/
    bpm       tempo
    delay     offset
    finalise  finalize
    pitch     note
    port      device
    ppq       ppqn
    prob      probability
    quantise  quantize
    quant     quantize
    repeat    every
    time      signature
    vel       velocity
/ };

use meta;
no warnings 'meta::experimental';
my $meta = meta::get_this_package;

use Carp qw/ croak carp /;
use MIDI::LiveCode::Events;

use parent 'Exporter';
our @EXPORT_OK = our @EXPORT = (
    @config,
    @defines,
    @parameters,
    @specials,
    keys $aliases->%*
);

sub _events {
    MIDI::LiveCode::Events->for_module( scalar caller(1) );
}

my $event;
sub _current_event {
    my $caller = (caller(0))[3] =~ s/.*://gr;
    croak "$caller called outside event definition" unless $event;
    return $event;
}

for my $cfg ( @config ) {
    $meta->add_symbol(
        "&$cfg" => sub( $val ) {
            _events->push_config( $cfg => $val );
        }
    )
}

for my $def ( @defines ) {
    $meta->add_symbol(
        "&$def" => sub ( $name, $cb ) {
            defer { undef $event; }
            $event = {};
            $cb->();
            _events->push_events( $name, [ $def => $event ] );
        }
    )
}

for my $param ( @parameters ) {
    $meta->add_symbol(
        "&$param" => sub( $value = 1 ) {
            croak "'$param' called outside event definition" unless $event;
            $event->{ $param } = $value;
        }
    )
}

sub random( $low, $hi ) {
    croak "'random' called outside event definition" unless $event;
    "random( $low, $hi )";
}

sub midi_bits( $bits ) {
    if ( $event ) {
        return $event->{ midi_bits } = $bits;
    }
    _events->push_config( midi_bits => $bits );
}

sub finalize {
    _events->finalize;
}

for my ( $alias, $orig ) ( $aliases->%* ) {
    $meta->add_symbol(
        "&$alias" => $meta->get_symbol( "&$orig" )->reference
    );
}
