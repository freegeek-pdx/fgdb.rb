#!/usr/bin/perl

# TODO: have post-update run --pending on trunk and --close on the
# tags. and make sure that ./script/release gets updated correctly wrt
# order.

use strict;
use warnings;

my ($status, $message);

open FOO, "dpkg-parsechangelog|";
my @list = <FOO>;
close FOO;

my $pkg = @{[split(/ /, $list[0])]}[1];
my $version = @{[split(/ /, $list[1])]}[1];
chomp $pkg;

if($ARGV[0] eq "--pending") {
  $status = "pending";
  $message = "This bug has been fixed in the latest work in progress version of $pkg. It will soon be released, and then this ticket will be closed.";
} elsif($ARGV[0] eq "--close") {
  $status = "resolved";
  $message = "The new version ($version) of $pkg with this bug fixed has been released.";
} else {
  die("Usage: $0 --pending|--close");
}

use Text::Wrap;

$Text::Wrap::columns = 72;

$message = wrap("", "", $message);
$message .= "\n\n";
$message .= "Here is the relevant changelog entry:\n";

use RT::Client::REST;

my $password = `cat ~/.rt_password`;
chomp $password;
my $username = getlogin();

my $rt = RT::Client::REST->new(
  server => 'http://todo.freegeek.org/',
);
$rt->login(username => $username, password => $password);

my $in_entry = 0;
my @entries;
foreach(@list) {
  if(/^   \*/) {
    push @entries, $_;
    $in_entry = 1;
  } elsif(/^ \./) {
    $in_entry = 0;
  } elsif($in_entry) {
    $entries[scalar(@entries) - 1] .= $_;
  }
}

@entries = map {s/^  //; $_} @entries;

sub get_closes {
  return grep /\d/, split(/\D/, @{[shift =~ /\(closes:(.*)\)/sig]}[0] || 0);
}

use RT::Client::REST::Ticket;

foreach my $entry(@entries) {
  my @closes = get_closes($entry);
  @closes = grep /[1-9]/, @closes;
  foreach my $bug(@closes) {
    my $ticket = RT::Client::REST::Ticket->new(rt => $rt, id => $bug)->retrieve;
    if($ticket->status ne $status) {
      my $msg = $message . $entry;
      $rt->correspond(ticket_id => $ticket->id, message => $msg);
      $ticket->status($status);
      $ticket->store();
    }
  }
}

