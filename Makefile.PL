use inc::Module::Install 0.95;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Image/TextMode/Reader/ANSI/XS.pm > README' );
}

perl_version '5.008';

name 'Image-TextMode-Reader-ANSI-XS';
all_from 'lib/Image/TextMode/Reader/ANSI/XS.pm';

requires 'Image::TextMode' => '0.05';

test_requires 'Test::More';

WriteAll;
