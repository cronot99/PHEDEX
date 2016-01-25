#! /usr/bin/env perl 
use strict;
use warnings;
use Data::Dumper;
my $INPUT = {
          'PHEDEX' => {
                        'REQUEST_DATE' => '2016-01-15 23:41:22 UTC',
                        'REQUEST_CALL' => 'dumpquery',
                        'REQUEST_URL' => 'http://localhost:8280/dmwmmon/datasvc/perl/dumpquery',
                        'CALL_TIME' => '0.00697',
                        'REQUEST_VERSION' => '1.0.3-comp2',
                        'QUERYSPACE' => [
                                          {
                                            'SPACE' => '1',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir3/a/b',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '2',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir1',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '2',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir3/a',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '1',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir1/a/b',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '2',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir2',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '2',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir1/a',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '1',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir2/a/b',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '2',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir3',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '2',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir2/a',
                                            'TIMESTAMP' => '1446500998'
                                          },
                                          {
                                            'SPACE' => '6',
                                            'NAME' => 'T2_Test_Buffer',
                                            'DIR' => '/storage/local/data1',
                                            'TIMESTAMP' => '1446500998'
                                          }
                                        ],
                        'REQUEST_TIMESTAMP' => '1452901282.63093',
                        'INSTANCE' => 'read'
                      }
        };

# END OF DATA OUTPUT. 

# Input parameters (API arguments): 
my %paramhash = ( 
    level       => 15, #      the depth of directories, should be less than or equal to 12, the default is 4
    rootdir     => '/', #     the path to be queried
    rootdir     => '/storage/local/data1/home/natasha/work/SPACEMON/DEBUG/data/store/dir2/a',
    #node        => 'T2_Test_Buffer', #       node name, could be multiple, all(T*). 
    #time_since  => '0', #    former time range, since this time, if not specified, time_since=0
    #time_until  => 10000000000, #     later time range, until this time, if not specified, time_until=10000000000
    # if both time_since and time_until are not specified, the latest record will be selected
);

# node name and time parameters are used in SQL query to filter out the desired entries
# (since we work on SQL output here we do not need them)
# level and rootdir parameters are used in the aggregation algorithm below
my $level = $paramhash{level};
my $root = $paramhash{rootdir};
# Find all node names
my $node_names = {};
foreach my $data (@{$INPUT->{PHEDEX}->{QUERYSPACE}}) {
    $node_names->{$data->{NAME}}=1;
};
# Processing all nodes:
foreach my $nodename (keys %$node_names) { 
    print "*** Processing node:  $nodename\n"; 
    my $node_element = {};
    $node_element->{'NODE'} = $nodename;
    $node_element->{'SUBDIR'} = $root;
    # Find all timestamps for this node:
    my $timestamps = {};
    foreach my $data (@{$INPUT->{PHEDEX}->{QUERYSPACE}}) {
	$timestamps->{$data->{TIMESTAMP}}=1;
    };
    my @timebins; # Array for node aggregated data per timestamp
    my $debug_count = 0;
    foreach my $timestamp (keys %$timestamps) { 
	$debug_count++;
	my $timebin_element = {timestamp => $timestamp};
	print "  *** Aggregating data from " . gmtime ($timestamp) . 
	    " GMT ($timestamp), to level=$level\n"; 
	# Pre-initialize data for all levels:
	my @levelsarray;
	for (my $i = 1; $i<= $level; $i++) {
	    push @levelsarray, {DATA => [], LEVEL => $i};
	};
	# Filter out all data for a given node and timestamp from SQL output:
	my @currentdata = grep {
	    ($_->{NAME} eq $nodename ) and ( $_->{TIMESTAMP} eq $timestamp )
	} @{$INPUT->{PHEDEX}->{QUERYSPACE}};
	my ($cur, $reldepth);
	while (@currentdata) {
	    $cur = shift @currentdata;
	    print "dir: " . $cur->{DIR} . "\n";
	    $reldepth = checklevel($root, $cur->{DIR});
	    print "Relative depth to rootdir $root = $reldepth\n";
	    # Aggregate by levels: 
	    for ( my $i = 1; $i <= $level; $i++ ) 
	    {
		print "*** Initializing data for LEVEL $i\n";
		#$levelsarray[$i-1]->{DATA} = [];		
		# update data
		#if ( $reldepth <= $level ) {
		if ( $reldepth <= $i ) {
		    push @{$levelsarray[$i-1]->{DATA}},{
			SIZE=>$cur->{SPACE}, 
			DIR=>$cur->{DIR}
		    };
		};
	    };
	};
	$timebin_element->{LEVELS} = \@levelsarray;
	push @timebins, $timebin_element;
    };
    $node_element->{'TIMEBINS'} = \@timebins;
    print Data::Dumper::Dumper ($node_element);
};

sub checklevel {
    my ($rootdir,$path)=@_;
    my @p = split "/", $path;
    my @r = split "/", $rootdir;
    return -1 if (@p < @r);
    my $result=1;
    for (my $i=1; $i < @p; $i += 1) {
	if ( ! $r[$i]){
	    $result += 1;
	    next;
	}
	if ( ($p[$i] ne $r[$i] )){
	    return -1;
	} 	
    }
    ( $rootdir eq "/" ) && ($result-=1);
    return $result;
};