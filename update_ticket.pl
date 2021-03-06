#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use Notification;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;
my $alias;
my $id;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $data = $q->Vars;
	$data->{'updater'} = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $access = $ticket->update(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data); #need to pass in hashref named data
	if($access->{'error'}){
		warn "Access denied to section " .  $data->{'section'} . " for user " . $data->{'updater'};
		print "Content-type: text/html\n\n";
	} else {
		my $notify = Notification->new(ticket_number => $data->{'ticket_number'});
		$notify->by_email(mode => 'ticket_update', to => $data->{'contact_email'});
		print "Content-type: text/html\n\n";
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
