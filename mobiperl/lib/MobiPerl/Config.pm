package MobiPerl::Config;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/COnfig.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
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

sub new {
    my $this  = shift;
    my $data  = shift;
    my $class = ref($this) || $this;
    my $obj   = bless {
        ADDCOVERLINK     => 0,
        TOCFIRST         => 0,
        COVERIMAGE       => "",
        THUMBIMAGE       => "",
        AUTHOR           => "",
        TITLE            => "",
        PREFIXTITLE      => "",
        NOIMAGES         => 0,
        FIXHTMLBR        => 0,
        REMOVEJAVASCRIPT => 0,
        SCALEALLIMAGES   => 1.0,
        KEEPBR           => 0,
        @_
    }, $class;
    $obj->initialize_from_file($data) if defined $data;
    return $obj;
}

sub add_cover_link {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{ADDCOVERLINK} = $val;
    }
    else {
        return $self->{ADDCOVERLINK};
    }
}

sub toc_first {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{TOCFIRST} = $val;
    }
    else {
        return $self->{TOCFIRST};
    }
}

sub cover_image {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{COVERIMAGE} = $val;
    }
    else {
        return $self->{COVERIMAGE};
    }
}

sub thumb_image {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{THUMBIMAGE} = $val;
    }
    else {
        return $self->{THUMBIMAGE};
    }
}

sub author {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{AUTHOR} = $val;
    }
    else {
        return $self->{AUTHOR};
    }
}

sub title {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{TITLE} = $val;
    }
    else {
        return $self->{TITLE};
    }
}

sub prefix_title {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{PREFIXTITLE} = $val;
    }
    else {
        return $self->{PREFIXTITLE};
    }
}

sub no_images {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{NOIMAGES} = $val;
    }
    else {
        return $self->{NOIMAGES};
    }
}

sub remove_java_script {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{REMOVEJAVASCRIPT} = $val;
    }
    else {
        return $self->{REMOVEJAVASCRIPT};
    }
}

sub scale_all_images {
    my $self = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{SCALEALLIMAGES} = $val;
    }
    else {
        return $self->{SCALEALLIMAGES};
    }
}

return 1;
