#!/usr/local/bin/perl
# This script will process mail and turn it into a ticket.  It may do other things in the future but who knows.

use strict;
use warnings;
use lib './libs';
use Ticket;
use ReadConfig;
use DBI;

my $email_file = "tickets.mail";

open TICKETS, $email_file;

my @mail_data = <TICKETS>; #I am doing it this way so I can get the data out of the file quickly so the file can be blanked.

close(TICKETS);

open TICKETS, ">$email_file";
close(TICKETS); #file should be blank at this point

my $new_message = 0;
my $sender = "";
my $subject = "";
my $body = "";

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config; #I am doing this because we have to call submit on the ticket object directly instead of letting ticket.pl handle it.  This means that we have to pass in the database information

my $ticket = Ticket->new(mode => "new");

#open LOG, ">>log.txt";

for my $line (@mail_data)
{
	
	if($line =~ /Sender:.*<(.+@.+)>/)
        {
                $sender = $1;
		chomp $sender;
        }
        if($line =~ /Subject:\s+(.*)/)
        {
                $subject = $1;
		chomp $subject;
        }
        if($line =~ /Body:\s+(.*)/) #theory is all header lines start with something: or something-else: where the body doesn't.  So unless someone starts the message something: we should be good.  This is a hack for now.
        {
                $body = $1;
        }
        if($line !~ m/^Subject:/ && $line !~ m/^Sender:/ && $line !~ m/^Body:/)
        {
                $body = $body . " $line";
        }
	
	if($line =~ /\$\$\$/)
	{
		$new_message = 1;
	}
	
	if($new_message == 1)
	{
		$body =~ s/\$\$\$//;

		my @body = split(/------.+\n/, $body);
		$body = $body[1];
		if($body =~ m/text\/plain/){
			$body =~ s/^Content-Type.*Content-Transfer-Encoding.*?\n+//is;
			# and some more stuff
		} else {
			$body =~ s/^Content-Type.*Content-Transfer-Encoding.*.*Content-Disposition.*?\n+//is;
		}


		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		my $query = "select id from users where email = '$sender'";
		my $sth = $dbh->prepare($query);
		$sth->execute;
		my $temp = $sth->fetchrow_hashref;
		my $alias = $temp->{'id'};
		if(!defined($alias)) #this allows technicians to submit tickets through email. if the email can't be found in the customers table it then searches the users(technicians)
		{
			$query = "select id from users where email = '$sender'";
			$sth = $dbh->prepare($query);
			$sth->execute;
			$temp = $sth->fetchrow_hashref;
			$alias = $temp->{'id'};
		}
		my $data = {site => "",barcode => "",location =>"",author => $sender,contact => $sender,phone => "",troubleshoot=> "",section=>"Helpdesk",problem=>$subject,priority =>"Normal",serial=>"",email=>$sender,tech => "", notes => $body, submitter  => $alias}; #This part will need to be improved.  Right now I am leaving a lot of fields blank that with some investigation could be filled out.  For example, I won't know what site someone is sending the ticket in from
								#unless I lookup in the database for a matching email address and then checking what site that person is at.  Also, the persons name could be looked up by email address.  This is something that isn't feasible now but should be in the future
		$ticket->submit(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data);
		
		#print LOG "$sender\n";
		#print LOG "$subject\n";
		#print LOG "$body\n\n";
		
		$subject = "";
		$sender = "";
		$body = "";
		$new_message = 0;
	}
}
#close LOG;
