package Text::ePub::NavMap;
use Mouse;
has entries => ( isa => 'ArrayRef', is => 'rw', default => sub { [] } );

no Mouse;
