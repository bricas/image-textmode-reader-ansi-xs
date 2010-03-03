use strict;
use warnings;

use blib;
use Benchmark;

use Image::TextMode;
use Image::TextMode::Format::ANSI;
use Image::TextMode::Reader::ANSI;
use Image::TextMode::Reader::ANSI::XS;

my $file  = shift;
my $iters = 50;

die "No file specified" unless $file;
die "File '${file}' does not exist" unless -e $file;

printf "Image\::TextMode version %s\n", Image::TextMode->VERSION;
printf "Image\::TextMode\::Reader\::ANSI\::XS version %s\n",
    Image::TextMode::Reader::ANSI::XS->VERSION;
printf "Filesize: %d bytes\n", -s ( $file );

my $image    = Image::TextMode::Format::ANSI->new;
my $pureperl = Image::TextMode::Reader::ANSI->new;
my $xs       = Image::TextMode::Reader::ANSI::XS->new;

open( my $f, '<', $file );
binmode( $f );

my $r = Benchmark::timethese(
    $iters,
    {   'PP' => sub { $pureperl->_read( $image, $f, { width => 80 } ) },
        'XS' => sub { $xs->_read( $image,       $f, { width => 80 } ) },
    }
);

close( $f );

Benchmark::cmpthese( $r );

