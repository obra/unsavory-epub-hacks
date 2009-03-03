use strict;
use warnings;

package App::Kindleize::Model::LibraryItem;
use Jifty::DBI::Schema;
use File::Temp qw/tempfile/;
use Digest::SHA1 qw/sha1_hex/;
use LWPx::ParanoidAgent;


sub since {'0.0.3'};

use App::Kindleize::Record schema {

    column account => references App::Kindleize::Model::Account;
    column url => type is 'text';
    column raw => type is 'blob';
    column title => type is 'text';
    column sha1 => type is 'text';
    column content_type => type is 'text';

};

# Your model-specific methods go here.
sub create {
    my $self = shift;
    my %args = (@_);
    if ($args{url}) {
        my $ua = LWPx::ParanoidAgent->new;
        $ua->timeout(30);
    my $response = $ua->get($args{url});
    if ($response->is_success) {
        $args{raw} = $response->decoded_content;
        $args{'content_type'} = $response->headers->header('Content-Type');
       }

    }
    if ($args{raw}) {
        $args{sha1} = sha1_hex($args{raw});
    $self->make_mobi(\%args);
    } 

    $self->SUPER::create(%args);

}

sub make_mobi {
    my $self = shift;
    my  $args = shift;
    my ($fh,$name) = tempfile();
    print $fh ($args->{raw} || "<html><body>No content found - server error?</body>") || die "$! - raw data into file";
    close $fh || die "close failed $!";
    warn "My name is ".$name;
    warn "My sha is ".$args->{sha1};
    App::Kindleize::html_to_mobi($name => '/tmp/mobi/'.$args->{sha1}.".mobi");

}    
1;

