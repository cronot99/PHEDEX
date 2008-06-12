package PHEDEX::RequestAllocator::SQL;

=head1 NAME

PHEDEX::RequestAllocator::SQL - encapsulated SQL for evaluating requests
Checking agent.

=head1 SYNOPSIS

This package simply bundles SQL statements into function calls.
It's not a true object package as such, and should be inherited from by
anything that needs its methods.

=head1 DESCRIPTION

pending...

=head1 METHODS

=over

=item method1($args)

=back

=head1 SEE ALSO...

L<PHEDEX::Core::SQL|PHEDEX::Core::SQL>,

=cut

use strict;
use warnings;
use base 'PHEDEX::Core::SQL';

use Carp;

our @EXPORT = qw( );

# Probably will never need parameters for this object, but anyway...
our %params =
	(
	);

sub new
{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new(%params,@_);
  bless $self, $class;
  return $self;
}

sub AUTOLOAD
{
  my $self = shift;
  my $attr = our $AUTOLOAD;
  $attr =~ s/.*:://;
  if ( exists($params{$attr}) )
  {
    $self->{$attr} = shift if @_;
    return $self->{$attr};
  }
  return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
  my $parent = "SUPER::" . $attr;
  $self->$parent(@_);
}

#-------------------------------------------------------------------------------
# Fetch basic transfer request information
# Options:
#   APPROVED    : if true, return approved; if false, return disapproved; if null, return either;
#   PENDING     : if true, return pending nodes; if false, return decided; if null, return either;
#   DEST_ONLY   : if true, return only destination nodes; if false or null, return either;
#   SRC_ONLY    : if true, return only source nodes; if false or null, return either;
#   STATIC      : if true, only return static requets, if false only return expanding requests
#   MOVE        : if true, return move requests; if false, return copy requests; if null return either;
#   DISTRIBUTED : if true, return dist. reqs; if false, return non-dist.; if null, return either;
#   WILDCARDS   : if true, only return requests with wildcards in them
#   AFTER       : only return requests created after this timestamp
#   NODES       : an arrayref of nodes.  Only return transfers affecting those nodes
sub getTransferRequests
{
    my ($self, %h) = @_;

    my %p;
    my @where;
    if (defined $h{APPROVED}) {
	push @where, 'rd.decision = '.($h{APPROVED} ? "'y'" : "'n'");
    }

    if (defined $h{PENDING}) {
	push @where, 'rd.request is '.($h{PENDING} ? '' : 'not ').'null';
    }

    if (defined $h{DEST_ONLY} && $h{DEST_ONLY}) {
	push @where, "rn.point = 'd'";
    }

    if (defined $h{SRC_ONLY} && $h{SRC_ONLY}) {
	push @where, "rn.point = 's'";
    }

    if (defined $h{STATIC}) {
	push @where, 'rx.is_static = '.($h{STATIC} ? "'y'" : "'n'");
    }
    if (defined $h{MOVE}) {
	push @where, 'rx.is_move = '.($h{MOVE} ? "'y'" : "'n'");
    }
    if (defined $h{DISTRIBUTED}) {
	push @where, 'rx.is_distributed = '.($h{DISTRIBUTED} ? "'y'" : "'n'");
    }
    if (defined $h{WILDCARDS}) {
	push @where, "rx.data like '%*%'";
    }
    if (defined $h{AFTER}) {
	push @where, "r.time_create > :after";
	$p{':after'} = $h{AFTER};
    }
    if (defined $h{NODES}) {
	my $dummy = '';
	push @where, '('. &filter_or_eq($self, \$dummy, \%p, 'rn.node', @{$h{NODES}}).')';
    }

    my $where = '';
    $where = 'where '.join(' and ', @where) if @where;

    my $sql = qq{
	select r.id, rt.name type, r.created_by creator_id, r.time_create, rdbs.name dbs,
               rx.priority, rx.is_move, rx.is_transient, rx.is_static, rx.is_distributed, rx.data,
	       n.name node, n.id node_id,
               rn.point, rd.decision, rd.decided_by, rd.time_decided
	  from t_req_request r
          join t_req_type rt on rt.id = r.type
          join t_req_dbs rdbs on rdbs.request = r.id
	  join t_req_xfer rx on rx.request = r.id
          join t_req_node rn on rn.request = r.id
          join t_adm_node n on n.id = rn.node
     left join t_req_decision rd on rd.request = rn.request and rd.node = rn.node
        $where 
      order by r.id
 };
    
    $self->{DBH}->{LongReadLen} = 10_000;
    $self->{DBH}->{LongTruncOk} = 1;
    
    my $q = &dbexec($self->{DBH}, $sql, %p);
    
    my $requests = {};
    while (my $row = $q->fetchrow_hashref()) {
	# request data
	my $id = $row->{ID};
	if (!exists $requests->{$id}) {
	    $requests->{$id} = { map { $_ => $row->{$_} } 
				 qw(ID TYPE CREATOR_ID TIME_CREATE DBS
				    PRIORITY IS_MOVE IS_TRANSIENT IS_STATIC IS_DISTRIBUTED
				    DATA) };
	    $requests->{$id}->{NODES} = {};
	}
	
	# nodes of the request
	my $node = $row->{NODE_ID};
	if ($node) {
	    $requests->{$id}->{NODES}->{$node} = { map { $_ => $row->{$_} }
						   qw(NODE NODE_ID POINT DECISION DECIDED_BY TIME_DECIDED) };
	}
    }
    
    return $requests;
}



#-------------------------------------------------------------------------------
# Fetch basic deletion request information
# Options:
#   APPROVED    : if true, return approved; if false, return disapproved; if null, return either;
#   PENDING     : if true, return pending nodes; if false, return decided; if null, return either;
#   RETRANSFER : if true, only return retransfer deletions, if false only return permenant deletions
#   WILDCARDS : if true, only return requests with wildcards in them
#   AFTER : only return requests created after this timestamp
#   NODES : an arrayref of nodes.  Only return deletions affecting those nodes
sub getDeleteRequests
{
    my ($self, %h) = @_;

    my %p;
    my @where;
    if (defined $h{APPROVED}) {
	push @where, 'rd.decision = '.($h{APPROVED} ? "'y'" : "'n'");
    }

    if (defined $h{PENDING}) {
	push @where, 'rd.request is '.($h{PENDING} ? '' : 'not ').'null';
    }

    if (defined $h{RETRANSFER}) {
	push @where, 'rx.rm_subscriptions = '.($h{RETRANSFER} ? "'n'" : "'y'");
    }

    if (defined $h{WILDCARDS}) {
	push @where, "rx.data like '%*%'";
    }
    if (defined $h{AFTER}) {
	push @where, "r.time_create > :after";
	$p{':after'} = $h{AFTER};
    }
    if (defined $h{NODES}) {
	my $dummy = '';
	push @where, '('. &filter_or_eq($self, \$dummy, \%p, 'rn.node', @{$h{NODES}}).')';
    }

    my $where = '';
    $where = 'where '.join(' and ', @where) if @where;

    my $sql = qq{
	select r.id, rt.name type, r.created_by creator_id, r.time_create, rdbs.name dbs,
               rx.rm_subscriptions, rx.data,
	       n.name node, n.id node_id,
               rn.point, rd.decision, rd.decided_by, rd.time_decided
	  from t_req_request r
          join t_req_type rt on rt.id = r.type
          join t_req_dbs rdbs on rdbs.request = r.id
	  join t_req_delete rx on rx.request = r.id
          join t_req_node rn on rn.request = r.id
          join t_adm_node n on n.id = rn.node
     left join t_req_decision rd on rd.request = rn.request and rd.node = rn.node
        $where 
      order by r.id
 };
    
    $self->{DBH}->{LongReadLen} = 10_000;
    $self->{DBH}->{LongTruncOk} = 1;
    
    my $q = &dbexec($self->{DBH}, $sql, %p);
    
    my $requests = {};
    while (my $row = $q->fetchrow_hashref()) {
	# request data
	my $id = $row->{ID};
	if (!exists $requests->{$id}) {
	    $requests->{$id} = { map { $_ => $row->{$_} } 
				 qw(ID TYPE CREATOR_ID TIME_CREATE DBS
				    RM_SUBSCRIPTIONS DATA) };
	    $requests->{$id}->{NODES} = {};
	}
	
	# nodes of the request
	my $node = $row->{NODE_ID};
	if ($node) {
	    $requests->{$id}->{NODES}->{$node} = { map { $_ => $row->{$_} }
						   qw(NODE NODE_ID POINT DECISION DECIDED_BY TIME_DECIDED) };
	}
    }
    
    return $requests;
}



#-------------------------------------------------------------------------------
# Returns arrayrefs of datasets and blocks attached to this request
# Options:
#   EXPAND_DATASETS : if true, expands datasets into block ids and returns them in the block array
sub getExistingRequestData
{
    my ($self, $id, %h) = @_;

    my $datasets = select_single ( $self->{DBH},
				   qq{ select rds.dataset_id from t_req_dataset rds
					   where rds.dataset_id is not null
                                             and rds.request = :id },
				   ':id' => $id );

    my $blocks = select_single ( $self->{DBH},
				 qq{ select rb.block_id from t_req_block rb
			 	      where rb.block_id is not null
                                        and rb.request = :id },
				 ':id' => $id );

    if ($h{EXPAND_DATASETS}) {
	my $ds_blocks = select_single ( $self->{DBH},
					qq{ select b.id
                                              from t_req_dataset rds
                                              join t_dps_block b on b.dataset = rds.dataset_id
                                             where rds.dataset_id is not null
					       and rds.request = :id } );
	push @$blocks, @{$ds_blocks};
    }
    
    return $datasets, $blocks;
}



#-------------------------------------------------------------------------------
# Adds a dataset or block to a request
sub addRequestData
{
    my ($self, $request, %h) = @_;
    my $type;
    $type = 'DATASET' if $h{DATASET};
    $type = 'BLOCK'   if $h{BLOCK};
    return undef unless $type && $request;

    my $type_lc = lc $type;
    my $sql = qq{ insert into t_req_${type_lc}
		  (request, name, ${type_lc}_id)
                  select :request, name, id
                  from t_dps_${type_lc}
                  where id = :id };

    my ($sth, $n);
    ($sth, $n) = execute_sql( $self, $sql, ':request' => $request, ':id' => $h{$type} );

    return $n;
}



#-------------------------------------------------------------------------------
# Creates a new subscription for a dataset or block
# Required:
#  DATASET or BLOCK : the name or ID of a dataset or block
#  REQUEST : request ID this is associated with
#  DESTINATION : the destination node ID
#  PRIORITY : priority
#  IS_MOVE : if this is a move subscription
#  IS_TRANSIENT : if this is a transient subscription
#  TIME_CREATE : the creation time
# TODO: Check that block subscriptions are not created where a dataset
#       subscription exists?  BlockAllocator takes care of this, but it may be 
#       unneccessary strain on that agent.
sub createSubscription
{
    my ($self, %h) = @_;;

    my $type;
    $type = 'DATASET' if defined $h{DATASET};
    $type = 'BLOCK'   if defined $h{BLOCK};
    if (!defined $type || (defined $h{DATASET} && defined $h{BLOCK})) {
	$self->Alert("cannot create subscriptioin:  DATASET or BLOCK must be defined");
	return undef;
    }

    my @required = qw(REQUEST DESTINATION PRIORITY IS_MOVE IS_TRANSIENT TIME_CREATE);
    foreach (@required) {
	if (!exists $h{$_} || !defined $h{$_}) {
	    $self->Alert("cannot create subscription:  $_ not defined");
	    return undef;
	}
    }

    foreach ( qw(IS_MOVE IS_TRANSIENT) ) {
	next unless  $h{$_} =~ /^[0-9]$/;
	$h{$_} = ( $h{$_} ? 'y' : 'n' );
    }

    my $sql = qq{ 
	insert into t_dps_subscription
        (request, dataset, block, destination,
	 priority, is_move, is_transient, time_create)
    };

    if ($h{$type} !~ /^[0-9]+$/) { # if not an ID, then lookup IDs from the name
	if ($type eq 'DATASET') {
	    $sql .= qq{ select :request, ds.id, NULL, :destination, :priority, :is_move, :is_transient, :time_create 
			  from t_dps_dataset ds where ds.name = :dataset };
	} elsif ($type eq 'BLOCK') {
	    $sql .= qq{ select :request, NULL, b.id, :destination, :priority, :is_move, :is_transient, :time_create 
			  from t_dps_block b where b.name = :block };
	}
    } else { # else we write exactly what we have
	$sql .= qq{ values (:request, :dataset, :block, :destination, :priority, :is_move, :is_transient, :time_create) };
    }

    my %p = map { ':' . lc $_ => $h{$_} } @required, qw(DATASET BLOCK);

    my ($sth, $n);
    eval { ($sth, $n) = execute_sql( $self, $sql, %p ); };
    die $@ if $@ && !($h{IGNORE_DUPLICATES} && $@ =~ /ORA-00001/);

    return $n;
}



1;
