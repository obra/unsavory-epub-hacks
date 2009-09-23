package Text::ePub::Manifest;
use Mouse;


has spine   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has content => ( is => 'rw', isa => 'HashRef',  default => sub { {} } );
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

1;
