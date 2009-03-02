package App::Kindleize::View;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;


private template 'salutation' => sub {};
private template 'keybindings' => sub {};
private template 'heading_in_wrapper' => sub {};
private template 'header' => sub {};
private template 'menu' => sub {};

template 'home' => page { 
    h1 { 'ePubs for your Kindle'};

    p{ outs 'Just visit';
        b{'http://kindle.fsck.com/http://some.ebook.site/my.epub'}};

};

template 'building_mobi' => page {{ title is 'Working on it!' }

    h1 { 'Converting your document'};
    p { 'Sorry. just not done yet'};
    p { 'If you see this page over and over for more than a couple minutes, something went wrong. mail jesse@fsck.com'};

};

1;
