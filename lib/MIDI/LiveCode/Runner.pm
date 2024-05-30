use v5.38;
use experimental qw/ class try /;

class MIDI::LiveCode::Runner {

    use again;
    use IO::Async::Loop;
    use IO::Async::Signal;
    use MIDI::LiveCode::Events;

    field $channel :param;
    field $module :param;
    field $loop = IO::Async::Loop->new;

    method go {
        $self->reload;
        $loop->add( IO::Async::Signal->new(
            name => 'USR1',
            on_receipt => sub { $self->reload }
        ) );
        $loop->run;
    }

    method send_events {
        $channel->send (
            MIDI::LiveCode::Events->for_module( $module )->events
        );
    }

    method reload {
        try {
            require_again $module;
            $self->send_events;
        }
        catch ( $e ) {
            warn $e;
        }
    }
};
