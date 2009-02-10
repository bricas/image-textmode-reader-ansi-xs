use inc::Module::Install 0.77;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Image/TextMode/Reader/ANSI/XS.pm > README' );
}

perl_version '5.008';

name 'Image-TextMode-Reader-ANSI-XS';
all_from 'lib/Image/TextMode/Reader/ANSI/XS.pm';

requires 'Image::TextMode';

test_requires 'Test::More';

WriteAll;
