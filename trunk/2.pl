#!/usr/local/bin/perl
use strict;
use warnings;
use CGI;
use QQBuddyList;

use Data::Dumper;
my $buddylist = QQBuddyList::get_buddy_list;
my $cgi = CGI->new();
print $cgi->header('text/html; charset=gb2312');
print Dumper($buddylist);
