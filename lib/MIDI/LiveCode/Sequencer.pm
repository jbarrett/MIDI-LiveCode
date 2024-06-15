use v5.40;
use experimental qw/ class builtin /;
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
    field $scheduler :reader;
    field $tempo = 120;
    field $prevtempo;
    field $bar;
    field $barnote;
    field $steps;
    field $module :reader :param;
    field $events :reader;
    field $device;
    field $numerator = 4;
    field $denominator = 4;
    field $snap = 0.005; # to nearest ppqn
    field @futures;

    sub for_module( $class, $module ) {
        $instances->{ $module } //=
        $class->new( module => $module );
    }

    method device( $port ) {
        return;
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

        my $step_ppqn = int $offset;
        my $delay = $self->duration_secs( $offset - int $offset );
        my $beat = int $step_ppqn / cfg->ppqn;
        # TODO: definable loop length
        while ( $beat < $numerator ) {
            push $steps->{ "$beat.$step_ppqn" }->@*, async sub {
                await Future::IO->sleep( $delay ) if $delay;
                $device->note_on( $channel, $note, $velocity );
                await Future::IO->sleep( $duration );
                $device->note_off( $channel, $note );
            };
            $step_ppqn += $every;
            $beat = int $step_ppqn / cfg->ppqn;
        }
        use DDP; p $steps;
        die;
    }

    method configure( $cfg ) {

    }

    method unroll {
        $self->configure( $events->config );
        for my ( $name, $event ) ( $events->music->%* ) {
            my $type = $event->[0];
            my $parameters = $event->[1];
            use DDP; p $name; p $type; p $parameters;
            #next unless $self->can( $event );
            #$self->$event( $parameters );
        }
    }

    method reload {
        try {
            $events->reload;
            $self->unroll;
        }
        catch ( $e ) {
            warn $e;
        }
    }

    method step( $beats ) {
        my $beat = $beats->{ beat } % $numerator;
        my $pulse = $beats->{ pulse };
        #say "$beat . " . $beats->{ pulse };
        my $key = sprintf '%s.%s', $beat, $beats->{ pulse };
        for my $step ( $steps->{ $key }->@* ) {
            my $res = $step->();
            push @futures, $res if $res isa 'Future';
        }
    }

    method time_signature( $sig ) {
        ( $numerator, $denominator ) = split '/', $sig;
        $barnote = $denominator / 4; # quarter notes
    }

    ADJUST {
        #$tempo = $events->{ tempo } if $events->{ tempo };
        #$prevtempo = $tempo;
        $events = MIDI::LiveCode::Events->for_module( $module );
        $scheduler = MIDI::LiveCode::Scheduler
            ->for_tempo( $tempo )
            ->add_sequencer( $self );
        builtin::weaken $scheduler;
        $self->reload;
    }
}
