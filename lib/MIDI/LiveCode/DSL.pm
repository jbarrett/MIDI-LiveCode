package MIDI::LiveCode::DSL;

use v5.38;
use experimental qw/ defer for_list /;

use meta;
no warnings 'meta::experimental';
my $meta = meta::get_this_package;

use Carp qw/ croak carp /;
use MIDI::LiveCode::Events;

my @config = qw/
    device
    signature
    tempo
    ppqn
    watch
/;

my @defines = qw/
    loop
    lfo
    oneshot
/;

# For now (with defaults):
# loop repeats every( bar )
# tick repeats as many times as fits in a bar
# length / duration is for a note which is once per bar
# anything else can go into a ref
my @parameters = qw/
    cc
    channel
    duration
    tick
    note
    offset
    probability
    quantize
    swing
    velocity
/;

my @specials = qw/
    copy
    finalize
    midi_bits
    random
    stop
/;

my $aliases = { qw/
    align     quantize
    bpm       tempo
    delay     offset
    dur       duration
    every     tick
    finalise  finalize
    len       duration
    pitch     note
    port      device
    ppq       ppqn
    prob      probability
    quantise  quantize
    quant     quantize
    sig       signature
    trig      trigger
    trip      triplet
    tr        triplet
    time      signature
    vel       velocity
/ };

my $note_lengths;
my $note_names;
my $all_notes;
BEGIN {
    require MIDI::LiveCode::Notation;
    $note_lengths = [ keys MIDI::LiveCode::Notation->duration_names->%* ];
    $note_names = [ MIDI::LiveCode::Notation->note_names->@*,
                 grep { /^[a-z]+$/i } keys MIDI::LiveCode::Notation->note_aliases->%* ];

    $all_notes = {
        map {
            my $octave = $_;
            map {
                ( "$_$octave", "$_$octave" )
            } $note_names->@*
        } 0..10
    };
}

use parent 'Exporter';
our @EXPORT_OK = our @EXPORT = (
    @config,
    @defines,
    @parameters,
    @specials,
    $note_lengths->@*,
    keys $all_notes->%*,
    keys $aliases->%*
);

my $event;
my $caller;

sub import {
    $caller = caller;
    __PACKAGE__->export_to_level(1, @_);
}

sub _events {
    MIDI::LiveCode::Events->for_module( $caller );
}

for my $cfg ( @config ) {
    $meta->add_symbol(
        "&$cfg" => sub( $val ) {
            _events->push_config( $cfg => $val );
        }
    )
}

for my $param ( @parameters ) {
    $meta->add_symbol(
        "&$param" => sub( $value, $cb = sub {} ) {
            sub {
                carp "'$param' called outside event definition" unless $event;
                $event->{ $param } = $value;
                $cb->();
            }
        }
    )
}

sub stop {
    sub {};
}

sub random( $low, $hi ) {
    carp "'random' called outside event definition" unless $event;
    sub {
        int rand( $hi - $low + 1 ) + $low;
    }
}

sub midi_bits( $bits, $mode = 'await' ) {
    if ( $event ) {
        return $event->{ midi_bits } = $bits;
    }
    _events->push_config( midi_bits => $bits );
    _events->push_config( midi_mode => $mode );
}

sub finalize {
    _events->finalize;
}

sub _add_event {
    my ( $type, $dur, $name, $cb ) = ref $_[2] // '' eq 'CODE'
        ? ( $_[0], 'bar', @_[1..2] )
        : @_;
    defer { undef $event; }
    $event = {};
    $cb->();
    _events->push_events( $name, [ $dur, $type => $event ] );
}

for my $def ( @defines ) {
    $meta->add_symbol(
        "&$def" => sub {
            _add_event( $def, @_ )
        }
    )
}

for my $length ( $note_lengths->@* ) {
    $meta->add_symbol(
        "&$length" => sub { $length }
    );
};

use constant $all_notes;

for my ( $alias, $orig ) ( $aliases->%* ) {
    $meta->add_symbol(
        "&$alias" => $meta->get_symbol( "&$orig" )->reference
    );
}
