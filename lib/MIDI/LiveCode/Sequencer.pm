use v5.40;
use experimental qw/ class builtin for_list /;
my $instances;

class MIDI::LiveCode::Sequencer {

    use IO::Async::Loop;
    use Future::IO;
    use Future::AsyncAwait;

    use MIDI::LiveCode::Scheduler;
    use MIDI::LiveCode::Notation;
    use MIDI::LiveCode::Device;

    use aliased 'MIDI::LiveCode::Config' => 'cfg';

    field $loop = IO::Async::Loop->new;
    field $scheduler :param;
    field $tempo = 120;
    field $prevtempo;
    field $bar;
    field $steps;
    field $module :reader;
    field $events :param;
    field $device;
    field $numerator = 4;
    field $denominator = 4;
    field $snap = 0.005; # to nearest ppqn

    method device( $port ) {
        $device //= MIDI::LiveCode::Device->new(
            direction => 'out',
            port => $port,
        )
    }

    method duration_beats( $ppqn ) {
        int $ppqn / cfg->ppqn
    }

    method duration_secs( $duration ) {
        duration_ppqn( $duration ) * $scheduler->pulselen;
    }

    method loop( $parameters ) {
        my $every = duration_ppqn( $parameters->{ every } );
        my $offset = $parameters->{ offset }
            ? duration_ppqn( $parameters->{ offset } )
            : 0;
        my $channel = $parameters->{ channel } // cfg->channel;
        my $velocity = $parameters->{ velocity } // cfg->velocity;
        my $note = pitch( $parameters->{ note } );
        my $duration = cfg->trigger if $parameters->{ trigger };
        $duration = $self->duration_secs( $parameters->{ duration } )
            if $parameters->{ duration };

        my $step_ppqn = $offset * cfg->ppqn;
        my $beat = int $step_ppqn / cfg->ppqn;
        # TODO: definable loop length
        while ( $beat < $numerator ) {
            $steps->{ "$beat.$step_ppqn" } = async sub {
                # delay goes here
                $device->note_on( $channel, $note, $velocity );
                await Future::IO->sleep( $duration * cfg->ppqn );
                $device->note_off( $channel, $note );

            };
            $step_ppqn += $every;
            $beat = int $step_ppqn / cfg->ppqn;
        }

    }

    method unroll {
        for my ( $event, $parameters ) ( $events->%* ) {
            next unless $self->can( $event );
            $self->$event( $parameters );
        }
    }

    method update( $events ) {

    }

    method step( $beats ) {
        
    }

    ADJUST {
        #$tempo = $events->{ tempo } if $events->{ tempo };
        #$prevtempo = $tempo;
        $scheduler = MIDI::LiveCode::Scheduler
            ->for_tempo( $tempo )
            ->add_sequencer( $self );
        builtin::weaken $scheduler;
    }
}
