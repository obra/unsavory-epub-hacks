package App::Kindleize::Dispatcher;
use Jifty::Dispatcher -base;
sub LWP::Debug::debug {}
sub LWP::Debug::trace {}
use LWPx::ParanoidAgent;
use File::Temp qw/tempfile/;
use Digest::SHA1;
use File::Spec;

        `mkdir /tmp/mobi`;
        `mkdir /tmp/epub`;

on qr'^/(index.html)?' => sub { show 'home' };

on qr'^/epub/(https?\://?.*)$' => run {
    my $url = $1;
    $url =~ s|:/|://|; # jifty removes repeated / - bug

        my $ua = LWPx::ParanoidAgent->new;
        $ua->timeout(30);
    warn "Fetching $url";
    my $response = $ua->get($url);
    warn "Fetched";
            my $sha1 = Digest::SHA1::sha1_hex($response->decoded_content);
    if ($response->is_success) {
        my $file = File::Spec->catfile("/tmp/epub/".$sha1);
        unless ( -e $file ) {
            open (my $fh, ">", $file);
            print $fh $response->decoded_content;
            close($fh);
        } 

        unless (File::Spec->catfile("/tmp/mobi/".$sha1.".epub")) {        mobify($file => $sha1)};

        redirect("/build-mobi/".$sha1.".mobi");
        last_rule;
   } else {
        redirect("/errors/could_not_fetch/$url");
    } 

};

on qr'/build-mobi/(.*).mobi' => sub {
    my $sha = $1;

    warn "building $sha";
     my $file = File::Spec->catfile("/tmp/mobi/",$sha.".mobi");
    if( -e $file ) {
        warn "Redir";
        redirect("/mobi/$sha.mobi");
    } else {
        Jifty->handler->apache->header_out( Refresh => qq{5; url="/build-mobi/$sha.mobi"});
        show("building_mobi");
    }

};

on qr'/mobi/(.*).mobi' => sub {
    my $sha = $1;
    warn "Getting $sha";
    my $apache = Jifty->handler->apache;
    $apache->header_out( Status          => 200 );

    # Expire in a year
        $apache->content_type('application/x-mobipocket-ebook');

    open (my $fd, "<", File::Spec->catfile("/tmp/mobi/",$sha.".mobi")) || die "file $!" . File::Spec->catfile("/tmp/mobi/",$sha);
    unless ($fd) {
        redirect "/errors/no/such/mobi";
    }
    Jifty->handler->send_http_header;
    $apache->send_fd($fd);
    while (<$fd>) {
        print $_
    }
    close($fd);
    last_rule;  

};

sub mobify {
    my $name = shift;
    my $sha1 = shift;
    my $file = File::Spec->catfile('/tmp/mobi/',$sha1 .".mobi");
    system("perl -I/Users/jesse/git/github/unsavory-epub-hacks/epub2html/lib -I/Users/jesse/git/github/unsavory-epub-hacks/mobi2html/lib /Users/jesse/git/github/unsavory-epub-hacks/epub2html/bin/epub2mobi --source $name --target $file &");
};

1;

