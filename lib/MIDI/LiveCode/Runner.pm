use v5.38;
use experimental qw/ class try /;

my $singleton;

class MIDI::LiveCode::Runner {

    use again;
    use IO::Async::Loop;

    field $channel :param;
    field $module :param;
    field $loop = IO::Async::Loop->new;

    method go {
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 1 + rand(),
            on_tick => sub {
                $channel->send( \$$ );
            },
        );
        $loop->add( $timer->start );
        $loop->run;
    }

    method reload {
        try {
            require_again $module;
        }
        catch ( $e ) {
            warn $e;
        }
    }

    sub instance { $singleton }
    ADJUST {
        $singleton = $self;
        $SIG{USR1} = sub { $singleton->reload };
    }
};
