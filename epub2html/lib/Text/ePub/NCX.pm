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


    my $node = $xp->find('/ncx/navMap')->shift;
    my @chapters = @{$self->get_child_navpoints($node)};

    $self->entries([sort {$a->{order} <=> $b->{order}} @chapters]);

}


sub get_child_navpoints {
       my $self = shift;
        my $root  = shift;
        my $nodes=$root->find ('./navPoint');
    my @chapters;
 
    foreach my $node ( $nodes->get_nodelist ) {
            my $data = {  id => $node->getAttribute('id'),
            order => $node->getAttribute('playOrder'),
            href => $node->find('content')->[0]->getAttribute('src'),
            label => $node->find('navLabel/text')->string_value};
        Text::ePub::Parser::_trace("Found an item ".$data->{href});
        $data->{file} = Text::ePub::Parser->href_to_file($data->{href});
        Text::ePub::Parser::_trace("it became ".$data->{file});
            $data->{kids} = $self->get_child_navpoints($node);

            if (!$data->{kids}->[0]) {
                delete $data->{kids};
            } elsif (my $child_content = $data->{kids}->[0]->{href}) {
                if ($data->{href} eq $child_content )   {
                    delete $data->{href};
                    delete $data->{file};
                }
            }

        push @chapters, $data;

    }
        return \@chapters; 
    }


no Mouse;

1;
