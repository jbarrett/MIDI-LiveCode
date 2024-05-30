package MIDI::LiveCode::DSL;

use v5.38;
use experimental qw/ defer for_list /;

my @config = qw/
    tempo
    signature
    device
/;

my @events = qw/
    loop
    oneshot
/;

my @parameters = qw/
    quantize
    offset
    every
    channel
    trigger
    note
    cc
    velocity
    probability
/;

my @specials = qw/
    midi_bits
    random
    finalize
    init
/;

my $aliases = { qw/
    finalise  finalize
    quantise  quantize
    quant     quantize
    delay     offset
    bpm       tempo
    port      device
    repeat    every
    time      signature
    vel       velocity
    prob      probability
/ };

use meta;
no warnings 'meta::experimental';
my $meta = meta::get_this_package;

use Carp qw/ croak /;
use MIDI::LiveCode::Events;

use parent 'Exporter';
our @EXPORT_OK = our @EXPORT = (
    @config,
    @events,
    @parameters,
    @specials,
    keys $aliases->%*
);

sub _events {
    MIDI::LiveCode::Events->for_module( scalar caller(2) );
}

my $event;
sub _current_event {
    my $caller = (caller(1))[3] =~ s/.*://gr;
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

for my $ev ( @events ) {
    $meta->add_symbol(
        "&$ev" => sub ( $name, $cb ) {
            defer { undef $event; }
            $event = {};
            $cb->();
            _events->push_events( $name, [ $ev => $event ] );
        }
    )
}

for my $param ( @parameters ) {
    $meta->add_symbol(
        "&$param" => sub( $value = 1 ) {
            _current_event->{ $param } = $value;
        }
    )
}

sub random( $low, $hi ) {
    _current_event;
    $low += 0; $hi += 0;
    "rand( $hi - $low ) + $low"
}

sub midi_bits( $bits ) {
    if ( $event ) {
        return $event->{ midi_bits } = $bits;
    }
    _events->push_config( midi_bits => $bits );
}

sub finalize :prototype() {
    _events->finalize;
}

sub init {
    _events->init;
}

for my ( $alias, $orig ) ( $aliases->%* ) {
    $meta->add_symbol(
        "&$alias" => $meta->get_symbol( "&$orig" )->reference
    );
}

#BEGIN {
#    _events->init;
#}
