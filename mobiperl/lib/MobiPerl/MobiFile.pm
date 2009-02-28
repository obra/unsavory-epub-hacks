package MobiPerl::MobiFile;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/MobiFile.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
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

use Palm::PDB;
use Palm::Doc;

use MobiPerl::MobiHeader;
use MobiPerl::Util;

use constant DOC_UNCOMPRESSED => scalar 1;
use constant DOC_COMPRESSED => scalar 2;
use constant DOC_RECSIZE => scalar 4096;

use strict;

sub save_mobi_file {
    my $html = shift;
    my $filename = shift;
    my $linksinfo = shift;
    my $config = shift;

    my $rescale = shift;

    my $imrescale = $MobiPerl::Util::rescale_large_images;
    $imrescale = $rescale if defined $rescale;

    my $author = $config->author ();
    my $title = $config->title ();

    print STDERR "Saving mobi file (version 4): $filename\n";

    my $mobi = new Palm::Doc;
    $mobi->{attributes}{"resource"} = 0;
    $mobi->{attributes}{"ResDB"} = 0;

    $mobi->{"name"} = $title;
    $mobi->{"type"} = "BOOK";
    $mobi->{"creator"} = "MOBI";
    $mobi->{"version"} = 0;
    $mobi->{"uniqueIDseed"} = 28;

#    $mobi->{"attributes"}{"resource"} = $data;

#    my $header = Palm::PDB->new_Record();
#    $header->{"categori"} = 0;
#    $header->{"attributes"}{"Dirty"} = 1;
#    $header->{"id"} = 0;
#    $header->{"data"} = $data;
#    $mobi->append_Record ($header);

##    $mobi->text ([$data, $html->as_HTML ()]);
##    $mobi->text ($html->as_HTML ());

#
# From Doc.pm and modified
#

    my $version = DOC_COMPRESSED;
    $mobi->{'records'} = [];
    $mobi->{'resources'} = [];
    my $header = $mobi->append_Record();    
    $header->{'version'} = $version;
    $header->{'length'} = 0;
    $header->{'records'} = 0;
    $header->{'recsize'} = DOC_RECSIZE;

    my $body = $html->as_HTML ();
    $body =~ s/&amp\;nbsp\;/&nbsp\;/g; #fix &nbsp; that fix_pre_tags have added


#    print STDERR "HTMLSIZE: " . length ($body) . "\n";

    my $current_record_index = 1;
    # break the document into record-sized chunks
    for( my $i = 0; $i < length($body); $i += DOC_RECSIZE ) {
	my $record = $mobi->append_Record;
	my $chunk = substr($body,$i,DOC_RECSIZE);
	$record->{'data'} = Palm::Doc::_compress_record( $version, $chunk );
	$record->{'id'} = $current_record_index++;
	$header->{'records'} ++;
    }
    $header->{'length'} += length $body;

    $header->{'recsize'} = $header->{'length'} if $header->{'length'} < DOC_RECSIZE;

    #
    # pack the Palm Doc  header
    #
    $header->{'data'} = pack( 'n xx N n n N',
			      $header->{'version'}, $header->{'length'},
			      $header->{'records'}, $header->{'recsize'}, 0 );
    #
    # Add MOBI header
    #

    my $mh = new MobiPerl::MobiHeader;
    $mh->set_title ($title);
    $mh->set_author ($author);
    $mh->set_image_record_index ($current_record_index);

    
    #    $mh->set_cover_offset (0); # It crashes on Kindle if no cover is
	                            # is available and offset is set to 0
    my $cover_offset = $linksinfo->get_cover_offset ();
    print STDERR "COVEROFFSET: $cover_offset\n";
    $mh->set_cover_offset ($cover_offset); # Set to -1 if no cover image

#    if ($cover_offset >= 0) {
#	$mh->set_cover_offset ($cover_offset);
#    }

    my $thumb_offset = $linksinfo->get_thumb_offset ();
    print STDERR "THUMBOFFSET: $thumb_offset\n";
    if ($thumb_offset >= 0) {
	$mh->set_thumb_offset ($thumb_offset);
    }

##    my $codepage = 65001; # utf-8
#    my $codepage = 1252; # westerner
#    my $ver = 3;
#    my $type = 2; # book
#    my $mobiheadersize = 0x74;
#    my $unique_id = 17;
#    if ($ver == 4) {
#	$mobiheadersize = 0xE4;
#    }
#
#    my $extended_title_offset = $mobiheadersize + 16;
#    my $extended_title_length = length ($title);
#
#    my $use_extended_header = 1;
#    my $extended_header_flag = 0x00;
#    if ($use_extended_header) {
#	$extended_header_flag = 0x50; # At MOBI+0x70
#    }
#
#    my $exth = "";
#    if ($use_extended_header) {
#	$exth = pack ("a*", "EXTH");
#	my $content = "";
#	my $n_items = 1;
#	$content .= pack ("NNa*", 100, length ($author)+8, $author);
#	$exth .= pack ("NN", length ($content), $n_items);
#	$exth .= $content;
#	$extended_title_offset += length ($exth);
#    }
#
#    
#    # NNNN    Number of char, N1 N2 N3
#    # N3 = Pointer to start of Title
#    # Not true in Alice Case...
#    #
#
#    my $vie1 = 0; # 0x11 Alice 0x0D Rosenbaum
#
#    print STDERR "MOBIHDR: imgrecpointer: $current_record_index\n";
#
#    $header->{'data'} .= pack ("a*NNNNN", "MOBI",
#			       $mobiheadersize, $type, 
#			       $codepage, $unique_id, $ver);
#
#    $header->{'data'} .= pack ("NN", 0xFFFFFFFF, 0xFFFFFFFF);
#    $header->{'data'} .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
#    $header->{'data'} .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
#    $header->{'data'} .= pack ("NNNN", $vie1, $extended_title_offset, $extended_title_length, 0x0409);
#    $header->{'data'} .= pack ("NNNN", 0, 0, 0x04, $current_record_index);
#    $header->{'data'} .= pack ("NNNN", 0, 0, 0, 0);
#    $header->{'data'} .= pack ("N", $extended_header_flag);
##    print STDERR "MOBIHEADERSIZE: $mobiheadersize " . length ($header->{'data'}). "\n";
#    while (length ($header->{'data'}) < ($mobiheadersize+16)) {
#	print STDERR "LEN: " . length ($header->{'data'}). " - $mobiheadersize
#\n";
#	$header->{'data'} .= pack ("N", 0);
#    }
#    $header->{'data'} .= $exth;
#    $header->{'data'} .= pack ("a*", $title);
#    for (1..48) {
#	$header->{'data'} .= pack ("N", 0);
#    }
#

    $header->{'data'} .= $mh->get_data ();
   

#
# End from Doc.pm
#

    if (not $config->no_images ()) {
	for my $i (1..$linksinfo->get_record_index ()) {
	    my $filename = $linksinfo->get_image_file ($i);
##	    print STDERR "New record for image $current_record_index: $filename\n";

#
# Is it really correct to assign id and categori?
#	    
	    my $img = Palm::PDB->new_Record();
	    $img->{"categori"} = 0;
	    $img->{"attributes"}{"Dirty"} = 1;
	    $img->{"id"} = $current_record_index++;
	    my $data = MobiPerl::Util::get_image_data ($filename, 
						       $imrescale,
						       $config->scale_all_images());
	    $img->{"data"} = $data;
	    $mobi->append_Record ($img);
	}
	
	my $coverimage = $config->cover_image ();
	#
	# This will not work since EXTH information not set
	#

        #
        # Adding thumb for Cybook does not seem to be neccessary.
	# To automatically add the first image seems wrong...
	# So functionality disabled for now.
        #

	if ($coverimage and 0) {
	    print STDERR "New record for library image $current_record_index: $coverimage\n";
	    my $img = Palm::PDB->new_Record();
	    $img->{"categori"} = 0;
	    $img->{"attributes"}{"Dirty"} = 1;
	    $img->{"id"} = $current_record_index++;
	    my $data = MobiPerl::Util::get_thumb_cover_image_data ($coverimage);
	    $img->{"data"} = $data;
	    $mobi->append_Record ($img);
	}
    }

    $mobi->Write ($filename);
}



return 1;
