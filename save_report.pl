#!/usr/local/bin/perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use lib './modules';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use JSON;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $vars = $q->Vars;
	$vars->{'table'} =~ s/'/"/g;
	my $object = from_json($vars->{'table'});
	my $mode = $vars->{'mode'};
	my $name = $vars->{'report_name'};
	my $filename = $name;
	$filename =~ s/ /_/g;
	foreach(@{$object}){
		shift @{$_};
	}
	if($mode eq "csv"){
		my $query;
		foreach(@{$object}){
			for(my $i = 0; $i <= $#{$_}; $i++){
				if(@{$_}[$i] =~ m/ /){
					@{$_}[$i] = qq(") . @{$_}[$i] . qq(");
				}
				$query .= "@{$_}[$i],";
			}
			shift @{$_};
			$query =~ s/,$//;
			$query .= "\n";
		}
		print "Content-type: application/octet-stream\n";
		print "Content-disposition: attachment; filename=$filename.csv\n\n";
		print($query);
	} elsif($vars->{'mode'} eq "pdf"){
		warn "Nothing here!";
	} elsif($vars->{'mode'} eq "excel"){
		warn "Nothing here either!";
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
