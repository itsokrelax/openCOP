#!/usr/local/bin/perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use DBI;

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
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $query;

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $title;
	my $types;
	my $properties;
	my $file;

	my @styles = (
		"styles/inventory.css",
		"styles/ui.multiselect.css",
	);
	my @javascripts = (
		"javascripts/main.js",
		"javascripts/jquery.validate.js",
		"javascripts/jquery.blockui.js",
		"javascripts/ui.multiselect.js"
	);

	my $mode = $q->param('mode');
	if ($mode eq "add"){
		$title = $config->{'company_name'} . " - Inventory Add";
		$file = "inventory_add.tt";
		push(@styles,"styles/inventory_add.css");
		push(@javascripts,"javascripts/inventory_add.js");
	} elsif ($mode eq "current"){
		$title = $config->{'company_name'} . " - Inventory Current";
		$file = "inventory_current.tt";
		push(@styles,
			"styles/ui.jqgrid.css",
			"styles/inventory_current.css",
		);
		push(@javascripts,
			"javascripts/grid.locale-en.js",
			"javascripts/jquery.jqGrid.min.js",
			"javascripts/jquery.mousewheel.js",
			"javascripts/mwheelIntent.js",
			"javascripts/inventory_current.js",
		);
	} elsif ($mode eq "configure"){
		$title = $config->{'company_name'} . " - Inventory Configure.";
		$file = "inventory_configure.tt";
		push(@styles,"styles/inventory_configure.css");
		push(@javascripts,"javascripts/inventory_configure.js");
	} else {
		$title = $config->{'company_name'} . " - Inventory Index";
		$file = "inventory_index.tt";
	}
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		types => $types,
		is_admin => $user->is_admin(id => $id),
		backen => $config->{'backend'},
	};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
