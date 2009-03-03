package App::Kindleize::View;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;


private template 'salutation' => sub {};
private template 'keybindings' => sub {};
private template 'heading_in_wrapper' => sub {};
private template 'header' => sub {};
private template 'menu' => sub {};

template 'account_home' => page {
    my $u = get('user');

h1 { 'Welcome to #APP#' };
h2 { 'Your token is '.$u->token};
p { Jifty->web->link( url => '/', label => 'foo')};

p { outs( 'Visit ') ;
    Jifty->web->link( label => Jifty->web->url ."setup/". $u->token.".mobi", url => "/setup/". $u->token.".mobi") ;
    outs( " from your Kindle")};
    p{
    outs("Don't lose this URL: ". Jifty->web->link( label => 'My Kindleize Library', url => '/account/'.$u->token.'/home')); 
    outs("Drag this bookmarklet to your bookmark bar: ");
    my $add_url = Jifty->web->url."account/".$u->token.'/add/';
    outs_raw(q[<a href="].
        q[javascript:(function(){f='].$add_url.q['+window.location.href].
        q[;a=function(){].
        q[if(!window.open(f,'bookmark','location=yes,links=no,scrollbars=no,toolbar=no,width=550,height=550'))].
        q[location.href=f};if(/Firefox/.test(navigator.userAgent)){setTimeout(a,0)}else{a()}})()">Kindleize!</a>]);
    };
};

template 'account_library' => page {
    h1 {'Your library'};
    my $u = get('user');
    my $items = $u->library_items;
    ul {
    foreach my $item (@$items) {

        li { 
           Jifty->web->link( label =>  "Download ".$item->url." for your Kindle", url => '/mobi/'.$item->sha1.".mobi");
        }
    }
    }

};

template 'account_adding' => page {
my $u = get('user');
h1 { 'Welcome to #APP#' };
h2 { 'Your token is '.$u->token};
p{ outs("Now downloading ".get('url'))}

};

template 'home' => page { 
    h1 { 'ePubs for your Kindle'};

    p{ outs 'Just visit';
        b{Jifty->web->url.'epub/http://some.ebook.site/my.epub'}};

};

template 'building_mobi' => page {{ title is 'Working on it!' }

    h1 { 'Converting your document'};
    p { 'Sorry. just not done yet'};
    p { 'If you see this page over and over for more than a couple minutes, something went wrong. mail jesse@fsck.com'};

};

1;
