package Tie::LLHash;
use strict;
use vars qw($VERSION);
use Carp;


$VERSION = '0.01';


sub TIEHASH {
	my $pkg = shift;

	my $self = {
		'first' => undef,
		'current' => undef,
		'last' => undef,
		'nodes' => {},
	};
	return bless($self, $pkg);
}

# Standard access methods:

sub FETCH {
	my $self = shift;
	my $key = shift;

	return undef unless $self->EXISTS($key);
	return $self->{'nodes'}{$key}{'value'};
}

sub STORE {
	my $self = shift;
	my $name = shift;
	my $value = shift;

	croak ("No such key '$name', use first or insert to add keys") unless $self->EXISTS($name);
	return $self->{'nodes'}{$name}{'value'} = $value;
}


sub FIRSTKEY {
	my $self = shift;
	return $self->{'current'} = $self->{'first'};
}

sub NEXTKEY {
	my $self = shift;
	return $self->{'current'} = $self->{'nodes'}{ $self->{'current'} }{'next'};
}

sub EXISTS {
	my $self = shift;
	my $name = shift;
	return exists $self->{'nodes'}{$name};
}

sub DELETE {
	my $self = shift;
	my $key = shift;
	
	return unless $self->EXISTS($key);
	
	if ($self->{'first'} eq $key) {
		$self->{'first'} = $self->{'nodes'}{$key}{'next'};
		delete $self->{'nodes'}{ $self->{'first'} }{'prev'};  # Need to check existance?
	} elsif ($self->{'last'} eq $key) {
		$self->{'last'} = $self->{'nodes'}{$key}{'prev'};
		delete $self->{'nodes'}{ $self->{'last'} }{'next'};  # Need to check existance?
	} else {
		my $key_one = $self->key_before($key);
		my $key_three = $self->key_after($key);
		$self->{'nodes'}{$key_one}{'next'} = $key_three;
		$self->{'nodes'}{$key_three}{'prev'} = $key_one;
	}
	delete $self->{'nodes'}{$key};
	$self->reset;
}

sub CLEAR {
	my $self = shift;
	
	$self->{'first'} = undef;
	$self->{'last'} = undef;
	$self->{'current'} = undef;
	$self->{'nodes'} = {};
}

# Special access methods 
# Use (tied %hash)->method to get at them

sub insert {
	my $self = shift;
	my $two_key = shift;
	my $two_value = shift;

	unless (@_) {
		croak ("Must supply 3 arguments to ->insert() method");
	}
	my $one_key = shift;

	croak ("No such key '$one_key'") unless $self->EXISTS($one_key);
	croak ("'$two_key' already exists") if $self->EXISTS($two_key);

	my $three_key = $self->key_after($one_key);

	$self->{'nodes'}{$one_key}{'next'} = $two_key;

	$self->{'nodes'}{$two_key}{'prev'} = $one_key;
	$self->{'nodes'}{$two_key}{'next'} = $three_key;
	$self->{'nodes'}{$two_key}{'value'} = $two_value;
	
	if (defined $three_key) {
		$self->{'nodes'}{$three_key}{'prev'} = $two_key;
	}

	return;
}

sub first {
	my $self = shift;
	
	if (@_) { # Set it
		my $newkey = shift;
		my $newvalue = shift;

		croak ("'$newkey' already exists") if $self->EXISTS($newkey);
		
		$self->{'nodes'}{$newkey} =
		{
			'next'  => undef,
			'value' => $newvalue,
			'prev'  => undef,
		};
		
		if (defined $self->{'first'}) {
			$self->{'nodes'}{$newkey}{'next'} = $self->{'first'};
			$self->{'nodes'}{ $self->{'first'} }{'prev'} = $newkey
		}
		
		# Finally, make this node the first node
		$self->{'first'} = $newkey;

		# If this is an empty hash, make it the last node too
		$self->{'last'} = $newkey unless (defined $self->{'last'});
	}
	return $self->{'first'};
}

sub last {
	my $self = shift;
	
	if (@_) { # Set it
		my $newkey = shift;
		my $newvalue = shift;

		croak ("'$newkey' already exists") if $self->EXISTS($newkey);
	
		$self->{'nodes'}{ $self->{'last'} }{'next'} = $newkey;
		$self->{'nodes'}{$newkey}{'prev'} = $self->{'last'};
		$self->{'nodes'}{$newkey}{'value'} = $newvalue;
	
		$self->{'last'} = $newkey;
	}
	return $self->{'last'};
}

sub key_before {
	my $self = shift;
	my $name = shift;

	return $self->{'nodes'}{$name}{'prev'};
}

sub key_after {
	my $self = shift;
	my $name = shift;

	return $self->{'nodes'}{$name}{'next'};
}

sub current_key {
	my $self = shift;
	return $self->{'current'};
}

sub current_value {
	my $self = shift;
	return $self->get($self->{'current'});
}

sub next  { my $s=shift; $s->NEXTKEY($_) }
sub prev  {
	my $self = shift;
	return $self->{'current'} = $self->{'nodes'}{ $self->{'current'} }{'prev'};
}
sub reset { my $s=shift; $s->FIRSTKEY($_) }

1;
__END__

=head1 NAME

Tie::LLHash.pm - ordered hashes

=head1 DESCRIPTION

This class implements an ordered hash-like object.  It's a cross between a
Perl hash and a linked list.  Use it whenever you want the speed and
structure of a Perl hash, but the orderedness of a list.  

Don't use it if you want to be able to address your hash entries by number, 
like you can in a real list ($list[5]).

See also Tie::IxHash by Gurusamy Sarathy.  It's similar (it does
ordered hashes), but it has a different internal data structure and a different 
flavor of usage.  It makes your hash behave more like a list than this does.

=head1 SYNOPSIS

 use Tie::LLHash;
 
 tie (%hash, "Tie::LLHash"); # A new empty hash
 
 # Add some entries:
 (tied %hash)->first('the' => 'hash');
 (tied %hash)->insert('here' => 'now', 'the'); 
 (tied %hash)->first('All' => 'the');
 (tied %hash)->insert('are' => 'right', 'the');
 (tied %hash)->insert('things' => 'in', 'All');
 
 $value = $hash{'things'}; # Look up a value
 $hash{'here'} = 'NOW';    # Set the value of an EXISTING RECORD!
 
 
 $key = (tied %hash)->key_before('in');  # Returns the previous key
 $key = (tied %hash)->key_after('in');   # Returns the next key
 

 # Luxury routines:
 $key = (tied %hash)->current_key;
 $val = (tied %hash)->current_value;
 (tied %hash)->next;
 (tied %hash)->prev;
 (tied %hash)->reset;
 
 
 ###### Iteration techniques
 # Here is a smattering of ways you can iterate over the hash.  I include it here
 # simply because iteration is probably important to people who need ordered data.
 
 while (($key, $val) = each %hash) {
    print ("$key: $val\n");
 }
 
 foreach $key (keys %hash) {
    print ("$key: $hash{$key}\n");
 }
 
 my $obj = tied %hash;  # For the following examples

 $key = $obj->reset;
 while (exists $hash{$key}) {
    print ("$key: $hash{$key}\n");
    $key = $obj->next;
 }

 $obj->reset;
 while (exists $hash{$obj->current_key}) {
    $key = $obj->current_key;
    print ("$key: $hash{$key}\n");
    $obj->next;
 }

=head1 TO DO

 It would be nice if you could do:
  tie(%hash, 'Tie::LLHash', key1=>6, key2=>9, ...);
 Probably wouldn't be all that hard either.

 I could speed up the keys() routine in a scalar context if I kept
 track of how many entries were in the hash.

 I may also want to add a method for... um, I forgot.

=head1 AUTHOR

Ken Williams <ken@forum.swarthmore.edu>

Copyright (c) 1998 Swarthmore College. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
