package MIDI::LiveCode::Notation;

use v5.40;

use Carp qw/ carp croak /;

use aliased 'MIDI::LiveCode::Config' => 'cfg';

use parent 'Exporter';
our @EXPORT_OK =
our @EXPORT = qw/
    duration_ppqn
    duration
    pitch
/;

# in quarter notes
my $duration_names = {
    bn => 8,
    wn => 4,
    hn => 2,
    qn => 1,
    en => 1/2,
    sn => 1/4,
    tn => 1/8,
    tr => 2/3,
};

my $pitch_nums->@{ 0..127 } = map {
    my $octave = $_;
    map {
        "$_$octave"
    } qw/ c cs d ds e f fs g gs a as b /
} -2..8;

my $pitch_names = { reverse $pitch_nums->%* };

my $note_aliases = {
    'c#' => 'cs',
    'df' => 'cs',
    'db' => 'cs',
    'd#' => 'ds',
    'ef' => 'ds',
    'eb' => 'ds',
    'f#' => 'fs',
    'gf' => 'fs',
    'gb' => 'fs',
    'g#' => 'gs',
    'af' => 'gs',
    'ab' => 'gs',
    'a#' => 'as',
    'bf' => 'as',
    'bb' => 'as',
};

# in quarter notes
sub duration( $duration ) {
    my $msg = "Apparent zero duration : $duration";
    $duration =~ s/_//g;
    my $dotted = $duration =~ s/^[d.]//;
    $duration = $duration_names->{ $duration } // $duration * 4;
    $duration += $duration / 2 if $dotted;
    carp $msg unless $duration;
    $duration;
}

sub duration_ppqn( $duration ) {
    duration( $duration ) * cgf->ppqn;
}

sub pitch( $note ) {
    $pitch_names->{ $note } // $note;
}

