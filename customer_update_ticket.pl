#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use CustomerFunctions;
use Notification;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 2)
{
	my $vars = $q->Vars;
	my $tkid = $vars->{'tkid'};
	my $new_note = $vars->{'new_note'};

	foreach ($new_note){
		$_  =~ s/\'/\'\'/g;
	}

	my $updater = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $query = "insert into notes (ticket_id, note) values(?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($tkid,$new_note);
	my $query = "update helpdesk set free_date = ?, start_time = ?, end_time = ? where ticket = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($vars->{'free_date'},$vars->{'start_time'},$vars->{'end_time'},$tkid);
	if(defined($vars->{'tech_email'})){
		my $notify = Notification->new(ticket_number => $tkid);
		$notify->by_email(mode => 'notify_tech_ticket_update', to => $vars->{'tech_email'});
	}

	print "Content-type: text/html\n\n";
}	
else
{
	print $q->redirect(-URL => $config->{'customer.pl'});
}
