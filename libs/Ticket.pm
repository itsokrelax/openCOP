#!/usr/bin/perl


use 5.008009;
package Ticket;

use strict;
use warnings;
use Template;
use lib './libs';
use ReadConfig;
use DBI;
use Notification;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use ReadConfig ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);

	$self->{'mode'} = $args{'mode'};

	return $self;
}

sub render{
	my $self = shift;
	my %args = @_;
	
	my %templates = (
		"new" => "ticket_new.tt",
		"lookup" => "ticket_lookup.tt",
		"edit" => "ticket_edit.tt"
	);

	my $file = $templates{$self->{'mode'}};
	
	my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

	$config->read_config;

	# Pull available sections from the database
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "
		select
			name,
			section_aclgroup.section_id
		from
			section_aclgroup
			join section on section.id = section_aclgroup.section_id
		where
			aclgroup_id in (
				select
					distinct(aclgroup_id)
				from
					alias_aclgroup
				where (
					alias_id = ?
				)
			)
		and
			section_aclgroup.aclread;
	";
	my $sth = $dbh->prepare($query);
	$sth->execute($args{'id'});
	my $section_list = $sth->fetchall_hashref('section_id');

	# Pull sections to which this user has create rights from the database
	$query = "
		select
			name,
			section_aclgroup.section_id
		from
			section_aclgroup
			join
				section on section.id = section_aclgroup.section_id
		where
			aclgroup_id in (
				select
					distinct(aclgroup_id)
				from
					alias_aclgroup
				where (
					alias_id = ?
				)
			)
		and
			section_aclgroup.aclcreate;
	";
	$sth = $dbh->prepare($query);
	$sth->execute($args{'id'});
	my $section_create_list = $sth->fetchall_hashref('section_id');

	# Create a psuedo-section for tickets which are assigned to the technician but not on a board to which the technician has read rights
	$section_list->{'pseudo'} = {
		'section_id'	=>	"pseudo",
		'name'		=>	"Tickets assigned directly",
	};

	# Get the list of available priorities
	$query = "select * from priority;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $priority_list = $sth->fetchall_hashref('id');

	# Get the list of available sites
	$query = "select * from site where not deleted;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $site_list = $sth->fetchall_hashref('id');

	# Get the list of technicians
	$query = "select id,alias from users where active;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $tech_list = $sth->fetchall_hashref('id');

	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	
	my @styles = ("styles/jquery.jscrollpane.css","styles/layout.css","styles/ticket.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/main.js","javascripts/jquery.validate.js","javascripts/ticket.js","javascripts/jquery.mousewheel.js","javascripts/mwheelIntent.js","javascripts/jquery.jscrollpane.js","javascripts/jquery.tablesorter.js","javascripts/jquery.livequery.js","javascripts/jquery.hoverIntent.minified.js","javascripts/jquery.blockui.js");

	print "Content-type: text/html\n\n";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts, 'company_name' => $config->{'company_name'},logo => $config->{'logo_image'}, site_list => $site_list, priority_list => $priority_list, section_list => $section_list, tech_list => $tech_list, section_create_list => $section_create_list};

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}

sub submit{
	my $self = shift;
	my %args = @_;
	my $data = $args{'data'};

	my $query;
	my $sth;	
	my $results;
	my $dbh = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $status = 1;
	my $site;
	foreach my $element (keys %$data){
		$data->{$element} =~ s/\'/\'\'/g;
	}
	
	if(defined($data->{'site'})){
		$site = $data->{'site'};
	} else {
		$site = "1";
	}

	if(defined($data->{'section'})){
	} else {
		$data->{'section'} = "0";
	}

	if(defined($data->{'priority'})){
	} else {
		$data->{'priority'} = "2";
	}

	if($data->{'free_date'}){
	} else {
		$data->{'free_date'} = "now";
	}

	if($data->{'free_time'}){
	} else {
		$data->{'free_time'} = "now";
	}

	if($data->{'tech'}){
	} else {
		$data->{'tech'} = "1";
	}


	if($args{'customer'}){
		$query = "
			select
				bool_or(section_aclgroup.aclcreate) as access
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = ?
			and (
				section_aclgroup.aclgroup_id in (
					select
						aclgroup_id
					from
						aclgroup
					where
						name = ?
				)
			);
		";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'section'},"customers");
	} else {
		$query = "
			select
				bool_or(section_aclgroup.aclcreate) as access
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = ?
			and (
				section_aclgroup.aclgroup_id in (
					select
						aclgroup_id
					from
						alias_aclgroup
					where
						alias_id = ?
				)
			);
		";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'section'},$data->{'submitter'});
	}
	my $access = $sth->fetchrow_hashref;
	if($access->{'access'}){
		$query = "
			select
				insert_ticket(
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?
				);
		";
		warn $query;
		$sth = $dbh->prepare($query);
		$sth->execute(
			$site,
			$status,
			$data->{'barcode'},
			$data->{'location'},
			$data->{'author'},
			$data->{'contact'},
			$data->{'phone'},
			$data->{'troubleshoot'},
			$data->{'section'},
			$data->{'problem'},
			$data->{'priority'},
			$data->{'serial'},
			$data->{'email'},
			$data->{'tech'},
			$data->{'notes'},
			$data->{'submitter'},
			$data->{'free_date'},
			$data->{'free_time'}
		) or die $sth->errstr; #this will return the id of the insert record if we ever find a use for it
		my $id = $sth->fetchrow_hashref;
		my $notify = Notification->new(ticket_number => $id->{'insert_ticket'});

		$notify->by_email(mode => 'ticket_create', to => $data->{'email'});
		if(defined($data->{'tech_email'}))
		{
			$notify->by_email(mode => 'notify_tech', to => $data->{'tech_email'});
		}
		return $results = {
			'error'		=>	"0",
			'id'		=>	$id->{'insert_ticket'},
		};
	} else {
		return $results = {
			'error'		=>	"1",
			'id'		=>	"0",
		};
	}
}

sub lookup{
	my $self = shift;
	my %args = @_;

	my $query;
	my $results;
	my $dbh = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	if($args{'customer'}){
		$query = "
			select
				bool_or(section_aclgroup.aclread) as read,
				bool_or(section_aclgroup.aclcomplete) as complete
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = ?
			and (
				section_aclgroup.aclgroup_id = (
					select
						aclgroup_id
					from
						aclgroup
					where
						name = ?
				)
			);
		";
	} else {
		$query = "
			select
				bool_or(section_aclgroup.aclread) as read,
				bool_or(section_aclgroup.aclcomplete) as complete
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = ?
			and (
				section_aclgroup.aclgroup_id in (
					select
						aclgroup_id
					from
						alias_aclgroup
					where
						alias_id = ?
				)
			);
		";
	}
	my $sth = $dbh->prepare($query);
	$sth->execute($args{'section'},$args{'id'});
	my $access = $sth->fetchrow_hashref;
	if ($access->{'complete'}) {
		$query = "
			select
				*
			from
				helpdesk
				join
					section on section.id = helpdesk.section
			where
				status not in ('7')
			and
				active
			and
				section = ?
			order by
				ticket
		";
		#Currently 7 is the ticket status Completed.  If more ticket statuses are added check to make sure 6 is still closed.  If you start seeing closed ticket in the view then the status number changed
		$sth = $dbh->prepare($query);
		$sth->execute($args{'section'});
		$results = $sth->fetchall_hashref('ticket');
	
		return $results;		
	} elsif($access->{'read'}){
		$query = "
			select
				*
			from
				helpdesk
				join
					section on section.id = helpdesk.section
			where
				status not in ('6','7')
			and
				active
			and
				section = ?
			order by
				ticket
		";
		#Currently 6 is the ticket status Closed.  If more ticket statuses are added check to make sure 6 is still closed.  If you start seeing closed ticket in the view then the status number changed
		$sth = $dbh->prepare($query);
		$sth->execute($args{'section'});
		$results = $sth->fetchall_hashref('ticket');
	
		return $results;
	} else {
		return $results = {
			'error'		=>	"1",
		};
	}
}

sub details{
	my $self = shift;
	my %args = @_;
	
	my $dbh = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select * from helpdesk where ticket = ? and active";
	my $sth = $dbh->prepare($query);
	$sth->execute($args{'data'});
	my $results = $sth->fetchrow_hashref;
	
	return $results;
}

sub update{
	my $self = shift;
	my %args = @_;
	my $data = $args{'data'};
	my $results;
	my $query;
	my $sth;
	my $access;

	foreach my $element (keys %$data)
	{
		$data->{$element} =~ s/\'/\'\'/g;
	}
	
	my $dbh = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	
	$query = "
		select
			bool_or(section_aclgroup.aclupdate) as access
		from
			section_aclgroup
			join
				section on section.id = section_aclgroup.section_id
			join
				aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
		where
			section_aclgroup.section_id = ?
		and (
			section_aclgroup.aclgroup_id in (
				select
					aclgroup_id
				from
					alias_aclgroup
				where
					alias_id = ?
			)
		);
	";
	$sth = $dbh->prepare($query);
	$sth->execute($data->{'section'},$data->{'updater'});
	$access = $sth->fetchrow_hashref;

	$query = "
		select
			count(ticket)
		from
			helpdesk
		where
			technician = ?
		and
			ticket = ?
		;
	";
	$sth = $dbh->prepare($query);
	$sth->execute($data->{'updater'},$data->{'ticket_number'});
	my $explicit_access = $sth->fetchrow_hashref;
	foreach($access->{'access'},$explicit_access->{'count'}){
		unless(defined($_)){
			$_ = 0;
		}
	}
	$access->{'access'} = ($access->{'access'} | $explicit_access->{'count'});

	if($data->{'status'} == "7"){
		$query = "
			select
				bool_or(section_aclgroup.aclcomplete) as access
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = ?
			and (
				section_aclgroup.aclgroup_id in (
					select
						aclgroup_id
					from
						alias_aclgroup
					where
						alias_id = ?
				)
			);
		";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'section'},$data->{'updater'});
		$access = $sth->fetchrow_hashref;
	}
	my $closed_by;
	my $completed_by;
	if($access->{'access'}){
		if($data->{'status'} == "6"){
			$closed_by = $data->{'updater'};
		} elsif($data->{'status'} == "7"){
			$completed_by = $data->{'updater'};
		}
		my $query = "
			select
				update_ticket(
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?
				);
		";
		my $sth = $dbh->prepare($query);
		$sth->execute(
			$data->{'ticket_number'},
			$data->{'site'},
			$data->{'location'},
			$data->{'contact'},
			$data->{'contact_phone'},
			$data->{'troubleshooting'},
			$data->{'contact_email'},
			$data->{'notes'},
			$data->{'status'},
			$data->{'tech'},
			$data->{'updater'},
			$closed_by,
			$completed_by
		);
		#this will return the id of the insert record if we ever find a use for it
		my $results = $sth->fetchrow_hashref;
		if($data->{'status'} == "6" || $data->{'status'} == "7"){
			$query = "
				update
					helpdesk
				set
					active = true
				where
					ticket in (
						select
							ticket_id
						from
							wo_ticket
						where
							requires = ?
					);
			";
			$sth = $dbh->prepare($query);
			$sth->execute($results->{'update_ticket'});
		}
		return $results;
	} else {
		return $results = {
			'error'		=>	"1",
		};
	}
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

ReadConfig - generic configuration reader

=head1 SYNOPSIS

  use ReadConfig;

=head1 DESCRIPTION

ReadConfig reads different config files that map to hashes well.  For example
it reads YAML config files and takes the ATTRIB: VALUE pair and turns them into
parameters for the object created when calling ReadConfig->new() inside of your
PERL script

=head2 VERSIONING

.1 reads yaml config files
=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

bels, <lt>bels@lfmcorp.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by bels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
