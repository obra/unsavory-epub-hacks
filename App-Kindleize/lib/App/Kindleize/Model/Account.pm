use strict;
use warnings;

package App::Kindleize::Model::Account;
use Jifty::DBI::Schema;

sub since {'0.0.2'};

use App::Kindleize::Record schema {
    column token => label is 'Your secret',
        default is lazy { gen_token() };
    column library_items => references App::Kindleize::Model::LibraryItemCollection by 'account';

};

# Your model-specific methods go here.

sub gen_token {
    return String::Koremutake->new->integer_to_koremutake(int rand(99999999))
}

1;

