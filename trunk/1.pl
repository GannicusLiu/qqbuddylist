#!/usr/local/bin/perl
use strict;
use warnings;
use CGI;
use QQBuddyList;

my $cgi = CGI->new();
print $cgi->header('text/html; charset=utf-8');
print QQBuddyList::get_login_page;
