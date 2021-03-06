package PHEDEX::BlockArrive::SQL;

=head1 NAME

PHEDEX::BlockArrive::SQL

=head1 SYNOPSIS

This package simply bundles SQL statements into function calls.
It is not a true object package as such, and should be inherited from by
anything that needs its methods.

=head1 DESCRIPTION

SQL calls for interacting with t_status_block_arrive, a table for the
predicted arrival time of a block on a node.

=head1 METHODS

=over

=item mergeStatusBlockArrive(%args)

Updates the t_status_block_arrive table using current data in
t_dps_block_dest, t_status_block_request, t_status_block_path.
Keeps track of predicted arrival time for blocks currently
subscribed for transfer and incomplete at destination.
If the block is not expected to complete, it provides a reason.
If the block is fully routed, it uses the arrival time estimate
calculated by FileRouter.
If the block is not fully routed, it calculates the arrival time
estimate from other sources (WARNING: not yet implemented).

This method can be run asynchronously, but since it is using information
generated by FileRouter it makes sense to call it in this agent.

Returns an array with the number of lines updated by each statement.

=back

=head1 SEE ALSO...

L<PHEDEX::Core::SQL|PHEDEX::Core::SQL>,

=cut

use strict;
use warnings;
use base 'PHEDEX::Core::SQL', 'PHEDEX::Core::Logging';
use PHEDEX::Core::Timing;

use Carp;

our @EXPORT = qw( );

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
sub mergeStatusBlockArrive
{
    my ($self,%h) = @_;
    my ($sql,%p,$q,$n,@r);

    $p{':now'} = $h{NOW} || &mytimeofday();

    # Clean up status table
    
    $sql = qq{ delete from t_status_block_arrive };
    ($q, $n) = execute_sql( $self, $sql );
    push @r, $n;

    # Create the stats (files, bytes, priority) for incomplete block destinations
    # which are currently not activated for routing (bd.state!=1, bd.state!=3),
    # and for open blocks.
    # States considered here:
    # - bd.state=-2   The destination node has no valid download link. In this case no estimate is possible.
    # - bd.state=-1   The priority queue to the destination node is full. TODO: In this case the arrival time
    #                  could be estimated from queue history (not yet implemented).
    # - bd.state=2    Subscription manually suspended. In this case no estimate is possible.
    # - bd.state=4    Subscription automatically suspended by FileRouter for too many failures
    #                  In this case no estimate is possible.
    # - b.is_open='y' Block is still open. In this case no estimate is possible.
    # TODO: suspensions can expire - should we use this in estimate?
    #
    # States not considered here:
    # - bd.state=0    The block has not yet been considered for routing, it will
    #                  be updated in the next FileRouter cycle.

    $sql = qq{
	insert into t_status_block_arrive
	    ( time_update, destination, block, files, bytes, priority, basis )
	    select :now, bd.destination, bd.block, b.files, b.bytes, bd.priority,
	            case
		      when bd.state = -2 then -3
		      when bd.state = -1 then 1
	              when bd.state = 2 then -2
		      when bd.state = 4 then -4
	              when b.is_open = 'y' then -1
		    end basis
	        from t_dps_block_dest bd
	        join t_dps_block b on b.id = bd.block
	        where bd.state = -2 or bd.state = -1 or bd.state = 2
		  or bd.state = 4 or b.is_open = 'y' };

    ($q, $n) = execute_sql( $self, $sql, %p );
    push @r, $n;
    
    # Estimate the arrival time for block destinations which are currently activated for routing (bd.state=1)
    # but for which some of the files are currently unroutable (t_xfer_request.state!=0).
    # The FileRouter logs this information in the t_status_block_request table.
    # States considered here are:
    # - br.state=4  Some files in the block have no replica; block will never complete.
    # - br.state=3  No path to destination for some files in the block.
    #                The block might complete eventually if a direct link
    #                is enabled or the file is replicated to an intermediate node
    #                with a valid link; no possible arrival time estimate.
    # - br.state=1  There was a recent transfer failure for some files in the block.
    #                The FileRouter should reactivate the request in 40-90 minutes.
    #                TODO: wait for rerouting, or estimate arrival time from other sources, e.g. latency tables?
    # States not considered here:
    # - br.state=2  The transfer request has expired for some files in the block, and it should be 
    #                reactivated in the same FileRouter cycle if the destination site is alive.

    $sql = qq{
	merge into t_status_block_arrive barr
	    using 
	    ( select distinct bd.destination, bd.block, b.files, b.bytes,
	              bd.priority,
	              case
	               when max(br.state)=4 then -6
	               when max(br.state)=3 then -5
	               when max(br.state)=1 then 2
	              end basis
	        from t_dps_block_dest bd
                join t_dps_block b on b.id=bd.block
	        join t_status_block_request br
	          on br.block=bd.block and br.destination=bd.destination
	        where br.state = 4 or br.state = 3 or br.state =1
	        group by bd.destination, bd.block, b.files, b.bytes,
	                 bd.priority
	     ) breqs
	     on ( barr.destination=breqs.destination
	          and barr.block=breqs.block )
	     when not matched then
	      insert ( time_update, destination, block, files, bytes, priority, basis )
	      values ( :now, breqs.destination, breqs.block, breqs.files, breqs.bytes,
	             breqs.priority, breqs.basis )
    };
    
    ($q, $n) = execute_sql( $self, $sql, %p );
    push @r, $n;

    # What remains is the files with an active request (t_xfer_request.state=0).
    # For these files, the arrival time is estimated by FileRouter in the path cost
    # and aggregated in the t_status_block_path table by src_node, destination, block.
    # Here we simply aggregate again.
    $sql = qq{
        merge into t_status_block_arrive barr
            using
            ( select distinct bd.destination, bd.block, b.files, b.bytes, bd.priority,
	              0 basis, max(bp.time_arrive) time_arrive
	       from t_dps_block_dest bd
	       join t_dps_block b on b.id=bd.block
	       join t_status_block_path bp
	         on bp.block=bd.block and bp.destination=bd.destination
	       group by bd.destination, bd.block, b.files, b.bytes, bd.priority
	      ) bpaths
	      on ( barr.block=bpaths.block 
		   and barr.destination=bpaths.destination )
	      when not matched then
	       insert ( time_update, destination, block, files, bytes, priority, basis, time_arrive )
	       values ( :now, bpaths.destination, bpaths.block, bpaths.files, bpaths.bytes,
			bpaths.priority, bpaths.basis, bpaths.time_arrive )
	   };

    ($q, $n) = execute_sql( $self, $sql, %p );
    push @r, $n;

    return @r;

}

1;
