package Text::ePub::Parser;
use Mouse;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use XML::XPath;
use XML::XPath::XMLParser;

has zip            => ( is  => 'rw',  isa     => 'Archive::Zip' );
has manifest       => ( is  => 'rw',  isa     => 'Text::ePub::Manifest' );
has content_prefix => ( isa => 'Str', is => 'rw' );
has content_index  => ( isa => 'Str', is      => 'rw' );
has toc => (is => 'rw', isa  => 'Text::ePub::NCX');

sub read_epub {

    my $self = shift;
    my $epub = shift;

    # Read a Zip file
    my $zip = Archive::Zip->new();
    unless ( $zip->read($epub) == AZ_OK ) {
        die 'read error';
    }

    $self->zip($zip);
    $self->find_content_index();
    $self->parse_manifest;
    $self->parse_toc;

}

sub find_content_index {
    my $self = shift;

    my $meta = $self->zip->contents('META-INF/container.xml');

    my $rootfile;
    unless ($meta) {
        warn "no metafile. defaulting to a standard rootfile";
        $self->content_index("OEBPS/content.opf");

    }
    else {

        my $xp = XML::XPath->new( xml => $meta );
        my $nodes = $xp->find('/container/rootfiles/rootfile');
        foreach my $node ( $nodes->get_nodelist ) {
            my $path = $node->getAttribute('full-path');
            next unless $path;
            $self->content_index($path);
            my $base_dir = $path;
        if ($base_dir =~ m|/|)  {
            $base_dir =~ s|/.*?$|/|;
        } else { $base_dir = ''}
            $self->content_prefix($base_dir);
        }
    }

}

sub parse_manifest {
    my $self = shift;
    my $data = $self->zip->contents( $self->content_index ) || die $!;
    $self->manifest( Text::ePub::Manifest->new( epub => $self ) );
    $self->manifest->parse($data);
}

sub parse_toc {
    my $self = shift;
    my $data = $self->zip->contents( $self->content_prefix.$self->manifest->content->{'ncx'}->{href} ) || die "Couldn't get the ncx file for " . $self->manifest->content->{'ncx'}->{href}  ." in " .$self->content_prefix .$!;
    $self->toc( Text::ePub::NCX->new( epub => $self ) );
    $self->toc->parse($data);

}

no Mouse;

package Text::ePub::Manifest;
use Mouse;

has spine   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has content => ( is => 'rw', isa => 'HashRef',  default => sub { {} } );
has metadata => ( is => 'rw', isa => 'Text::ePub::MetaData' );
has toc      => ( is => 'rw', isa => 'Str' );
has author => (is => 'rw', isa => 'Str');
has title => (is => 'rw', isa => 'Str');

use XML::XPath;
use XML::XPath::XMLParser;

sub parse {
    my $self = shift;
    my $data = shift;

    my $xp = XML::XPath->new( xml => $data );
    my $nodes = $xp->find(".//*[local-name()='manifest']/*[local-name()='item']");
    foreach my $node ( $nodes->get_nodelist ) {
        my $file_info = {
            id         => $node->getAttribute('id'),
            href       => $node->getAttribute('href'),
            media_type => $node->getAttribute('media-type')

        };
        $self->content->{ $file_info->{id} } = $file_info;

    }

    my $author = $xp->find(".//*[local-name()='creator']");
    $self->author($author->string_value);

    my $title = $xp->find(".//*[local-name()='title']");
    $self->title($title->string_value);

    my $toc = $xp->find(".//*[local-name()='spine']");
    $self->toc( $toc->get_node(1)->getAttribute('toc') );
    my $spine_entries = $xp->find(".//*[local-name()='spine']//*[local-name()='itemref'");
    foreach my $entry ( $spine_entries->get_nodelist ) {
        push @{ $self->spine }, $entry->getAttribute('idref');
    }

}

no Mouse;

package Text::ePub::NCX;
use Mouse;
use XML::XPath;
use XML::XPath::Parser;
has entries => ( isa => 'ArrayRef', is => 'rw');
has epub => ( isa => 'Text::ePub::Parser', weak_ref => 1, is => 'rw' );
has title => (isa => 'Str', is => 'rw');


sub parse {
    my $self = shift;
    my $data = shift;

    my $xp = XML::XPath->new( xml => $data );
    my $title = scalar $xp->find('/ncx/docTitle')->[0]->string_value;
    $self->title($title);


    my $nodes = $xp->find('/ncx/navMap/navPoint');
    my @chapters;
    foreach my $node ( $nodes->get_nodelist ) {
            push @chapters, {  id => $node->getAttribute('id'),
            order => $node->getAttribute('playOrder'),
            href => $node->find('content')->[0]->getAttribute('src'),
            label => $node->find('navLabel/text')->string_value};


    } 

    $self->entries([sort {$a->{order} <=> $b->{order}} @chapters]);

}

no Mouse;

package Text::ePub::NavMap;
use Mouse;
has entries => ( isa => 'ArrayRef', is => 'rw', default => sub { [] } );

no Mouse;

package Text::ePub::NavPoint;
use Mouse;

has label     => ( isa => 'Str', is => 'rw' );
has content   => ( isa => 'Str', is => 'rw' );
has playorder => ( isa => 'Str', is => 'rw' );
has id        => ( isa => 'Str', is => 'rw' );

no Mouse;

package Text::ePub::HTMLContent;
use Mouse;
has filename => ( isa => 'Str', is => 'rw' );
has raw_content => ( isa => 'Str|Undef', is => 'rw', default => '' );
has epub => ( isa => 'Text::ePub::Parser', weak_ref => 1, is => 'rw' );

sub load {
    my $self = shift;
    $self->raw_content( $self->epub->zip->contents( $self->filename ) ) || die "Couldn't load file ".$self->filename;

}

no Mouse;

1;
