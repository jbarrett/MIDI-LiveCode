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
    cc
    channel
    every
    note
    offset
    probability
    quantize
    trigger
    velocity
/;

my @specials = qw/
    finalize
    midi_bits
    random
/;

my $aliases = { qw/
    bpm       tempo
    delay     offset
    finalise  finalize
    port      device
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

sub finalize {
    _events->finalize;
}

for my ( $alias, $orig ) ( $aliases->%* ) {
    $meta->add_symbol(
        "&$alias" => $meta->get_symbol( "&$orig" )->reference
    );
}
