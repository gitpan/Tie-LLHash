# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::LLHash;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


{
	my %hash;

	# 2: Test the tie interface
	tie (%hash, "Tie::LLHash");
	&report_result( tied %hash );

	# 3: Add first element
	(tied %hash)->first('firstkey', 'firstval');
	&report_result( $hash{firstkey} eq 'firstval' );

	# 4: Add more elements
	(tied %hash)->insert( red => 'rudolph', 'firstkey');
	(tied %hash)->insert( orange => 'julius', 'red');
	&report_result( $hash{red} eq 'rudolph' 
						and $hash{orange} eq 'julius'
						and (keys(%hash))[0] eq 'firstkey'
						and (keys(%hash))[1] eq 'red'
						and (keys(%hash))[2] eq 'orange');

	# 5: Delete first element
	delete $hash{firstkey};
	&report_result( keys %hash  == 2
						and not exists $hash{firstkey} );

	# 6: Delete all elements
	delete $hash{orange};
	delete $hash{red};
	&report_result( not keys %hash
						and not exists $hash{orange}
						and not exists $hash{red} );
}

sub report_result {
	$TEST_NUM ||= 2;
	print ( $_[0] ? "ok $TEST_NUM\n" : "not ok $TEST_NUM\n" );
	$TEST_NUM++;
}
