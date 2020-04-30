#!/usr/bin/perl
use strict;
use warnings;

use GeoIP2::WebService::Client;
use CGI ':standard';
use Date::Calc qw (Add_Delta_Days Delta_Days Today_and_Now Date_to_Text_Long Decode_Date_US);

my $debug = 0;
my $is_stage = 0;
$is_stage = 1 if $ENV && $ENV{'SCRIPT_NAME'} =~ /stage/i;

my $data_file = 'state.data';
$data_file = 'stage.data.stage' if $is_stage;

my $geoip2_client = GeoIP2::WebService::Client->new(
    account_id  => 289360,
    license_key => 'S0EmUDB3wEnlkqS0',
    );
my $ip = $ENV{'REMOTE_ADDR'} || '18.250.0.1';
my $geoip2_state = 'MA';
{
    my $geoip2_results = $geoip2_client->insights( ip => $ip );
    my $geoip2_subdivision = $geoip2_results->most_specific_subdivision() || '';
    $geoip2_state = $geoip2_subdivision->iso_code() if $geoip2_subdivision;
}

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
	
	my $state_apply_online = <IN>;
	chomp($state_apply_online);
	$state_data{$state}{'apply_online'} = $state_apply_online;

	my $tmp_line = <IN>;
    }
    close(IN);
}

#die $state_data{'PA'}{'name'};
$param_state = '' if $param_state && ! exists $state_data{$param_state};
 
my $state = $param_state || $geoip2_state || 'FL';
my $state_name = $state_data{$state}{'name'};

my $state_excuse = $state_data{$state}{'excuse'};
{
    $state_excuse = ($state_excuse eq 'N') ? 'No' : 'Yes';
};

my $state_cutoff = $state_data{$state}{'cutoff'};
#$state_cutoff = '45 days' if $debug;
{


    if ($state_cutoff eq '0') {
	$state_cutoff = 'Yes';

    } else {

	my ($tmp_year, $tmp_month, $tmp_day) = ('','','');
	
	if ($state_cutoff =~ /(\d+) days/) {
	    my $cutoff_days = $1;
	    ($tmp_year, $tmp_month, $tmp_day) = Add_Delta_Days(2020,11,3,-$cutoff_days);

	} else {
	    ($tmp_year, $tmp_month, $tmp_day) = Decode_Date_US($state_cutoff);
	}

	my $tmp_long = Date_to_Text_Long($tmp_year, $tmp_month, $tmp_day, 1);
	
	my ($now_year,$now_month,$now_day) = Today_and_Now();
	
	my $delta_days = Delta_Days($now_year, $now_month, $now_day, $tmp_year,$tmp_month,$tmp_day);

	if ($delta_days<0) {
	    $state_cutoff = 'Yes';

	} else {
	    $state_cutoff = qq(No, but you can sign up in $delta_days days on $tmp_long);
	}

    }
	
} ;

my $state_deadline = $state_data{$state}{'deadline'};
{
    if ($state_deadline eq 'XXX') {
	$state_deadline = '';

    } else {
	my ($tmp_year, $tmp_month, $tmp_day) = Decode_Date_US($state_deadline);
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

my $state_form_url = $state_data{$state}{'form_url'};
{
    if ($state_form_url eq 'XXX') {
	$state_form_url = '';
    }
    
};

my $state_info_url = $state_data{$state}{'info_url'};
{
    if ($state_info_url eq 'XXX') {
	$state_info_url = '';
    }
    
};

my $state_apply_online = $state_data{$state}{'apply_online'};
{
    if ($state_apply_online eq 'Y') {
	$state_apply_online = 'Yes';

    } elsif ($state_apply_online =~ /^http/) {
	$state_apply_online = qq(Yes, <a href="$state_apply_online">here</a>);

    } else {
	$state_apply_online = 'No';
    }
};
  
print "Content-type:text/html\n\n";
print <<EOH
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Vote by Mail 2020</title>
<link rel="stylesheet" type="text/css" href="css/base.css">
<style type="text/css">
</style>
</head>

<body>
<img class="emoji" src="img/ballot-box.png">
<img class="emoji" src="img/mailbox.png">
<div class="clear">

<div id="col1">
<h2>Vote by Mail in $state_name in the 2020 U.S. Presidential Election</h2>

<div class="question">When is the election?</div>
<div class="answer">Tuesday Nov 3, 2020.</div>

<div class="question">Can I apply now to vote by mail?</div>
<div class="answer">$state_cutoff.</div>

<div class="question">Do I need an excuse?</div>
<div class="answer">$state_excuse.</div>
EOH
    ;

if ($state_deadline) {
    print <<EOH
<div class="question">When is the deadline to apply?</div>
<div class="answer">$state_deadline.</div>
EOH
;	
}

if ($state_apply_online) {
    print <<EOH
<div class="question">Can I apply online?</div>
<div class="answer">$state_apply_online.</div>
EOH
    ;
}

if ($state_form_url) {
    print <<EOH
<div class="question">Can I apply by mail?</div>
<div class="answer">Yes, with <a href="$state_form_url">this form</a>.</div>
EOH
    ;
}

if ($state_info_url) {
    print <<EOH
<div class="question">Where can I get more official info?</div>
<div class="answer"><a href="$state_info_url">Here</a>.</div>
EOH
	;
}
    

#FCGI Params
#foreach my $key (sort(keys %ENV)) {
#  print "$key = $ENV{$key}<br>\n";
#}


print <<EOH
</div>
<div id="col2">
<div id="states">
EOH
    ;

#foreach my $tmp_state (sort {$state_data{$a}{"name"} cmp $state_data{$b}{"name"}} keys %state_data) {
foreach my $tmp_state (sort {$a cmp $b} keys %state_data) {
    print qq(<a href="/?state=$tmp_state">), $tmp_state, qq(</a> );
#    print qq( | ) if $tmp_state ne 'WY';
}

print <<EOH
</div>

<div id="footer">
Privacy Policy: no tracking. We don't use any third-party services on this site,
nor do we store IP addresses or user agents in our access logs.

<br><br>
We're continually updating this site, but some info might be out of date.
For all inquiries (including corrections), please email info at mailin.vote.
</footer>

</div>
</body></html>
EOH
    ;
