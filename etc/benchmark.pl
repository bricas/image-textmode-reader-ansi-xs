use strict;
use warnings;

use blib;
use Benchmark;

use Image::TextMode::Format::ANSI;
use Image::TextMode::Reader::ANSI;
use Image::TextMode::Reader::ANSI::XS;

my $image = Image::TextMode::Format::ANSI->new;
my $pureperl = Image::TextMode::Reader::ANSI->new;
my $xs = Image::TextMode::Reader::ANSI::XS->new;

open( my $f, shift );
binmode( $f );

my $r = Benchmark::timethese( 25, {
    'PP' => sub { $pureperl->_read( $image, $f, { width => 80 } ) },
    'XS' => sub { $xs->_read( $image, $f, { width => 80 } ) },
} );

close( $f );

Benchmark::cmpthese( $r );

