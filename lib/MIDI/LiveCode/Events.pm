use v5.40;
use experimental qw/ class /;
my $instances;

class MIDI::LiveCode::Events :isa( MIDI::LiveCode::Decor ) {

    use again;
    use Carp qw/ carp croak /;

    field $module :param;
    field $events :reader;

    sub for_module( $class, $module ) {
        $instances->{ $module } //=
        $class->new( module => $module );
    }

    method push_events :SkipIfFinalized ( $name, $event ) {
        #croak "Event $name already exists"
        carp "Redefining $name!"
            if exists $events->{ events }->{ $name };
        $events->{ events }->{ $name } = $event;
    }

    method push_config :SkipIfFinalized ( $cfg, $val ) {
        $events->{ config }->{ $cfg } = $val;
    }

    # Need to rationalise : local vs global configs.
    # Some things are not intechangeable ...
    method config( $cfg = undef ) {
        $cfg
            ? $events->{ config }->{ $cfg }
            : $events->{ config }
    }

    method finalize :SkipIfFinalized {
        $events->{ finalized } = true;
    }

    method music {
        $events->{ events };
    }

    method init {
        $events = {};
    }

    method reload {
        $self->init;
        require_again $module;
    }
}
