package Image::TextMode::Reader::ANSI::XS;

use strict;
use warnings;
use XSLoader;

our $VERSION = '0.05';

use base 'Image::TextMode::Reader';

XSLoader::load( 'Image::TextMode::Reader::ANSI::XS', $VERSION );

=head1 NAME

Image::TextMode::Reader::ANSI::XS - Fast ANSI image parsing

=head1 SYNOPSIS

    # The XS reader will automatically be used instead of the pure-perl version
    my $ansi = Image::TextMode::Format::ANSI->new
    $ansi->read( shift );

=head1 DESCRIPTION

To parse an ANSI file, we use a simple state machine and examine each character
individually. This proves to be a little on the slow side in pure-perl form.

This module endeavors to re-implement the parsing in XS/C. The results show
a major speed increase; about 25 times faster.

=head1 INSTALLATION

	perl Makefile.PL
	make
	make test
	make install

=head1 METHODS

=head2 _read( $image, $fh, \%options )

This is an XS-based version of L<Image::TextMode::Reader::ANSI>'s method of the
same name.

=head1 BENCHMARK

    Image::TextMode version 0.12
    Image::TextMode::Reader::ANSI::XS version 0.05
    Filesize: 75501 bytes
    Benchmark: timing 50 iterations of PP, XS...
            PP: 43 wallclock secs (42.25 usr +  0.04 sys = 42.29 CPU) @  1.18/s (n=50)
            XS:  2 wallclock secs ( 2.11 usr +  0.03 sys =  2.14 CPU) @ 23.36/s (n=50)
         Rate    PP    XS
    PP 1.18/s    --  -95%
    XS 23.4/s 1876%    --

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
