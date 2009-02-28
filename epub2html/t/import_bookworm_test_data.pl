#!/usr/bin/env perl

use warnings;
use strict;
chdir('t');
chdir('data');
`rm -rf bookworm_test_data`;
print "Fetching bookworm test data from google code\n";
`svn export http://threepress.googlecode.com/svn/trunk/bookworm/library/test-data/data bookworm_test_data`;

print "Got it all\n";





