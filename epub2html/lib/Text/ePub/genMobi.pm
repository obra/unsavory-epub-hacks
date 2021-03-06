#!/usr/bin/env perl

#    Contains significant portions of:
#    html2mobi, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;

package Text::ePub::genMobi;

use File::Temp qw/tempdir/;
use lib 'lib';
use Text::ePub::Parser;
use Text::ePub::HTMLContent;
use Getopt::Long;

use MobiPerl::MobiFile;
use MobiPerl::Opf;
use MobiPerl::Config;
use MobiPerl::LinksInfo;

use HTML::TreeBuilder;

sub verbose;    # predeclare with null prototype. awful hack so we can say warn 'foo' if verbose;


sub epub_to_mobi {
    my %args = (
        source => undef,
        target => undef,
        @_
    );

    $args{tempdir} = tempdir( CLEANUP => 1 );
    my ( $html, $parser ) = Text::ePub::genMobi::epub_to_html(%args);
    Text::ePub::genMobi::html_to_mobi(
        %args,
        content => $html,
        parser  => $parser,
    );

}




sub epub_to_html {
    my %args   = (@_);
    my $epub   = $args{source};
    my $target = $args{target};

    my $parser = Text::ePub::Parser->new();

    unless ( $parser->read_epub($args{source}) ) {
        die "Something bad happened while trying to read your book: $@";
    }

    my $html_header = my $out
        = build_html_header($parser) 
        . "<body>"
        . sectionize( front_matter($parser) )
        . sectionize( generate_toc($parser) )
        . sectionize( extract_chapters($parser) )
        . "</body></html>";

    extract_images( $parser, $args{tempdir} );
    return $out, $parser;
}


sub html_to_mobi {
    my %args = (
        content => undef,
        target  => undef,
        parser  => undef,
        tempdir => undef,
        @_
    );

    my $linksinfo = MobiPerl::LinksInfo->new;

    my $config = MobiPerl::Config->new();

    $config->title($args{parser}->manifest->title);
    $config->author($args{parser}->manifest->author);

    my $tree = HTML::TreeBuilder->new();
    $tree->ignore_unknown(0);
    $tree->parse_content( $args{content} );

    convert_tree( $tree, $linksinfo, $config, $args{tempdir} );

    MobiPerl::MobiFile::save_mobi_file( $tree, $args{target}, $linksinfo, $config,
        ( 1));

}

sub sectionize {
    my $content = shift;
    return "<mbp:section>" . $content . "</mbp:section>";
}

sub flatten_toc {
    my $entries = shift;
    my @flat;
    for my $e (@$entries) {
        push @flat, $e;
        if ( ref $e->{kids} ) {
            push @flat, flatten_toc( $e->{kids} );
        }
    }

    return @flat;
}

sub extract_chapters {
    my $parser  = shift;
	my $spine = $parser->manifest->spine;
    my @entries = flatten_toc( $parser->toc->entries );
    my $out     = '<a name="chapters"></a>';

	my %navpoints = map { $_->{file} => $_ } @entries;
	for my $item (@$spine) {
		my $href = $parser->manifest->content->{$item}->{href};
		my $navpoint = $navpoints{$href}->{id};
		if ($navpoint) {
			$out .= qq{<a name="@{[$navpoint]}"><!-- Chapter --></a>};
		}
            my $content = Text::ePub::HTMLContent->new(
                epub     => $parser,
                filename => $parser->content_prefix . $href
            );
            $content->load();
            $out .= warp_xhtml_to_html_section( $content->content_utf8() );

            #$out .= build_chapter_nav( $id, \@entries );
            $out .= qq{    <p style="page-break-before: always"/> };
    }
    return $out;
}

sub build_chapter_nav {
    my $id      = shift;
    my @entries = @{ shift @_ };
    my $entry   = $entries[$id];
    my $out     = '<div class="nav">';
    $out .= qq{<a href="#@{[$entries[$id-1]->{id}]}">Previous (@{[$entries[$id-1]->{label}]})</a>}
        if ($id);    #skip 1
    $out .= ' <a href="#contents">Table of contents</a>';
    $out .= qq{ <a href="#@{[$entries[$id+1]->{id}]}">Next (@{[$entries[$id+1]->{label}]})</a>}
        if ( exists $entries[ $id + 1 ] );
    $out .= "</div>";

}

sub generate_toc {
    my $parser = shift;

    my $out
        = q{<div id="toc"><a name="contents"><h2>Table of contents</h2></a>}
        . sub_toc( $parser->toc->entries )
        . "</div>";
    return $out;

}

sub sub_toc {
    my $items = shift;
    my $out;
    $out .= qq{<ul class="contents">\n};
    foreach my $entry ( @{$items} ) {
        $out .= qq{<li><a href="#@{[ $entry->{id}]}">@{[$entry->{label}]}</a>};

        $out .= sub_toc( $entry->{kids} ) if ( ref $entry->{kids} );

        $out .= qq{</li>\n};
    }
    $out .= "</ul>\n";

    return $out;
}

sub front_matter {
    my $parser = shift;

    return qq{
    

    
    <div id="cover">&nbsp;</div>
    <div name="title">
        <center><h1 class="title">@{[$parser->manifest->title]}</h1></center>
    </div>
    <p style="page-break-before: always"/>
    <div name="author">
        <center><h2 class="author">@{[$parser->manifest->author]}</h2></center>
    </div>
    <p style="page-break-before: always"/>
};

}

sub build_html_header {
    my $parser = shift;
    my $out    = qq{<html>
<head>
    <title>@{[$parser->manifest->title]}</title>
    <dc:author>@{[$parser->manifest->author]}</dc:author>
   <guide>
     <reference type="toc" title="Table of Contents" href="#contents"></reference> 
    </guide>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
};

    return $out;
}

sub warp_xhtml_to_html_section {
    my $html = shift;

 # XHTML DTD might encode entities like this. if we were professionals, we'd use a real xhtml parser

    #<!DOCTYPE html [
    #<!ENTITY D "&#x2014;">
    #<!ENTITY o "&#x2018;">
    #<!ENTITY c "&#x2019;">
    #<!ENTITY O "&#x201C;">
    #<!ENTITY C "&#x201D;">
    #]>
    #

    # instead, we wrote a regex in 90 seconds
    while ( $html =~ /<!ENTITY\s+(.*?)\s+"(.*?)">/gim ) {
        my $from = $1;
        my $to   = $2;
        $html =~ s/&$from;/$to/g;
    }

    $html =~ s!^\s*(<.*?)?<html.*?>.*?<body.*?>!!is;
    $html =~ s!^\s*<html.*?>.*?<body.*?>!!is;
    $html =~ s!</body.*?>.*?</html.*>\s*$!!is;

    return $html;
}

sub extract_images {
    my $parser        = shift;
    my $target        = shift;
    my $content_files = $parser->manifest->content;
    for my $item ( keys %$content_files ) {
        my $media_type = $content_files->{$item}->{media_type};
        my $file       = $content_files->{$item}->{file};

        next
            unless ( ( $media_type && $media_type =~ /(?:image|css)/i )
            || ( $file && $file =~ /(?:jpe?g|png|gif|tiff?|bmp|css)$/i ) );

        # this is an awful, awful hack to try to write out collateral files
        # that start out at the same base level as document content
        # into the same directory as our eventual index.html

        # This deals with:
        # ../t/bookworm_test_data/invalid_天.epub

# the adobe alice book doesn't want or need this.
# The right solution probably involves parsing the html, finding a list of images it wants and trying to match them. I don't feel like doing that for a proof of concept.

        my $ch0_path = $parser->toc->entries->[0]->{file};
        $ch0_path =~ s|/(.+)?$|/|;

        my $out_path = $file;

        $out_path =~ s/^$ch0_path//;

        if ( $out_path =~ m|^(.*)/.+$| ) {
            my $subdir = $1;
            `mkdir -p $target/$subdir`;
        }
        open( my $imgout, ">", $target . "/" . $out_path )
            || die "Couldn't open image output file $out_path in $target: " . $!;
        print $imgout $parser->zip->contents( $parser->content_prefix . $file )
            || die " no writey $!";
        close $imgout;
    }

}

sub usage {
    print <<EOF;

$0 --source /home/lcarroll/from-publisher/alice.epub --target /home/lcarroll/alice.html --verbose

EOF
}

sub verbose {
    $ENV{'EPUB2HTML_VERBOSE'} ? 1 : 0;
}

sub convert_tree {
    my $tree      = shift;
    my $linksinfo = shift;
    my $config    = shift;
    my $base_dir  = shift;
    $linksinfo->check_for_links( $tree, $base_dir );

    my $coverimage = "";
    if ( $config->cover_image() ) {
        $coverimage = $config->cover_image();
    }

    if ($coverimage) {
        $linksinfo->add_cover_image($coverimage);
        if ( $config->add_cover_link() ) {
            my $coverp = HTML::Element->new(
                'p',
                id    => "addedcoverlink",
                align => "center"
            );
            my $coverimageel
                = HTML::Element->new( 'a', onclick => "document.goto_page_relative(1)" );
            $coverp->push_content($coverimageel);
            my $el = HTML::Element->new( 'img', src => "$coverimage" );
            $coverimageel->push_content($el);

            my $body = $tree->find("body");
            if ($body) {
                $body->unshift_content($coverp);
            }
            $linksinfo->check_for_links($tree);
        }
    }

    if ( $config->thumb_image() ) {
        $linksinfo->add_thumb_image( $config->thumb_image() );
    } else {
        if ($coverimage) {
            $linksinfo->add_thumb_image($coverimage);
        }
    }

    MobiPerl::Util::mobipocket_page_breaks($tree);
    MobiPerl::Util::fix_pre_tags($tree);
    MobiPerl::Util::remove_javascript($tree) if ( $config->remove_javascript() );
    make_hrefs_filepos($tree);
    return $tree;

}

sub make_hrefs_filepos {
    my $tree = shift;

    # Fix links, convert them to filepos

    my @refs        = $tree->look_down( "href", qr/^\#/ );
    my @hrefs       = ();
    my @refels      = ();
    my %href_to_ref = ();
    foreach my $r (@refs) {
        $r->attr( "filepos", "0000000000" );
        my $key = $r->attr("href");
        $key =~ s/\#//g;
        push @hrefs,  $key;
        push @refels, $r;
    }

    my $data = $tree->as_HTML();
    foreach my $i ( 0 .. $#hrefs ) {
        my $h          = $hrefs[$i];
        my $r          = $refels[$i];
        my $searchfor1 = qq{id="$h"};
        my $searchfor2 = qq{<a name="$h"};
        my $pos        = index( $data, $searchfor1 );
        if ( $pos >= 0 ) {

            # search backwards for <

            while ( substr( $data, $pos, 1 ) ne "<" ) {
                $pos--;
            }

##	    $pos -=4; # back 4 positions to get to <h2 id=
            $r->attr( "filepos", sprintf( "%0.10d", $pos ) );
        } else {
            $pos = index( $data, $searchfor2 );

            if ( $pos >= 0 ) {
                $r->attr( "filepos", sprintf( "%0.10d", $pos ) );
            } else {
            }
        }
    }
}


=head1 AUTHOR

Portions copyright Tommy Persson (tpe@ida.liu.se)
Portions copyright Jesse Vincent (jesse@fsck.com)

=cut

1;
