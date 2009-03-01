package Text::ePub::Parser;
use Mouse;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use XML::XPath;
use XML::Parser;
use URI;

has zip            => ( is  => 'rw',  isa     => 'Archive::Zip' );
has manifest       => ( is  => 'rw',  isa     => 'Text::ePub::Manifest' );
has content_prefix => ( isa => 'Str', is => 'rw' );
has content_index  => ( isa => 'Str', is      => 'rw' );
has toc => (is => 'rw', isa  => 'Text::ePub::NCX');



sub read_epub {

    my $self = shift;
    my $epub = shift;
    
    eval { 
    _trace('opening zip');
    # Read a Zip file
    my $zip = Archive::Zip->new();
    unless ( $zip->read($epub) == AZ_OK ) {
        die 'read error';
    }
    _trace('opened');
    $self->zip($zip);
    _trace('finding content index');
    $self->find_content_index();
    _trace('found content index');
    $self->parse_manifest;
    _trace('got the manifest');
    $self->parse_toc;
    _trace('got the toc');
    };
    if (my $err = $@) {
        warn "Read failed: $err";
        return undef;
    }
    return 1;
}

sub find_content_index {
    my $self = shift;

    my $meta = $self->zip->contents('META-INF/container.xml');

    my $rootfile;
    unless ($meta) {
        _trace( "no metafile. searching for something that looks ok");
        $self->_divine_container_info;

    }
    else {
    _trace("opening themetafile");
        my $xp = Text::ePub::Parser->_get_parser( xml => $meta );
        my $nodes = $xp->find('/container/rootfiles/rootfile');
    _trace("got some nodes");
        foreach my $node ( $nodes->get_nodelist ) {
            my $path = $node->getAttribute('full-path');
            next unless $path;
            $self->content_index($path);
            my @parts = File::Spec->splitdir($path);
            pop @parts;
            my $base_dir = join('/',@parts);
            $base_dir .= "/" if ($base_dir);
            $self->content_prefix($base_dir);
        }
    }
}
sub _divine_container_info {
    my $self = shift;

    my @files = $self->zip->memberNames;
    my @maybe_content = grep { /content.opf$/ } @files;
    if ($maybe_content[0] =~ m|^(.*/)?content.opf$|) {
        my $dir = $1;
        _trace("Got a container file that looks ok: $dir and ".$maybe_content[0]);
        $self->content_prefix($dir); 
        $self->content_index($maybe_content[0]);
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

    my @toc_options = grep defined, (
        $self->manifest->content->{ncx}->{href},
        $self->manifest->content->{ncxtoc}->{href},
        $self->manifest->content->{toc}->{href},
        'toc.ncx', 'toc'
    );
    my @files = $self->zip->memberNames;
    my $toc_file;
    for my $proposal ( ( map { $self->content_prefix . $_ } @toc_options ), @toc_options ) {
        if ( grep { $_ eq $proposal } @files ) {
            $toc_file = $proposal;
            last;
        }
    }
    unless ($toc_file) {
    for my $maybe (grep { /ncx$/i} @files) { 
        
        { local $@;
        my  $data = eval { $self->zip->contents($maybe)};
            warn $@ if ($@);
        next unless $data =~ /<navmap/i;
        }
        $toc_file = $maybe; 
        last;
    }
    }
    die "I couldn't find anything that looked like a toc. help!" unless($toc_file);

    my $data = $self->zip->contents($toc_file) || die "Couldn't get the ncx file for " . $toc_file;
    $self->toc( Text::ePub::NCX->new( epub => $self ) );
    $self->toc->parse($data);

}

sub _trace {
    # warn join(' ', @_);
}

sub _get_parser { 
    my $self = shift;
    my (%args) = (@_);
    my $p = XML::Parser->new( NoLWP => 1);
    my $xp= XML::XPath->new( parser => $p, %args);
}

sub href_to_file {
    my $self = shift;
    my $href = shift;
    my $uri = URI->new($href);
    return $uri->path;

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


sub parse {
    my $self = shift;
    my $data = shift;

    my $xp = Text::ePub::Parser->_get_parser( xml => $data );
    my $nodes = $xp->find(".//*[local-name()='manifest']/*[local-name()='item']");
    foreach my $node ( $nodes->get_nodelist ) {
        my $file_info = {
            id         => $node->getAttribute('id'),
            href       => $node->getAttribute('href'),
            media_type => $node->getAttribute('media-type')

        };

        # deal with items that reference anchors in docs like t/bookworm_test_data/天.epub
        $file_info->{file} = Text::ePub::Parser->href_to_file($file_info->{href});

        $self->content->{ $file_info->{id} } = $file_info;

    }

    my $author = $xp->find(".//*[local-name()='creator']");
    $self->author($author->string_value);

    my $title = $xp->find(".//*[local-name()='title']");
    $self->title($title->string_value);

    my $toc = $xp->find(".//*[local-name()='spine']");
    my $proposed_toc = $toc->get_node(1)->getAttribute('toc');
    $self->toc($proposed_toc) if ($proposed_toc);
    my $spine_entries = $xp->find(".//*[local-name()='spine']//*[local-name()='itemref'");
    foreach my $entry ( $spine_entries->get_nodelist ) {
        push @{ $self->spine }, $entry->getAttribute('idref');
    }

}

no Mouse;

package Text::ePub::NCX;
use Mouse;
has entries => ( isa => 'ArrayRef', is => 'rw');
has epub => ( isa => 'Text::ePub::Parser', weak_ref => 1, is => 'rw' );
has title => (isa => 'Str', is => 'rw');


sub parse {
    my $self = shift;
    my $data = shift;

    my $xp = Text::ePub::Parser->_get_parser( xml => $data );
    my $title = scalar $xp->find('/ncx/docTitle')->[0]->string_value;
    $self->title($title);


    my $nodes = $xp->find('/ncx/navMap/navPoint');
    my @chapters;
    foreach my $node ( $nodes->get_nodelist ) {
            my $data = {  id => $node->getAttribute('id'),
            order => $node->getAttribute('playOrder'),
            href => $node->find('content')->[0]->getAttribute('src'),
            label => $node->find('navLabel/text')->string_value};

        $data->{file} = Text::ePub::Parser->href_to_file($data->{href});

        push @chapters, $data;

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
    my $file = $self->filename;
    $file =~ s|^/+||;
    $self->raw_content( $self->epub->zip->contents( $file ) ) || die "Couldn't load file ".$file;

}

no Mouse;

1;
