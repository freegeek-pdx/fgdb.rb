#!/usr/bin/perl

BEGIN {
    use File::Basename;
    push @INC, dirname($0);
}

use LibraryLabels;

gen_pdf($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);
