use v5.38;
use experimental qw/ class /;

class MIDI::LiveCode::Watcher {

    use IO::Async::Loop;
    use IO::Async::File;
    use MIDI::LiveCode::Sequencer;

    use aliased 'MIDI::LiveCode::Config' => 'cfg';

    field $modules :param;
    field $loop = IO::Async::Loop->new;
    field $files;
    field $channels;

    method go {
        $loop->run;
    }

    method _handle( $channel, $msg ) {
        use DDP; p $msg;
    }

    ADJUST {
        for my $module ( $modules->@* ) {
            my $fn = $module =~ s{::}{/}gr . '.pm';
            require $fn;
            my $full_fn = $INC{ $fn };
            my $sequencer = MIDI::LiveCode::Sequencer->for_module( $module );
            $files->{ $module } = IO::Async::File->new(
                filename => $full_fn,
                on_stat_changed => sub {
                    $sequencer->reload;
                },
                interval => cfg->file_interval
            );
            $loop->add( $files->{$module} );
        }
    }

};
