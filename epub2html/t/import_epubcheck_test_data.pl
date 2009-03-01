#!/usr/bin/env perl

use warnings;
use strict;
chdir('t');
chdir('data');
`rm -rf epubcheck_test_data`;
print "Fetching epubcheck test data from google code\n";
`svn export http://epubcheck.googlecode.com/svn/trunk/com.adobe.epubcheck/testdocs epubcheck_test_data`;

print "Got it all\n";





