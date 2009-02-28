package MobiPerl::LinksInfo;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/LinksInfo.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
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

use strict;

###use MobiPerl::Util;
##use Data::Dumper;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $obj = bless {
	LINKEXISTS => {},
	RECORDINDEX => 0,
	RECORDTOIMAGEFILE => {},
	COVEROFFSET => -1,
	THUMBOFFSET => -1,
	@_
    }, $class;
    return $obj;
}

sub link_exists {
    my $self = shift;    
    return $self->{LINKEXISTS};
}

sub add_image_link {
    my $self = shift;
    my $image = shift;
##    print STDERR "ADD_IMAGE_LINK: $image\n";
    $self->{RECORDINDEX}++;
    $self->{RECORDTOIMAGEFILE}->{$self->get_record_index ()} = $image;
}

sub add_cover_image {
    my $self = shift;
    my $image = shift;
    $self->add_image_link ($image);
    $self->{COVEROFFSET} = $self->get_record_index () - 1;
}

sub add_thumb_image {
    my $self = shift;
    my $image = shift;
    $self->add_image_link ($image);
    $self->{THUMBOFFSET} = $self->get_record_index () - 1;
}

sub get_cover_offset {
    my $self = shift;
    return $self->{COVEROFFSET};
}

sub get_thumb_offset {
    my $self = shift;
    return $self->{THUMBOFFSET};
}

sub get_record_index {
    my $self = shift;    
    return $self->{RECORDINDEX};
}

sub get_image_file {
    my $self = shift;    
    my $val = shift;
    return $self->{RECORDTOIMAGEFILE}->{$val};
}

sub get_n_images {
    my $self = shift;
    my $res = keys %{$self->{RECORDTOIMAGEFILE}};
    return $res;
}



sub check_for_links {
    my $self = shift;
    my $html = shift;
    for (@{$html->extract_links('a', 'img')}) {
	my($link, $element, $attr, $tag) = @$_;
	next if ($link =~ /http/);
	next if ($link =~ /mailto/);
	next if ($link =~ /www/);
#	print STDERR "LINK: $tag $link $attr at ", $element->address(), " ";
	if ($tag eq "a") {
	    my $filename = $element->as_trimmed_text ();
##	    print STDERR "LINKEXISTS $filename -> $link - ";
	    #
	    # Remove possible prefix file name in link
	    #
	    
	    $link =~ s/^.*\#//;
##	    print STDERR "$link\n";

	    $element->attr("href", "\#$link");
	    $self->{LINKEXISTS}->{$link} = 1;
	    next;
	}
	if ($tag eq "img") {
	    my $src = $element->attr("src");
	    if (-e "$src") {
		#
		# Onlys save link if image exists.
		#
		$element->attr("src", undef);
		$self->{RECORDINDEX}++;
		$element->attr("recindex", sprintf ("%05d", $self->{RECORDINDEX}));
		$self->{RECORDTOIMAGEFILE}->{$self->{RECORDINDEX}} = $src;
	    } else {
		print STDERR "Warning: Image file do not exists: $src\n";
	    }
	    next;
	}
	print STDERR "LINK: $tag $link $attr at ", $element->address(), " ";
#	print STDERR $element->as_HTML;
    }
}

return 1;
