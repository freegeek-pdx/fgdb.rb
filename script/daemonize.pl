#!/usr/bin/perl -w

use strict;
use warnings;
use Proc::Daemon;
use File::Spec;

my $program = File::Spec->rel2abs($ARGV[0]);
Proc::Daemon::Init;
exec { $program } @ARGV;
