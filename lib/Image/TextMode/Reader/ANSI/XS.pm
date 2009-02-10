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

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
