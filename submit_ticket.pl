#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;
use CustomerFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $user;
	my $alias;
	my $uid;
	my $submitter;
	my $data = $q->Vars;
	my $type = $q->url_param('type');
	my $notes;

	$alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},sid => $cookie{'sid'});

	if($type eq "customer")
	{
		$user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$uid = $user->get_user_info(alias => $alias);
		$submitter = $uid->{'cid'};
		$notes = $q->param('problem');
		$data->{'tech'} = "undefined";
	}
	else
	{
		$user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$uid = $user->get_user_info(alias => $alias);
		$submitter = $uid->{'uid'};
		$notes = "";
	}

	if(defined($data->{'tech'})){
		$user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$uid = $user->get_user_info(alias => $data->{'tech'});
		$data->{'tech_email'} = $uid->{'email'};
	}

	$ticket->submit(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data, notes => $notes,submitter => $submitter); #need to pass in hashref named data
	
	print "Content-type: text/html\n\n";
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
