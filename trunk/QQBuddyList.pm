package QQBuddyList;
use strict;
use warnings;
use LWP;
use IO::File;
use CGI;
use URI::Escape;
use HTTP::Cookies;

our @EXPORT = qw(get_login_page get_buddy_list);
use base qw(Exporter);

sub get_login_page {
	my %html = (
		'safejsurlreg' => '(http:\/\/res.mail.qq.com\/zh_CN\/htmledition[0-9]+\/js\/safeauth.js)',
		'imgurlreg' => '(http:\/\/ptlogin2.qq.com\/getimage\?aid=[0-9]+)',
		'mailserverreg' => 'form.*?http:\/\/(m[0-9]+).mail.qq.com\/cgi-bin\/login\?sid=0,2,zh_CN',
		'template' => 'qqlogin.txt',
		'verifyimgfile' => '../data/img/vimg.jpeg',
		'verifyimg' => '/img/vimg.jpeg',
		'verifysession' => '',
		'safejavascript' => '',
		'mailserver' => '',
		'pagecode' => ''
	);
	my $ua = LWP::UserAgent->new('agent' => 'Mozilla/5.0');
	my $page_response = $ua->get('http://mail.qq.com');
	die 'Http get failed', "\n" unless $page_response->is_success;
	my $vimg_url = $1 if($page_response->content =~ m/$html{'imgurlreg'}/);
	$html{'mailserver'} = $1 if($page_response->content =~ m/$html{'mailserverreg'}/);
	$html{'safejavascript'} = $1 if($page_response->content =~ m/$html{'safejsurlreg'}/);
	$ua = LWP::UserAgent->new('agent' => 'Mozilla/5.0');
	my $vimg_response = $ua->get($vimg_url);
	$html{'verifysession'} = (split /; /, $vimg_response->headers->header('set-cookie'))[0];
	my $vimg_file = IO::File->new($html{'verifyimgfile'}, 'w')
	  || die 'Cannot create verify image', "\n";
	binmode($vimg_file);
	print $vimg_file $vimg_response->content;
	$vimg_file->close;
	my $page_file = IO::File->new($html{'template'}, 'r')
		|| die 'Cannot read template', "\n";
	for(<$page_file>) {
		s/SAFEJAVASCRIPT/$html{'safejavascript'}/g;
		s/VERIFYIMG/$html{'verifyimg'}/g;
		s/VERIFYSESSION/$html{'verifysession'}/g;
		my $ts = time;
		s/TIMESTAMP/$ts/g;
		s/MAILSERVER/$html{'mailserver'}/g;
		$html{'pagecode'} .= $_;
	}
	$page_file->close;
	$html{'pagecode'};
}

sub get_buddy_list {
	my $q = CGI->new();
	die 'Cannot parse the parameters'."\n" unless $q->param;
	my %info = (
		'loginurl' => 'http://'.$q->param('mailserver').'.mail.qq.com/cgi-bin/login?sid=0,2,zh_CN',
		'cookie' => rand().'; '.$q->param('verifysession'),
		'urlhead' => 'http://'.$q->param('mailserver').'.mail.qq.com/cgi-bin/',
		'sidreg' => '"frame_html\?sid=(.*?)"',
		'sid' => '',
		'addressurl' => 'addr_listall?sid=SID&encode_type=js&show_type=hot&all_data=1&level=0&qq=1&t=quickaddr&sorttype=Freq&s=AutoComplete&category=hot&sw=140',
		'hotreg' => 'g_hotAddrs\s+=\s+\[(.*?)\];',
		'unhotreg' => 'g_addrs\s+=\s+\[(.*?)\];'
	);
	my $content = '';
	$content .= $_.'='.URI::Escape::uri_escape($q->param($_)).'&' for $q->param;
	my $ua = LWP::UserAgent->new('agent' => 'Mozilla/5.0');
	my $req = HTTP::Request->new(
		'POST' => $info{'loginurl'},
		[
			'Cookie' => $info{'cookie'},
			'Content-Type' => 'application/x-www-form-urlencoded'
		],
		$content
	);
	my $login_response = $ua->request($req);
	die 'Http post failed', "\n" unless $login_response->is_success;
	my $cookie_jar = HTTP::Cookies->new;
	$cookie_jar->extract_cookies($login_response);
	$info{'sid'} = $1 if($login_response->content =~ m/$info{'sidreg'}/);
	$info{'addressurl'} =~ s/SID/$info{'sid'}/g;
	$ua = LWP::UserAgent->new('agent' => 'Mozilla/5.0');
	$ua->cookie_jar($cookie_jar);
	$login_response = $ua->get($info{'urlhead'}.$info{'addressurl'});
	die 'Http get failed', "\n" unless $login_response->is_success;
	my $hot_address = $1 if($login_response->content =~ m/$info{'hotreg'}/s);
	my $unhot_address = $1 if($login_response->content =~ m/$info{'unhotreg'}/s);
	my $address = $hot_address.$unhot_address;
	$address =~ s/\s//gs;
	$address;
}
1;
__END__

=head1 NAME

	QQBuddyList - Utility implementation of QQ buddylist import.

=head1 SYNOPSIS

	#step 1: show qq login page
	use strict;
	use warnings;
	use CGI;
	use QQBuddyList;
	my $cgi = CGI->new();
	print $cgi->header('text/html; charset=utf-8');
	print QQBuddyList::get_login_page;

	#step 2: get qq buddylist
	use strict;
	use warnings;
	use CGI;
	use Data::Dumper;
	my $buddylist = QQBuddyList::get_buddy_list;
	my $cgi = CGI->new();
	print $cgi->header('text/html; charset=gb2312');
	print Dumper($buddylist);

=head1 DESCRIPTION

	QQBuddyList is created to import user's buddylist of QQ to the web application.
	The module contains a template login page named "qqlogin.txt", where you could add/modify CSS/HTML for a nice look.
	The template file, "qqlogin.txt" ought to be put in the script file directory path.

=head1 AUTHOR

	zhangsanji@yahoo.cn

=head1 COPYRIGHT

	Copyright 2009-2011.

=cut
