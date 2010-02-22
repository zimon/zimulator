#
# Package: DebugMessages
#
# Overwrites warn and die function to print a verbose stacktrace
#
# Usage:
# Import this file with
# use lib "path/to/my/modules"
# use DebugMessages fatal => x, warnings => y, level => z, exit_on_warning => b;
#
# where "path/to/my/modules" is replaced with the path to this file.
#
# You can use the following variables:
# b - 1 to exit the program when a warning occures.
# x - number of lines to print before and after the line that produced the error
# y - number of lines to print before and after the line that produced the warning
# z - depth for stacktrace (default is 3)

package DebugMessages;

use strict;
use warnings;

##
# Is called when this package is used somewhere. Overwrites warn and die functions
sub import {
    my ( $class, %args ) = @_;
    my $level = $args{level};
    my $exit_on_warning = $args{exit_on_warning};
    $level = 3 unless defined $level;
    $exit_on_warning = 0 unless defined $exit_on_warning;

    $SIG{__DIE__} = sub { DB::report( shift, $args{fatal}, $level ); exit; } if $args{fatal};
    $SIG{__WARN__} = sub { DB::report( shift, $args{warnings}, $level ); exit if $exit_on_warning; } if $args{warnings};
}

package DB;

##
# Collects all informations for stacktrace. Calls <showSource> to get the lines and prints the stacktrace to STDERR.
#
# PARAMETERS:
# $message - errormessage that came from the program
# $size - number of lines to print before and after the error line
# $level - depth of the stacktrace
sub report {
    my ( $message, $size, $level ) = @_;
    $level ||= 1;
    my @callValueList    = ();
    my @callArgumentList = ();
    for ( my $i = 1 ; $i <= $level + 1 ; $i++ ) {
        my @callValues    = caller($i);
        my @callArguments = @DB::args;
        push( @callValueList,    \@callValues );
        push( @callArgumentList, \@callArguments );
    }
    my %calls = ( CALLVALUES => \@callValueList, CALLARGUMENTS => \@callArgumentList );

    print STDERR showSource( $size, %calls );
}

##
# Get all needed lines from program files and genrate output
#
# PARAMETERS:
# $size - number of lines to print before and after error line
# @calls - array with references to caller returned arrays and function arguments
#
# RETURNS:
# string with stacktrace
sub showSource {
    my $size  = shift;
    my %calls = @_;

    my @text;
    my @callValueList    = @{ $calls{CALLVALUES} };
    my @callArgumentList = @{ $calls{CALLARGUMENTS} };
    my $tab              = "";
    my $i                = 0;
    local $.;

    do {
        my ( $package, $fileName, $line, $subroutine ) = @{ $callValueList[$i] };
        my @arguments = @{ $callArgumentList[$i] };
        if ( defined $fileName ) {    # next is not possible in do-while loop
            my $fh;

            # Open source file or return all informations till now
            return "\n$subroutine(" . join( ",", @arguments ) . 
              ") at line $line in file $fileName (package $package):\nCan not print lines because opening file $fileName is not possible.\n\n" 
              unless open( $fh, $fileName );

            my $start = $line - $size;
            my $end   = $line + $size;

            push( @text, "\nError Message: " . join( ",", @arguments ) . "\n" ) if $i == 0;

            push( @text, "\n$tab $subroutine(" . join( ",", @arguments ) . ") at line $line in file $fileName (package $package):\n" ) if $i > 0;

            while (<$fh>) {
                next unless $. >= $start;
                last if $. > $end;
                my $highlight = $. == $line ? '* ' : '  ';
                push( @text, sprintf( "%s %s%04d: %s", $tab, $highlight, $., $_ ) );
            }
            $tab .= "  ";
        }
        $i++;
    } while ( $i < $#callValueList );
    return join( '', @text, "\n\n" );
}

1;
