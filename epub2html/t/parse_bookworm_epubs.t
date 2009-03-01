use strict;
use warnings;

use Test::More;
use File::Find;
use Text::ePub::Parser;

my @test_files;

find(
    sub {
        return unless $File::Find::name =~ /epub$/;
        push @test_files, $File::Find::name;

    },
    't/bookworm_test_data'
);

plan tests => scalar @test_files * 4;

test_parse($_) for @test_files;

sub test_parse {
    my $file = shift;
    eval {
        my $p = Text::ePub::Parser->new();
        ok( eval { $p->read_epub($file); }, "$file Basic parse was ok" );

        if ( my $err = $@ ) { ok(0, "Basic parse failed: error $err"); }

        if ( $p->toc->entries->[0] ) {

            my $file = $p->toc->entries->[0]->{file};

            ok( $file, "Found an ref for the first chapter" );
            my $content = Text::ePub::HTMLContent->new(
                epub     => $p,
                filename => $p->content_prefix . $file
            );
            ok( $content->load(), "The content file loaded" );

        } else {
        SKIP: {
                skip "this ebook doesn't have any chapters!", 2;
            }
        }

    };

    if ( my $err = $@ ) {
        ok( 0, "Parse failed for $file: $err" );
    } else {
        ok( 1, "Parse ok for $file" );
    }

}
