#!/usr/bin/perl

BEGIN {
    use File::Basename;
    push @INC, dirname($0);
}

use LibraryLabels;

print join(",", get_number($ARGV[0]));
