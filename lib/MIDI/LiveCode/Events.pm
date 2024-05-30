use v5.38;
use experimental qw/ class /;
my $instances;

class MIDI::LiveCode::Events {

    use Carp qw/ carp croak verbose /;

    field $module :param;
    field $events;

    sub for_module( $class, $module ) {
        $instances->{ $module } //
        $class->new( module => $module );
    }

    method push_events( $name, $event ) {
        croak "Event $name already exists"
            if exists $events->{ events }->{ $name };
        $events->{ events }->{ $name } = $event;
    }

    method push_config( $cfg, $val ) {
        $events->{ config }->{ $cfg } = $val;
    }

    method config ( $cfg ) {
        $cfg
            ? $events->{ config }->{ $cfg }
            : $events->{ config }
    }

    method finalize {
        croak "Events have already been finalized!"
            if $events->{ finalized };
        $events->{ finalized } = 1;
    }

    method init {
        $events = {};
    }

    method events { $events }

    ADJUST {
        $instances->{ $module } = $self;
    }
}
