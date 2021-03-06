#!/usr/local/bin/perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use Ticket;
use Data::Dumper;
use URI::Escape;
use POSIX qw(ceil);

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $data = $q->Vars;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my ($page, $total_pages, $count, $start);
	my @placeholders = ($id,$id);
	my $query;
	my $sth;
	my $section = {};

	$page = $data->{'page'};
	if(!$page){$page=1};
	my $limit = $data->{'rows'};
	if(!$limit){$limit=10};
	my $sidx = $data->{'sidx'};
	if(!$sidx){$sidx = 1};
	my $sord = $data->{'sord'};


	$query = "
		select
			count(*)
		from
			helpdesk
		where (
			(
				helpdesk.status not in ('6','7')
			) and (
				helpdesk.active
			) and (
				helpdesk.priority > '2'
			) and (
				helpdesk.technician = ?
				or (
					select
						bool_or(section_aclgroup.aclread) as read
					from
						section_aclgroup
						join
							section on section.id = section_aclgroup.section_id
						join
							aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
					where (
						section_aclgroup.aclgroup_id in (
							select
								aclgroup_id
							from
								alias_aclgroup
							where
								alias_id = ?
						)
					)
				)
			)
		)
			order by ? $sord
			offset ? limit ?;
	";
	push(@placeholders,$sidx,$start,$limit);

	$sth = $dbh->prepare($query);
	$sth->execute(@placeholders);

	$count = $sth->fetchrow_hashref;
	$count = $count->{'count'};
	if( $count > 0 && $limit > 0) {
		$total_pages = ceil($count/$limit); 
	} else { 
		$total_pages = 0;
	} 
	if($page > $total_pages){
		$page=$total_pages;
	}
	$start = $limit * $page - $limit;
	if($start<0){$start=0};

	$query = "select id,name from section where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');
	$data->{'section'} = "critical";
		$query = "
			select
				f.ticket as ticket,
				f.section as name,
				f.status as status,
				f.status_id as status_id,
				f.priority as priority,
				f.priority_id as priority_id,
				f.contact as contact,
				f.technician as technician,
				f.technician_id as technician_id,
				f.problem as problem
			from
				friendly_helpdesk AS f
			where (
				(
					f.status_id not in ('6','7')
				) and (
					f.active
				) and (
					f.priority_id > '2'
				) and (
					f.technician_id = ?
					or (
						select
							bool_or(section_aclgroup.aclread) as read
						from
							section_aclgroup
							join
								section on section.id = section_aclgroup.section_id
							join
								aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
						where (
							section_aclgroup.aclgroup_id in (
								select
									aclgroup_id
								from
									alias_aclgroup
								where
									alias_id = ?
							)
						)
					)
				)
			)
			order by ? $sord
			offset ? limit ?;
		";
		$sth = $dbh->prepare($query);
		$sth->execute(@placeholders);
		$section->{$data->{'section'}}->{'data'} = $sth->fetchall_arrayref({});
	if($section->{$data->{'section'}}->{'error'}) {
		warn "Access denied to section " .  $data->{'section'} . " for user $id";
	} else {
		print "Content-type: text/xml;charset=utf-8\n\n";

		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		foreach my $row (@{$section->{$data->{'section'}}->{'data'}}){
			$xml .= "<row id='" . $row->{'ticket'} . "'>";
			$xml .= "<cell>" . $row->{'ticket'} . "</cell>";
			$xml .= "<cell>" . $row->{'status'} . "</cell>";
			$xml .= "<cell>" . $row->{'priority'} . "</cell>";
			$xml .= "<cell>" . $row->{'technician'} . "</cell>";
			$xml .= "<cell>" . $row->{'problem'} . "</cell>";
			$xml .= "<cell>" . $row->{'name'} . "</cell>";
			$xml .= "</row>";
		}
		
		$xml .= "</rows>";
		print $xml;
	}
}
else{
	print $q->redirect(-URL => $config->{'index_page'});
}
