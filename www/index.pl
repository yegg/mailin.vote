#!/usr/bin/perl
use strict;
use warnings;

use GeoIP2::Database::Reader;
use CGI ':standard';
use Date::Calc qw (Add_Delta_Days Delta_Days Today_and_Now Date_to_Text_Long Date_to_Text Decode_Date_US Day_of_Week_to_Text Month_to_Text Day_of_Week Day_of_Week_Abbreviation);

my $is_debug = 0;
my $is_stage = 0;
$is_stage = 1 if $is_debug;

my $data_file = 'state.data';
$data_file = 'state.data.stage' if $is_stage;

my $geoip2_client = GeoIP2::Database::Reader->new(
    file    => '/home/yegg/geoip/GeoIP2-City_20200428/GeoIP2-City.mmdb',
    locales => [ 'en' ]
);
my $ip = $ENV{'REMOTE_ADDR'} || '18.250.0.1';
my $geoip2_state = '';
my $geoip2_country = '';
{
    my $geoip2_results = $geoip2_client->city( ip => $ip );
    $geoip2_state = $geoip2_results->most_specific_subdivision();
    $geoip2_state = $geoip2_state->iso_code() if $geoip2_state;
    $geoip2_country = $geoip2_results->country();
    $geoip2_country = $geoip2_country->iso_code if $geoip2_country;
}
#$geoip2_country = 'UK';

my $param_state = param('state') || '';

my %state_data = ();
{
    my $state = '';
    open(IN,"<$data_file");
    LINE: while (my $line = <IN>) {
	chomp($line);
	$state = $line;
#	print qq($state\n);

	my $state_name = <IN>;
	chomp($state_name);
	$state_data{$state}{'name'} = $state_name;

	my $state_excuse = <IN>;
	chomp($state_excuse);
	$state_data{$state}{'excuse'} = $state_excuse;

	my $state_cutoff = <IN>;
	chomp($state_cutoff);
	$state_data{$state}{'cutoff'} = $state_cutoff;

	my $state_deadline = <IN>;
	chomp($state_deadline);
	$state_data{$state}{'deadline'} = $state_deadline;

	my $state_form_url = <IN>;
	chomp($state_form_url);
	$state_data{$state}{'form_url'} = $state_form_url;

	my $state_info_url = <IN>;
	chomp($state_info_url);
	$state_data{$state}{'info_url'} = $state_info_url;
	
	my $state_apply_url = <IN>;
	chomp($state_apply_url);
	$state_data{$state}{'apply_url'} = $state_apply_url;

	my $state_register_cutoff = <IN>;
	chomp($state_register_cutoff);
	$state_data{$state}{'register_cutoff'} = $state_register_cutoff;

	my $state_register_url = <IN>;
	chomp($state_register_url);
	$state_data{$state}{'register_url'} = $state_register_url;

	my $state_register_form_url = <IN>;
	chomp($state_register_form_url);
	$state_data{$state}{'register_form_url'} = $state_register_form_url;
	
	my $tmp_line = <IN>;
    }
    close(IN);
}

#die $state_data{'PA'}{'name'};
$param_state = '' if $param_state && ! exists $state_data{$param_state};
 
my $state = $param_state || '';
$state = $geoip2_state if !$state && $geoip2_country && $geoip2_country eq 'US' && $geoip2_state;
#$state = 'OR';

my $state_name = '';
my $state_excuse = '';
my $state_cutoff = '';
my $state_deadline = '';
my $state_form_url = '';
my $state_info_url = '';
my $state_apply_url = '';
my $state_register_cutoff = '';
my $state_register_url = '';
my $state_register_form_url = '';

if ($state && exists $state_data{$state}) {
    $state_name = $state_data{$state}{'name'};

    $state_excuse = $state_data{$state}{'excuse'};
    {
	if ($state_excuse eq 'N') {
	    $state_excuse = qq(No reason is needed to apply);
	} else {
	    $state_excuse = qq(A reason is needed to apply);
	}
    };
    
    $state_cutoff = $state_data{$state}{'cutoff'};
    #$state_cutoff = '45 days' if $is_debug;
    {
	
	
	if ($state_cutoff eq '0') {
	    $state_cutoff = '';
	    
	} else {
	    
	    my ($tmp_year, $tmp_month, $tmp_day) = ('','','');
	    
	    if ($state_cutoff =~ /(\d+) days/) {
		my $cutoff_days = $1;
		($tmp_year, $tmp_month, $tmp_day) = Add_Delta_Days(2020,11,3,-$cutoff_days);
		
	    } else {
	    ($tmp_year, $tmp_month, $tmp_day) = Decode_Date_US($state_cutoff);
	    }
	    
	    my $tmp_long = Date_to_Text($tmp_year, $tmp_month, $tmp_day, 1);
	    $tmp_long = Day_of_Week_Abbreviation(Day_of_Week($tmp_year, $tmp_month, $tmp_day)) . ' ' . substr(Month_to_Text($tmp_month),0,3) . ' ' . $tmp_day;
	    
	    my ($now_year,$now_month,$now_day) = Today_and_Now();
	    
	    my $delta_days = Delta_Days($now_year, $now_month, $now_day, $tmp_year,$tmp_month,$tmp_day);
	    
	    if ($delta_days<0) {
		$state_cutoff = '';
		
	    } else {
		$state_cutoff = qq( wait <br><b>$delta_days days</b> (until $tmp_long), then);
	    }
	    
	}
	
    } ;
    
    $state_deadline = $state_data{$state}{'deadline'};
    {
	if ($state_deadline eq 'XXX') {
	    $state_deadline = '';
	    
	} else {
	    
	    my ($tmp_year, $tmp_month, $tmp_day) = ('','','');
	    
	    if ($state_deadline =~ /(\d+) days/) {
		my $cutoff_days = $1;
		#	    warn qq($cutoff_days);
		($tmp_year, $tmp_month, $tmp_day) = Add_Delta_Days(2020,11,3,-$cutoff_days);
		
	    } else {
		($tmp_year, $tmp_month, $tmp_day) = Decode_Date_US($state_deadline);
	    }
	    
	    #	warn qq($tmp_year-$tmp_month-$tmp_day);
	    my $tmp_long = Date_to_Text_Long($tmp_year, $tmp_month, $tmp_day, 1);
	    
	    my $delta_days = Delta_Days($tmp_year, $tmp_month, $tmp_day, 2020,11,3);
	    
	    $state_deadline = qq($tmp_long, $delta_days day); 
	    $state_deadline .= $delta_days>1 ? 's' : '';
	    $state_deadline .= qq( before the election);
	    
	    if ($delta_days == 0) {
		$state_deadline = 'There is no deadline';
	    }
	}
    
    };

   $state_form_url = $state_data{$state}{'form_url'};
    {
	if ($state_form_url eq 'XXX') {
	    $state_form_url = '';
	}
	
    };
    
    $state_info_url = $state_data{$state}{'info_url'};
    {
	if ($state_info_url eq 'XXX') {
	    $state_info_url = '';
	}
	
    };
    
    $state_apply_url = $state_data{$state}{'apply_url'} || '';
    {
	if ($state_apply_url eq 'Y') {
	    $state_apply_url = '';
	    
	} elsif ($state_apply_url =~ /^http/) {
	    $state_apply_url = qq(<a href="$state_apply_url">this site</a>);
	    
	} else {
	    $state_apply_url = '';
	}
    };
    if (!$state_apply_url && $state_form_url) {
	$state_apply_url = qq(<a href="$state_form_url">this form</a>);
    }
    
    $state_register_cutoff = $state_data{$state}{'register_cutoff'} || '';
    $state_register_url = $state_data{$state}{'register_url'} || '';
    $state_register_form_url = $state_data{$state}{'register_form_url'} || '';
    {
	if ($state_register_url eq 'N') {
	    $state_register_url = '';
	    
	} elsif ($state_register_url =~ /^http/) {
	    $state_register_url = qq(<a href="$state_register_url">this site</a>);
	    
	} else {
	    $state_register_url = '';
	}
    };
    if (!$state_register_url && $state_register_form_url) {
	$state_register_url = qq(<a href="$state_register_form_url">this form</a>);
    }
}

my $title = 'Vote by Mail 2020';
$title .= ": $state_name" if $param_state;

my $heading = 'Vote by Mail';
$heading .= ": <br> $state_name" if $state_name;

my $description = 'How to vote by mail in the 2020 U.S. Presidential Election';
$description = qq(How to vote by mail in $state_name the 2020 U.S. Presidential Election) if $param_state;

print "Content-type:text/html\n\n";
print <<EOH
<!DOCTYPE HTML>
<html lang="en"><head>
<link rel="apple-touch-icon" sizes="57x57" href="/favicon/apple-icon-57x57.png">
<link rel="apple-touch-icon" sizes="60x60" href="/favicon/apple-icon-60x60.png">
<link rel="apple-touch-icon" sizes="72x72" href="/favicon/apple-icon-72x72.png">
<link rel="apple-touch-icon" sizes="76x76" href="/favicon/apple-icon-76x76.png">
<link rel="apple-touch-icon" sizes="114x114" href="/favicon/apple-icon-114x114.png">
<link rel="apple-touch-icon" sizes="120x120" href="/favicon/apple-icon-120x120.png">
<link rel="apple-touch-icon" sizes="144x144" href="/favicon/apple-icon-144x144.png">
<link rel="apple-touch-icon" sizes="152x152" href="/favicon/apple-icon-152x152.png">
<link rel="apple-touch-icon" sizes="180x180" href="/favicon/apple-icon-180x180.png">
<link rel="icon" type="image/png" sizes="192x192"  href="/favicon/android-icon-192x192.png">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="96x96" href="/favicon/favicon-96x96.png">
<link rel="icon" type="image/png" sizes="16x16" href="/favicon/favicon-16x16.png">
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<meta name="description" content="$description"/>
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="$title">
<meta name="twitter:image" content="https://mailin.vote/favicon/apple-icon-120x120.png">
<meta name="twitter:site" content="">
<meta name="twitter:description" content="$description">
<meta property="og:site_name" content="Vote by Mail 2020" />
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="https://mailin.vote/favicon/apple-icon-120x120.png" />
<meta property="og:image:width" content="180" />
<meta property="og:image:height" content="180" />
<meta name="msapplication-TileColor" content="#ffffff">
<meta name="msapplication-TileImage" content="/ms-icon-144x144.png">
<meta name="theme-color" content="#ffffff">
<meta http-equiv="content-language" content="en">
<title>$title</title>
<link rel="stylesheet" type="text/css" href="css/base.css">
<style type="text/css">
</style>
</head>

<body>
<a href="/"><img class="emoji" src="img/mailbox.png" alt="Open and raised flag mailbox with envelope"></a>

<h1>$heading</h1>
<h2>U.S. Presidential Election (Nov 3, 2020)</h2>

<div id="answers">
<ul>
EOH
    ;

if ($state_name) {

    if ($state eq 'ND') {
	print <<EOH
<li>Use <b>$state_apply_url</b> to get a mail-in ballot.
EOH
	    ;
    
    } elsif ($state_register_url eq $state_apply_url) {
	print <<EOH
<li>Use <b>$state_apply_url</b> to get a mail-in ballot,
which is the same site for voter registration.
EOH
	    ;
    
    } else {
    
	print <<EOH
<li>If you are not registered to vote, 
<br>use <b>$state_register_url</b> to register first.

<li>If you are registered to vote, 
$state_cutoff
<br>use <b>$state_apply_url</b> to get a mail-in ballot.
EOH
	    ;

    }


    print <<EOH
<li>$state_excuse;
<br>see <b><a href="$state_info_url">this page</a></b> for more info.
EOH
	;

    print <<EOH
</ul>
</div>
<div id="states">
States: 
EOH
    ;

    foreach my $tmp_state (sort {$a cmp $b} keys %state_data) {
	print qq(<a href="/?state=$tmp_state">), $tmp_state, qq(</a> );
    }
    

} else {

        print <<EOH
<li>Select a state:
EOH
	;

	foreach my $tmp_state (sort {$state_data{$a}{"name"} cmp $state_data{$b}{"name"}} keys %state_data) {
	    print qq(<a href="/?state=$tmp_state">), $state_data{$tmp_state}{"name"}, qq(</a> );
	}
	
}
    

print <<EOH
</div>

<footer>
<div id="footer">
Note: We update this site, but it could become dated.
Please send feedback to info\@mailin.vote or 
<a href="https://github.com/yegg/mailin.vote/issues/new">add an issue</a>
on <a href="https://github.com/yegg/mailin.vote">GitHub</a>.

<br><br>
Privacy: We don't collect or share personal information. 
As such, we don't use any third-party services on this site,
nor do we store IP addresses or user agents in our access logs.
</footer>
EOH
    ;

#print scalar(keys %state_data);

print <<EOH
</div>
</body></html>
EOH
    ;

#FCGI Params
#foreach my $key (sort(keys %ENV)) {
#  print "$key = $ENV{$key}<br>\n";
#}
