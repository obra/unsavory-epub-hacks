package App::Kindleize;
use warnings;
use strict;
use FindBin;
our $PREFIX = $FindBin::Bin."/../..";
#our $PREFIX = '/Users/jesse/git/github/unsavory-epub-hacks';
    $ENV{'PERL5LIB'} .= ":". join(":",
            $PREFIX.'/epub2html/lib',
            $PREFIX.'/mobiperl/lib');
        `mkdir /tmp/mobi`;
        `mkdir /tmp/epub`;
warn $ENV{PERL5LIB};

our $EPUB2MOBI = $PREFIX. '/epub2html/bin/epub2mobi';
our $HTML2MOBI = $PREFIX . '/mobiperl/bin/html2mobi';

sub epub_to_mobi {
    my $name = shift;
    my $sha1 = shift;
    my $file = File::Spec->catfile('/tmp/mobi/',$sha1 .".mobi");
    system("$^X $EPUB2MOBI --source $name --target $file &");
};

sub html_to_mobi {
    my $html = shift;
    my $mobi = shift;
    my @args = ("$^X",$HTML2MOBI, "--mobifile", $mobi , $html);
    warn "outputting a mobi for $html to" . join( " ", @args);
    system("(".join(' ',@args).") &");
    warn "ok";
}
1;

1;

