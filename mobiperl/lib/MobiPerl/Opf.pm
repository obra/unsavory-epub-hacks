use warnings;
use strict;
package MobiPerl::Opf;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/Opf.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
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

use FindBin qw($RealBin);
use lib "$RealBin";


use XML::Parser::Lite::Tree;

use MobiPerl::Util;

sub new {
    my $this  = shift;
    my $data  = shift;
    my $class = ref($this) || $this;
    my $obj   = bless {
        OPF           => 0,
        TITLE         => "",
        AUTHOR        => "Unspecified Author",
        IDTOHREF      => {},
        IDTOMEDIATYPE => {},
        MANIFESTIDS   => [],
        COVERIMAGE    => "",
        SPINEIDS      => [],
        TOCHREF       => "",
        FILENAME      => $data,
        @_
    }, $class;
    $obj->initialize_from_file($data) if defined $data;
    return $obj;
}

sub get_href {
    my $self = shift;
    my $val  = shift;
    return $self->{IDTOHREF}->{$val};
}

sub get_media_type {
    my $self = shift;
    my $val  = shift;
    return $self->{IDTOMEDIATYPE}->{$val};
}

sub get_spine_ids {
    my $self = shift;
    return @{ $self->{SPINEIDS} };
}

sub get_manifest_ids {
    my $self = shift;
    return @{ $self->{MANIFESTIDS} };
}

sub set_opf {
    my $self = shift;
    my $val  = shift;
    $self->{OPF} = $val;
}

sub get_opf {
    my $self = shift;
    return $self->{OPF};
}

sub set_title {
    my $self = shift;
    my $val  = shift;
    $self->{TITLE} = $val;
}

sub get_title {
    my $self = shift;
    return $self->{TITLE};
}

sub set_author {
    my $self = shift;
    my $val  = shift;
    $self->{AUTHOR} = $val;
}

sub get_author {
    my $self = shift;
    return $self->{AUTHOR};
}

sub set_toc_href {
    my $self = shift;
    my $val  = shift;
    $self->{TOCHREF} = $val;
}

sub get_toc_href {
    my $self = shift;
    return $self->{TOCHREF};
}

sub set_cover_image {
    my $self = shift;
    my $val  = shift;
    $self->{COVERIMAGE} = $val;
}

sub get_cover_image {
    my $self = shift;
    return $self->{COVERIMAGE};
}

sub initialize_from_file {
    my $self     = shift;
    my $filename = shift;

    print STDERR "Opf: Initialize from file: $filename\n";

    open OPF, "<$filename" or die "Could not open opf file: $filename\n";
    local $/;
    my $content = <OPF>;

    print STDERR "CONTENT: $content\n";

    my $tree_parser = XML::Parser::Lite::Tree::instance();
    my $opf         = $tree_parser->parse($content);
    $self->set_opf($opf);

    #    print STDERR Dumper($opf);

    my $title = opf_get_title($opf);

    # global variable $title, bad...
    print STDERR "OPF: TITLE: $title\n";
    $self->set_title($title);

    my $creator = opf_get_tag( $opf, "dc:Creator" );

    # global variable $title, bad...
    print STDERR "OPF: CREATOR: $creator\n";
    $self->set_author($creator);

    $self->parse_manifest($opf);
    $self->parse_spine($opf);
    $self->parse_guide($opf);

}

sub parse_manifest {
    my $self = shift;
    my $opf  = shift;

    #    my ($vol,$dir,$basefile) = File::Spec->splitpath ($self->{FILENAME});
    #    print STDERR "OPFFILE: $vol - $dir - $basefile\n";

    my $type = $opf->{"type"};

    #    print STDERR "TYPE: $type - ";

    if ( $type eq "tag" or $type eq "element" ) {
        my $name = $opf->{"name"};

        #	print STDERR "$name\n";
        if ( $name eq "manifest" ) {
            print STDERR "Init from manifest\n";
            my $children = $opf->{"children"};
            foreach my $c ( @{$children} ) {
                if ( $c->{name} eq "item" ) {
                    my $id        = $c->{"attributes"}->{"id"};
                    my $href      = $c->{"attributes"}->{"href"};
                    my $mediatype = $c->{"attributes"}->{"media-type"};
                    print STDERR "$id - $href - $mediatype\n";
                    $self->{IDTOHREF}->{$id}      = $href;
                    $self->{IDTOMEDIATYPE}->{$id} = $mediatype;
                    push @{ $self->{MANIFESTIDS} }, $id;

                    #		    $opf_id_to_href{$id} = $href;
                    #		    $opf_id_to_mediatype{$id} = $mediatype;
                    #		    push @opf_manifest_ids, $id;

                    #
                    # Check if image is coverimage file
                    #

                    if ( $mediatype =~ /image/ ) {
                        print STDERR "CHECK IF IMAGE: $href\n";
                        if ( MobiPerl::Util::is_cover_image($href) ) {
                            $self->set_cover_image($href);
##			    $coverimage = $href;
                        }
                    }
                }
            }

            return;
        }
    }

    if ( $type eq "data" ) {
        return "";
    }

    if ( $type eq "tag" or $type eq "root" or $type eq "element" ) {
        my $children = $opf->{"children"};
        foreach my $c ( @{$children} ) {
            $self->parse_manifest($c);
        }
    }
}

sub parse_spine {
    my $self = shift;
    my $opf  = shift;
    my $type = $opf->{"type"};

    #    print STDERR "TYPE: $type - ";

    if ( $type eq "tag" or $type eq "element" ) {
        my $name = $opf->{"name"};

        #	print STDERR "$name\n";
        if ( $name eq "spine" ) {

            #	    print STDERR "Init from spine\n";
            my $children = $opf->{"children"};
            my %idcheck  = ();
            foreach my $c ( @{$children} ) {
                if ( $c->{name} eq "itemref" ) {
                    my $idref = $c->{"attributes"}->{"idref"};
                    if ( $idcheck{$idref} ) {
                        print STDERR "WARNING: Spine, duplice idref: $idref\n";
                    }
                    else {
                        push @{ $self->{SPINEIDS} }, $idref;
##			push @opf_spine_ids, $idref;
                        $idcheck{$idref} = 1;
                    }
                }
            }
            foreach my $id ( @{ $self->{MANIFESTIDS} } ) {
##		print STDERR "CHECK FOR ADDING to spine from manifest - $id\n";
                if ( not $idcheck{$id} ) {
                    print STDERR "Warning, $id missing from spine, adding\n";
                    push @{ $self->{SPINEIDS} }, $id;
##		    push @opf_spine_ids, $id;
                }
            }

            return;
        }
    }

    if ( $type eq "data" ) {
        return "";
    }

    if ( $type eq "tag" or $type eq "root" or $type eq "element" ) {
        my $children = $opf->{"children"};
        foreach my $c ( @{$children} ) {
            $self->parse_spine($c);
        }
    }
}

sub parse_guide {
    my $self = shift;
    my $opf  = shift;
    my $type = $opf->{"type"};

    #    print STDERR "TYPE: $type - ";

    if ( $type eq "tag" or $type eq "element" ) {
        my $name = $opf->{"name"};

        #	print STDERR "$name\n";
        if ( $name eq "guide" ) {
            print STDERR "Init from guide\n";
            my $children = $opf->{"children"};
            foreach my $c ( @{$children} ) {
                if ( $c->{name} eq "reference" ) {
                    my $type = $c->{"attributes"}->{"type"};

                    #		    print STDERR "TYPE: $type\n";
                    if ( $type eq "toc" ) {
                        $self->set_toc_href( $c->{"attributes"}->{"href"} );
                        print STDERR "TOCHREF: ", $self->get_toc_href(), "\n";
                    }
                    if ( $type eq "other.ms-coverimage-standard" ) {
                        my $href = $c->{"attributes"}->{"href"};
                        $self->set_cover_image($href);
                    }
                }
            }
            return;
        }
    }

    if ( $type eq "data" ) {
        return "";
    }

    if ( $type eq "tag" or $type eq "root" or $type eq "element" ) {
        my $children = $opf->{"children"};
        foreach my $c ( @{$children} ) {
            $self->parse_guide($c);
        }
    }
}

#
# Non object methods
#

sub opf_get_title {
    my $opf = shift;

    #    print STDERR "SELF:$self\n";
    my $type = $opf->{"type"};

    #    print STDERR "TYPE: $type - ";

    if ( $type eq "tag" or $type eq "element" ) {
        my $name = $opf->{"name"};

        #	print STDERR "$name\n";
        if ( $name eq "dc:Title" ) {
            my $children = $opf->{"children"};
            return @{$children}[0]->{"content"};
        }
    }

    if ( $type eq "data" ) {
        return "";
        my $content = $opf->{"content"};
        chomp $content;
        chomp $content;
        print STDERR "$content\n";
    }

    if ( $type eq "tag" or $type eq "root" or $type eq "element" ) {
        my $children = $opf->{"children"};
        foreach my $c ( @{$children} ) {
            my $res = opf_get_title($c);
            if ($res) {
                return $res;
            }
        }
    }
    return "";
}

sub opf_get_tag {
    my $opf = shift;
    my $tag = shift;
##    print STDERR "opf_get_tag: $tag\n";
    #    print STDERR "SELF:$self\n";
    my $type = $opf->{"type"};

    #    print STDERR "TYPE: $type - ";

    if ( $type eq "tag" or $type eq "element" ) {
        my $name = $opf->{"name"};
##	print STDERR "$name - $tag\n";
        if ( $name eq $tag ) {
            my $children = $opf->{"children"};
            return @{$children}[0]->{"content"};
        }
    }

    if ( $type eq "data" ) {
        return "";
        my $content = $opf->{"content"};
        chomp $content;
        chomp $content;
        print STDERR "$content\n";
    }

    if ( $type eq "tag" or $type eq "root" or $type eq "element" ) {
        my $children = $opf->{"children"};
        foreach my $c ( @{$children} ) {
            my $res = opf_get_tag( $c, $tag );
            if ($res) {
                return $res;
            }
        }
    }
    return "";
}

return 1;
