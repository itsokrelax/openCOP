#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use SessionFunctions;
use URI::Escape;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $site_name = uri_unescape($q->param('delete_site_name'));

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in delete_site.pl";
	my $query = "update site set delete = 1 where name = '$site_name'";
	my $sth = $dbh->prepare($query);
	$sth->execute;

	print $q->redirect(-URL=> "sites.pl?delete_site_success=1");
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}