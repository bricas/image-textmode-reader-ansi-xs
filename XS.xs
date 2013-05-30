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
    char *feature;
    SV **temp_pv;
    sv_2mortal( (SV * ) args );

    // render options hashref
    HV *render_opts = (HV *) SvRV( *hv_fetch( (HV *) SvRV( image ), "render_options", 14, 0 ) );

    // get options
    if( hv_exists( options, "width", 5 ) ) {
        wrap = SvIV(* hv_fetch( options, "width", 5, 0 ) );
    }

    if( !wrap ) {
        wrap = WRAP;
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
                    av_push( args, newSVpv( argbuf, 0 ) );
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
                            temp_pv = av_fetch( args, 0, TRUE );
                            y = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            temp_pv = av_fetch( args, 1, TRUE );
                            x = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            y--;
                            x--;
                            if( y < 0 ) y = 0;
                            if( x < 0 ) x = 0;
                            break;
                        case 'A' : // move up
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            y -= i;
                            if( y < 0 ) y = 0;
                            break;
                        case 'B' : // move down
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            y += i;
                            break;
                        case 'C' : // move right
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x += i;
                            break;
                        case 'D' : // move left
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x -= i;
                            if( x < 0 ) x = 0;
                            break;
                        case 'E' : // next line
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x = 0;
                            y += i;
                            break;
                        case 'F' : // previous line
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x = 0;
                            y -= i;
                            if( y < 0 ) y = 0;
                            break;
                        case 'G' : // horizontal move
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x = i - 1;
                            break;
                        case 'h' : // feature on
                            feature = av_len( args ) < 0 ? "" : SvPV_nolen(* av_fetch( args, 0, 0 ) );
                            if( strcmp( feature, "?33" ) == 0 ) {
                                hv_store( render_opts, "blink_mode", 10, newSViv( 0 ), 0 );
                            }
                            break;
                        case 'l' : // feature off
                            feature = av_len( args ) < 0 ? "" : SvPV_nolen(* av_fetch( args, 0, 0 ) );
                            if( strcmp( feature, "?33" ) == 0 ) {
                                hv_store( render_opts, "blink_mode", 10, newSViv( 1 ), 0 );
                            }
                            break;
                        case 's' : // save position
                            save_x = x; save_y = y;
                            break;
                        case 'u' : // restore position
                            x = save_x; y = save_y;
                            break;
                        case 'J' : // clear screen
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 0;

                            if( !i ) {
                                int row;
                                int next = y + 1;
                                for( row = 1; row <= height - next + 1; row++ ) {
                                    ENTER;
                                    SAVETMPS;
                                    PUSHMARK( SP );
                                    XPUSHs( image );
                                    XPUSHs( sv_2mortal( newSViv( next ) ) );
                                    PUTBACK;
                                    call_method( "delete_line", G_DISCARD | G_VOID );
                                    SPAGAIN;
                                    FREETMPS;
                                    LEAVE;
                                    height--;
                                }

                                ENTER;
                                SAVETMPS;
                                PUSHMARK( SP );
                                XPUSHs( image );
                                XPUSHs( sv_2mortal( newSViv( y ) ) );
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( x ) );
                                av_store( cols, 1, newSViv( -1 ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                                PUTBACK;
                                call_method( "clear_line", G_DISCARD | G_VOID );
                                SPAGAIN;
                                FREETMPS;
                                LEAVE;
                            }
                            else if( i == 1 ) {
                                int row;
                                for( row = 0; row < y; row++ ) {
                                    ENTER;
                                    SAVETMPS;
                                    PUSHMARK( SP );
                                    XPUSHs( image );
                                    XPUSHs( sv_2mortal( newSViv( row ) ) );
                                    PUTBACK;
                                    call_method( "clear_line", G_DISCARD | G_VOID );
                                    SPAGAIN;
                                    FREETMPS;
                                    LEAVE;
                                }

                                ENTER;
                                SAVETMPS;
                                PUSHMARK( SP );
                                XPUSHs( image );
                                XPUSHs( sv_2mortal( newSViv( y ) ) );
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( 0 ) );
                                av_store( cols, 1, newSViv( x ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                                PUTBACK;
                                call_method( "clear_line", G_DISCARD | G_VOID );
                                SPAGAIN;
                                FREETMPS;
                                LEAVE;
                            }
                            else if( i == 2 ) {
                                ENTER;
                                SAVETMPS;
                                PUSHMARK( SP );
                                XPUSHs( image );
                                PUTBACK;
                                call_method( "clear_screen", G_DISCARD | G_VOID );
                                SPAGAIN;
                                FREETMPS;
                                LEAVE;
                                width = 0;
                                height = 0;
                                x = 0;
                                y = 0;
                            }
                            break;
                        case 'K' : // clear line
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 0;

                            ENTER;
                            SAVETMPS;
                            PUSHMARK( SP );
                            XPUSHs( image );
                            XPUSHs( sv_2mortal( newSViv( y ) ) );

                            if( !i ) {
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( x ) );
                                av_store( cols, 1, newSViv( -1 ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                            }
                            else if( i == 1 ) {
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( 0 ) );
                                av_store( cols, 1, newSViv( x ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                            }
                            else if( i == 2 ) { // no additional args
                            }

                            PUTBACK;
                            call_method( "clear_line", G_DISCARD | G_VOID );
                            SPAGAIN;
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
    XPUSHs( image );
    XPUSHs( sv_2mortal( newSViv( width ) ) );
    PUTBACK;
    call_method( "width", G_DISCARD | G_VOID );
    SPAGAIN;
    FREETMPS;
    LEAVE;

    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    XPUSHs( image );
    XPUSHs( sv_2mortal( newSViv( height ) ) );
    PUTBACK;
    call_method( "height", G_DISCARD | G_VOID );
    SPAGAIN;
    FREETMPS;
    LEAVE;

    RETVAL = SvREFCNT_inc( image );
OUTPUT:
    RETVAL
