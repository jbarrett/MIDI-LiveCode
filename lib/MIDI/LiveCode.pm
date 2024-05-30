package  MIDI::LiveCode;

use v5.38;

my @PRAGMAS  = qw/ utf8 /;
my @FEATURES = qw/ :5.38 /;
my @MODULES  = qw/ MIDI::LiveCode::DSL /;

use Import::Into;

sub import {
    my $caller = caller;
    feature->import::into( $caller, @FEATURES );
    $_->import::into( $caller ) for @PRAGMAS;
    $_->import::into( $caller ) for @MODULES;
    $caller->init;
}
