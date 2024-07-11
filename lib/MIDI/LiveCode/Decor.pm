package MIDI::LiveCode::Decor;

use v5.40;
use experimental qw/ builtin class /;

use meta;
no warnings 'meta::experimental';

class MIDI::LiveCode::Decor { # Looking forward to roles :)

    use Attribute::Handlers;

    # Calls any callbacks passed in params
    sub CallBacker :ATTR(CODE) ( $package, $symbol, $referent, @blahblah ) {
        my $meta = meta::get_package( $package );
        my $sym = '&' . *{$symbol}{NAME};
        $meta->remove_symbol( $sym );
        $meta->add_symbol(
            $sym => method {
                my @params = map {
                    no warnings 'uninitialized';
                    builtin::reftype $_ eq 'CODE'
                        ? $_->()
                        : $_
                } @_;
                $referent->( $self, @params );
            }
        );
    }

    # Skips method if $event->{finalized}
    sub SkipIfFinalized :ATTR(CODE) ( $package, $symbol, $referent, @blahblah ) {
        my $meta = meta::get_package( $package );
        my $sym = '&' . *{$symbol}{NAME};
        $meta->remove_symbol( $sym );
        $meta->add_symbol(
            $sym => method {
                return if $self->events->{finalized};
                $referent->( $self, @_ );
            }
        );
    }

}
