package MIDI::LiveCode::Notation;

use v5.40;

use Carp qw/ carp croak /;
use Scalar::Util qw/ looks_like_number /;

use aliased 'MIDI::LiveCode::Config' => 'cfg';

use parent 'Exporter';
our @EXPORT_OK =
our @EXPORT = qw/
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
    triplet => 2/3,
    trigger => 1/64,
};
sub duration_names{ $duration_names }

my $note_names = [ qw/ c cs d ds e f fs g gs a as b / ];
sub note_names { $note_names }

my $pitch_nums->@{ 0..127 } = map {
    my $octave = $_;
    map {
        "$_$octave"
    } $note_names->@*
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
sub note_aliases { $note_aliases }

# in quarter notes
sub duration( $duration, $n, $d ) {
    my ( $count, $dur ) = $duration =~ /([0-9]+)?\s*([.a-z]+)/i;
    return cfg->trigger if $duration eq 'trigger';
    my $dotted = $duration =~ s/^[d.]//;
    $count //= 1;
    my $qn = ( $dur =~ /^bar/i )
        ? $count * $n * ( 4 / $d )
        : $count * $duration_names->{ lc $dur };
    $qn += $qn / 2 if $dotted;
    carp "Apparent zero duration: $duration" unless $qn;
    $qn;
}

sub pitch( $note ) {
    return $note if looks_like_number( $note );
    my ( $midc ) = cfg->middle_c =~ /C([0-9])/i;
    my $offset = 3 - $midc;
    my ( $name, $num ) = $note =~ /([a-z#]+)([0-9])/i;
    $num += $offset;
    $name = lc $name;
    $name = $note_aliases->{ $name } if $note_aliases->{ $name };
    $pitch_names->{ "$name$num" };
}

