use v5.40;
use experimental qw/ class /;

class MIDI::LiveCode::Device {

    use MIDI::RtMidi::FFI::Device;
    use IO::Async::Loop;
    use IO::Async::Routine;
    use IO::Async::Channel;
    use Future::AsyncAwait;

    field $loop = IO::Async::Loop->new;
    field $cb :param = sub {};
    field $port :param;
    field $direction :param = 'out';
    field $device;
    field $routine;
    field $channel;

    async method watch {
        while ( my $msg = await $channel->recv ) {
            $cb->( $msg );
        }
    }

    method note_on( $channel, $note, $velocity ) {
        $device->send_event( note_on => $channel - 1, $note, $velocity )
    }

    method note_off( $channel, $note ) {
        $device->send_event( note_off => $channel - 1, $note, 0 )
    }

    ADJUST {
        $direction eq 'in' && goto RTN;

        $device = MIDI::RtMidi::Device->new(
            type => $direction,
        );
        $device->open_virtual_port( 'midi-livecode-' . $$ )
            unless $^O eq 'MSWin32';
        $device->open_port_by_name( $port );

        return;


RTN:
        $channel = IO::Async::Channel->new;
        $routine = IO::Async::Routine->new(
            channels_out => [ $channel ],
            code => sub {
                $device = MIDI::RtMidi::FFI::Device->new( type => $direction );
                $device->open_port_by_name( $port );
                $device->set_callback(
                    sub( $ts, $msg, $data ) {
                        $channel->send( [ $ts => $device->decode_msg( $msg ) ] );
                    }
                );
                sleep;
            }
        );
        $loop->add( $routine );
        watch->retain;
    }
}
