#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef PerlIO *	InputStream;

#define S_TXT      0
#define S_CHK_B    1
#define S_WAIT_LTR 2
#define S_END      3

#define WRAP       80
#define TABSTOP    8

static void
store( image, x, y, c, attr, wrap, width, height )
    SV *image;
    int *x;
    int *y;
    char c;
    int attr;
    int wrap;
    int *width;
    int *height;
{
    HV *pixel = newHV();
    hv_store( pixel, "char", 4, newSVpvn( &c, 1 ), 0 );
    hv_store( pixel, "attr", 4, newSViv( attr ), 0 );

    AV *rows = (AV *) SvRV( *hv_fetch( (HV *) SvRV( image ), "pixeldata", 9, 0 ) );

    int newrow = 1;
    AV *row = newAV();
    SV **elem_p = av_fetch( rows, *y, FALSE );

    if( elem_p ) {
        row = (AV *) SvRV( *elem_p );
        newrow = 0;
    }

    av_store( row, *x, newRV_noinc((SV *) pixel ) );

    if( newrow ) {
        av_store( rows, *y, newRV_noinc((SV *) row) );
    }

    if( *x + 1 > *width ){
        *width = *x + 1;
    }

    if( *y + 1 > *height ){
        *height = *y + 1;
    }

    (*x)++;
    if( *x == wrap ) {
        *x = 0; (*y)++;
    }
}

static void
set_attrs( attr, args ) // set the current attribute byte
    int *attr;
    AV *args;
{
    int i;
    int arg;

    for( i = 0; i <= av_len( args ); i++ ) {
        arg = SvIV(* av_fetch( args, i, 0 ) );
        if ( arg == 0 ) {
            *attr = 7 ;
        }
        else if ( arg == 1 ) {
            *attr |= 8;
        }
        else if ( arg == 5 ) {
            *attr |= 128;
        }
        else if ( arg >= 30 && arg <= 37 ) {
            *attr &= 248;
            *attr |= ( arg - 30 );
        }
        else if ( arg >= 40 && arg <= 47 ) {
            *attr &= 143;
            *attr |= ( ( arg - 40 ) << 4 );
        }
    }
}

MODULE = Image::TextMode::Reader::ANSI::XS		PACKAGE = Image::TextMode::Reader::ANSI::XS

PROTOTYPES: DISABLE

SV *
_read( self, image, file, options )
    SV *self
    SV *image
    InputStream file
    HV *options
PREINIT:
    char c;
    int state = S_TXT;
    char argbuf[ 255 ];
    int arg_index = 0;
    int x = 0;
    int y = 0;
    int save_x = 0;
    int save_y = 0;
    int attr = 7;
    int wrap = WRAP;
    int width = 0;
    int height = 0;
    AV *args = newAV();
CODE:
    int i;
    int count;
    sv_2mortal( (SV * ) args );

    // get options
    if( hv_exists( options, "width", 5 ) ) {
        wrap = SvIV(* hv_fetch( options, "width", 5, 0 ) );
    }

    PerlIO_rewind( file );

    while ( state != S_END && ( c = PerlIO_getc( file ) ) != -1 ) {
        switch ( state ) {
            case S_TXT      : // parse text
                switch( c ) {
                    case '\x1a' : state = S_END; break;
                    case '\x1b' : state = S_CHK_B; break;
                    case '\n'   :
                        x = 0; y++;
                    case '\r'   : break;
                    case '\t'   :
                        count = ( x + 1 ) % TABSTOP;
                        if( count ) {
                            count = TABSTOP - count;
                            for ( i = 0; i < count; i++ ) {
                                store( image, &x, &y, ' ', attr, wrap, &width, &height );
                            }
                        }
                        break;
                    default :
                        store( image, &x, &y, c, attr, wrap, &width, &height );
                        break;
                }
                break;
            case S_CHK_B    : // check for a left square bracket
                if( c != '[' ) {
                    store( image, &x, &y, '\x1b', attr, wrap, &width, &height );
                    store( image, &x, &y, c, attr, wrap, &width, &height );
                    state = S_TXT;
                }
                else {
                    state = S_WAIT_LTR;
                }
                break;
            case S_WAIT_LTR : // wait for a letter to exec. a command
                if ( isALPHA( c ) || c == ';' ) {
                    argbuf[arg_index] = 0;
                    av_push( args, newSViv( atoi( argbuf ) ) );
                    arg_index = 0;
                    if( c == ';' )
                        break;
                }

                if ( isALPHA( c ) ) {
                    switch( c ) {
                        case 'm' : // set attributes
                            set_attrs( &attr, args );
                            break;
                        case 'H' : // set position
                        case 'f' :
                            y = av_len( args ) < 0 ? 0 : SvIV(* av_fetch( args, 0, 0 ) );
                            x = av_len( args ) < 1 ? 0 : SvIV(* av_fetch( args, 1, 0 ) );
                            if( !y ) {
                                y = 1;
                            }
                            y--;
                            if( !x ) {
                                x = 1;
                            }
                            x--;
                            break;
                        case 'A' : // move up
                            i = SvIV(* av_fetch( args, 0, 0 ) );
                            if( !i ) i = 1;
                            y -= i;
                            break;
                        case 'B' : // move down
                            i = SvIV(* av_fetch( args, 0, 0 ) );
                            if( !i ) i = 1;
                            y += i;
                            break;
                        case 'C' : // move right
                            i = SvIV(* av_fetch( args, 0, 0 ) );
                            if( !i ) i = 1;
                            x += i;
                            break;
                        case 'D' : // move left
                            i = SvIV(* av_fetch( args, 0, 0 ) );
                            if( !i ) i = 1;
                            x -= i;
                            break;
                        case 's' : // save position
                            save_x = x; save_y = y;
                            break;
                        case 'u' : // restore position
                            x = save_x; y = save_y;
                            break;
                        case 'J' : // clear screen
                            ENTER;
                            SAVETMPS;
                            PUSHMARK( SP );
                            PUSHs( image );
                            PUTBACK;
                            call_method( "clear_screen", G_DISCARD );
                            FREETMPS;
                            LEAVE;

                            width = 0;
                            height = 0;

                            break;
                        case 'K' : // clear line
                            ENTER;
                            SAVETMPS;
                            PUSHMARK( SP );
                            PUSHs( image );
                            PUSHs( sv_2mortal( newSViv( y ) ) );
                            PUTBACK;
                            call_method( "clear_line", G_DISCARD );
                            FREETMPS;
                            LEAVE;
                            break;
                        default:
                            break;
                    }
                    av_clear( args );
                    state = S_TXT;
                    break;
                }
                argbuf[ arg_index ] = c; 
                arg_index++;
                break;
            case S_END      : // done parsing
            default         : break;
        }
    }

    // set width + height of the image
    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    PUSHs( image );
    PUSHs( sv_2mortal( newSViv( width ) ) );
    PUTBACK;
    call_method( "width", G_DISCARD );
    FREETMPS;
    LEAVE;

    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    PUSHs( image );
    PUSHs( sv_2mortal( newSViv( height ) ) );
    PUTBACK;
    call_method( "height", G_DISCARD );
    FREETMPS;
    LEAVE;

    RETVAL = SvREFCNT_inc( image );
OUTPUT:
    RETVAL
