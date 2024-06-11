use v5.40;
use experimental qw/ class /;
my $instances;

class MIDI::LiveCode::Scheduler {

    use IO::Async::Loop;
    use IO::Async::Timer::Periodic;

    use aliased 'MIDI::LiveCode::Config' => 'cfg';

    field $loop = IO::Async::Loop->new;
    field $tempo :reader :param //= 120;
    field $barcounts = [ 2, 3, 5, 7 ];
    field $beatlen;
    field $pulselen :reader;
    field $pulse = 0;
    field $beat = 0;
    field $sequencers;
    field $timer;

    sub for_tempo( $class, $tempo ) {
        $instances->{ $tempo } //=
        $class->new( tempo => $tempo );
    }

    method add_sequencer( $seq ) {
        $sequencers->{ $seq->module } = $seq;
        return $self;
    }

    method enqueue_sequencer( $seq ) {
        # hmm
    }

    method remove_sequencer( $seq ) {
        delete $sequencers->{ $seq->module };
    }

    ADJUST {
        $pulselen = 60 / ( $tempo * cfg->ppqn );

        $timer = IO::Async::Timer::Periodic->new(
            interval => $pulselen,
            reschedule => 'hard',
            on_tick => sub {
                my $beats = { pulse => $pulse, beat => $beat };
                if ( $pulse == 0 ) {
                    $beats->{bars}->{ $_ }++ for
                        grep { ! $_ % $beat } $barcounts->@*;
                }
                $_->step( $beats ) for values $sequencers->%*;
                $pulse ++;
                if ( $pulse >= cfg->ppqn ) {
                    $pulse = 0;
                    $beat++;
                }
            }
        );
        $loop->add( $timer->start );
    }
}
