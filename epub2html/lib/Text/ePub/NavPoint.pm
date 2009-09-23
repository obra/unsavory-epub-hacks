package Text::ePub::NavPoint;
use Mouse;

has label     => ( isa => 'Str', is => 'rw' );
has content   => ( isa => 'Str', is => 'rw' );
has playorder => ( isa => 'Str', is => 'rw' );
has id        => ( isa => 'Str', is => 'rw' );

no Mouse;
1;
