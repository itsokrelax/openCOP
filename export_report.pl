#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use JSON;
use Notification;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $vars = $q->Vars;
	my $json = JSON->new;
	warn $vars->{'table'};
	my $object = from_json($vars->{'table'});
	my $name = $vars->{'report_name'};
	my $filename = $name;
	$filename =~ s/ /_/g;
	foreach(@{$object}){
		shift @{$_};
	}
	if($vars->{'email'} eq "true"){
		warn $vars->{'email'};
		if($vars->{'mode'} eq "csv"){
			my $dbh = DBI->connect("dbi:CSV:f_dir=/tmp/");
			my $query = "CREATE TABLE $filename.csv (";
			foreach(@{@{$object}[0]}){
				$query .= "$_ VARCHAR(255), ";
			}
			shift(@{$object});
			$query =~ s/, $/ /;
			$query .= ")";
			my $sth = $dbh->prepare($query);
			$sth->execute;
			foreach(@{$object}){
				$query = "INSERT INTO $filename.csv values (";
				for(my $i = 0; $i <= $#{$_}; $i++){
					$query .= "'@{$_}[$i]', ";
				}
				shift @{$_};
				$query =~ s/, $/ /;
				$query .= ")";
				$sth = $dbh->prepare($query);
				$sth->execute;
			}
			my $notify = Notification->new;
			$notify->send_attachment(attachment_name => $name, attachment_file => "/tmp/$filename.csv", content_type => "application/text");
		} elsif($vars->{'mode'} eq "pdf"){
		}
		print "Content-type: text/html\n\n";
	} else {
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
