package App::Kindleize::Dispatcher;
use Jifty::Dispatcher -base;
sub LWP::Debug::debug {}
sub LWP::Debug::trace {}
use LWPx::ParanoidAgent;
use File::Temp qw/tempfile/;
use Digest::SHA1;
use File::Spec;

on qr'^/(index.html)?$' => sub { show 'home' };

on qr'^/epub/(https?\://?.*)$' => run {
    my $url = $1;
    $url =~ s|:/|://|; # jifty removes repeated / - bug

        my $ua = LWPx::ParanoidAgent->new;
        $ua->timeout(30);
    warn "Fetching $url";
    my $response = $ua->get($url);
    warn "Fetched";
    if ($response->is_success) {
            my $sha1 = Digest::SHA1::sha1_hex($response->decoded_content);
        my $file = File::Spec->catfile("/tmp/epub/".$sha1);
        unless ( -e $file ) {
            open (my $fh, ">", $file);
            print $fh $response->decoded_content;
            close($fh);
        } 

        unless (File::Spec->catfile("/tmp/mobi/".$sha1.".epub")) {  
            App::Kindleize::epub_to_mobi($file => $sha1)};

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

on '/new_account' => sub {
    my $u = App::Kindleize::Model::Account->new(current_user => App::Kindleize::CurrentUser->superuser);
    $u->create;
    redirect('/account/'.$u->token.'/home');

};

on qr'/setup/(.*?).mobi' => sub {
    my $token = $1;
   my $content =  qq{<html><head><title>##APP## for $token</title></head>
                 <body><a href="}.Jifty->web->url."/account/".$token.
                 qq{/library">Visit your library</a></body</html>};
    close $fh;
   
    my ($fh, $file) = tempfile();
    print $fh $content;
    close($fh);

    my ($mobifh, $tmpmobi) =tempfile();
    close ($mobifh);
    App::Kindleize::html_to_mobi($file => $tmpmobi);

    send_mobi($tmpmobi);
    unlink($file);
    unlink ($tmpmobi);
    last_rule;
};

on qr'/account/(\w+)/?$' => run { redirect '/account/'.$1.'/home'};
under qr'/account/(.*?)/' => run {
    my $token = $1;
    my $u     = App::Kindleize::Model::Account->new(
        current_user => App::Kindleize::CurrentUser->superuser );
    $u->load_by_cols( token => $token );
    set user          => $u;
    on qr'^(.*)$' => sub { warn "GOT $1";};
    on 'home'         => sub { warn "home";show '/account_home' };
    on 'library'      => sub {warn "lib"; show "/account_library" };
        on qr'^/account/(?:\w+)/add/(.*)$' => sub {
        my $url = $1;
        $url =~ s|:/|://|;
        set url => $url;
        my $record = App::Kindleize::Model::LibraryItem->new(
            current_user => App::Kindleize::CurrentUser->superuser );
        $record->create( url => $url, account => $u->id );
        show "/account_adding";

    }
};

on qr'/mobi/(.*).mobi' => sub {
    my $sha = $1;
    send_mobi("/tmp/mobi/".$sha.".mobi");
    last_rule;  

};

sub send_mobi {
    my $file = shift;
    my $apache = Jifty->handler->apache;
    unless (-e $file ) {
        redirect '/error/mobi-file-missing';
    }
    $apache->header_out( Status          => 200 );

    warn "Sending mobi $file";
    # Expire in a year
        $apache->content_type('application/x-mobipocket-ebook');

    open (my $fd, "<", File::Spec->catfile($file)) || die "file $file $!";
    unless ($fd) {
        redirect "/errors/no/such/mobi";
    }
    Jifty->handler->send_http_header;
    $apache->send_fd($fd);
    while (<$fd>) {
        warn "Printing ".$_;
        print $_
    }
    close($fd);

};


'TRUE!';

