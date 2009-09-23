package Text::ePub::HTMLContent;
use Mouse;
has filename => ( isa => 'Str', is => 'rw' );
has raw_content => ( isa => 'Str|Undef', is => 'rw', default => '' );
has epub => ( isa => 'Text::ePub::Parser', weak_ref => 1, is => 'rw' );

sub load {
    my $self = shift;
    my $file = $self->filename;
    $file =~ s|^/+||;
    $self->raw_content( $self->epub->zip->contents( $file ) ) || die "Couldn't load file ".$file;

}

sub content_utf8 {
    my $self = shift;
                 use Encode::Guess;
                use Encode;
             # perhaps ok
    my $data = $self->raw_content();

             my $decoder = guess_encoding($data, 'cp1252', 'latin1');
             # definitely NOT ok
        if  (ref($decoder) ) {
            my $utf8 = $decoder->decode($data);
            return $utf8;
        } elsif ($data =~ /^“/m && $data =~ /”$/m) {
                 # if the ebook has ""ed paragraphs in latin 1, it's probably in latin 1.
                return decode('utf-8',$data);
            } else {
            return $data;
            }
}

no Mouse;

1;
