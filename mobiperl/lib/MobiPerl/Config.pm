use warnings;
use strict;

package MobiPerl::Config;

use Any::Moose;


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


has add_cover_link => (
	is => 'rw',
	isa => 'Bool',
	default => 0);


has toc_first => (
	is => 'rw',
	isa => 'Bool',
	default => 0);

has cover_image => (
	is => 'rw',
	isa => 'Maybe[Str]',
	default => '');

has thumb_image => (
	is => 'rw',
	isa => 'Str',
	default => '');

has author => (
	is => 'rw',
	isa => 'Maybe[Str]',
	default => '');

has title => (
	is => 'rw',
	isa => 'Maybe[Str]',
	default => '');


has prefix_title => (
	is => 'rw',
	isa => 'Maybe[Str]',
	default => '');


has no_images => (
	is => 'rw',
	isa => 'Bool',
	default => 0);

has remove_javascript => (
	is => 'rw',
	isa => 'Bool',
	default => 0);

has scale_all_images => (
	is => 'rw',
	isa => 'Str',
	default => '1.0');


1;
