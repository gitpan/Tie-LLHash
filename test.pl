# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

$^W = 1;

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::LLHash;
$loaded = 1;
&report_result(1);

######################### End of black magic.

sub report_result {
  $TEST_NUM++;
  print ( $_[0] ? "ok $TEST_NUM\n" : "not ok $TEST_NUM\n" );
}


{
  my (%hash, %hash2);

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

  # 7: Exercise the ->last method
  {
    my ($i, $bad);
    for ($i=0; $i<10; $i++) {
      (tied %hash)->last($i, $i**2);
    }

    $i=0;
    foreach (keys %hash) {
      $bad++ if ($i++ ne $_);
    }
    &report_result(!$bad);
  }

  # 8: delete all contents
  %hash = ();
  &report_result( !%hash );

  # 9: Combine some ->first and ->last action
  {
    my @result = qw(1 6 4 5 7 9 n r);
    (tied %hash)->first(5=>1);
    (tied %hash)->last (7=>1);
    (tied %hash)->last (9=>1);
    (tied %hash)->first(4=>1);
    (tied %hash)->last (n=>1);
    (tied %hash)->first(6=>1);
    (tied %hash)->first(1=>1);
    (tied %hash)->last (r=>1);
		
    my ($i, $bad);
    foreach (keys %hash) {
      $bad++ if ($_ ne $result[$i++]);
    }
    &report_result(!$bad);
  }

  # 10: create a new hash with an initialization hash
  {
    my @keys = qw(zero one two three four five six seven eight);

    tie(%hash2, 'Tie::LLHash', map {$keys[$_], $_} 0..8);
    my ($bad, $i) = (0,0);
		
    foreach (keys %hash2) {
      $bad++ unless ($_ eq $keys[$i]  and  $hash2{$_} eq $i++); 
    }

    &report_result( !$bad );
  }

  # 11: use insert() to add an item at the beginning
  untie %hash2;
  {
    my $t = tie(%hash2, 'Tie::LLHash', one=>1);
    $t->insert(zero=>0);
    &report_result($t->first eq 'zero' and $t->last eq 'one')
  }

  # 12: lazy mode
  untie %hash2;
  {
    tie(%hash2, 'Tie::LLHash', {lazy=>1}, zero=>0);
    $hash2{one}=1;
    my @k = keys %hash2;
    &report_result($k[0] eq 'zero' and $k[1] eq 'one')
  }
}
