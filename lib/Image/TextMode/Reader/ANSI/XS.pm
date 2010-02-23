package Image::TextMode::Reader::ANSI::XS;

use strict;
use warnings;

our $VERSION = '0.03';

use base ( 'Image::TextMode::Reader', 'DynaLoader' );

bootstrap Image::TextMode::Reader::ANSI::XS $VERSION;

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

Versus Image::TextMode 0.05, parsing 74K of ANSI 25 times yields:

    Benchmark: timing 25 iterations of PP, XS...
            PP: 24 wallclock secs (23.84 usr +  0.00 sys = 23.84 CPU) @  1.05/s (n=25)
            XS:  1 wallclock secs ( 1.00 usr +  0.00 sys =  1.00 CPU) @ 25.00/s (n=25)
         Rate    PP    XS
    PP 1.05/s    --  -96%
    XS 25.0/s 2284%    --

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
