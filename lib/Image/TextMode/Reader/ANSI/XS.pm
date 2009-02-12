package Image::TextMode::Reader::ANSI::XS;

use strict;
use warnings;

our $VERSION = '0.01';

use base ( 'Image::TextMode::Reader', 'DynaLoader' );

bootstrap Image::TextMode::Reader::ANSI::XS $VERSION;

=head1 NAME

Image::TextMode::Reader::ANSI::XS - Fast ANSI image parsing

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INSTALLATION

	perl Makefile.PL
	make
	make test
	make install

=head1 METHODS

=head1 BENCHMARK

Parsing 74K of ANSI 25 times yields:

    Benchmark: timing 25 iterations of PP, XS...
            PP: 24 wallclock secs (23.84 usr +  0.00 sys = 23.84 CPU) @  1.05/s (n=25)
            XS:  1 wallclock secs ( 1.00 usr +  0.00 sys =  1.00 CPU) @ 25.00/s (n=25)
         Rate    PP    XS
    PP 1.05/s    --  -96%
    XS 25.0/s 2284%    --

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
