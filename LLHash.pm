package Tie::LLHash;
use strict;
use vars qw($VERSION);
use Carp;


$VERSION = '0.02';


sub TIEHASH {
   my $pkg = shift;

   my $self = {};
   bless($self, $pkg);
   $self->CLEAR;
   
   # Initialize the hash if more arguments are given
   while (@_) {
      $self->last( splice(@_, 0, 2) );
   }
   
   return $self;
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
   my $debug = 0;
   

print ("Deleting $key ...") if $debug;
   return unless $self->EXISTS($key);
   
   if ($self->{'first'} eq $self->{'last'}) {
print ("only key\n") if $debug;
      $self->{'first'} = undef;
      $self->{'current'} = undef;
      $self->{'last'} = undef;

   } elsif ($self->{'first'} eq $key) {
print ("first key\n") if $debug;
      $self->{'first'} = $self->{'nodes'}{$key}{'next'};
      $self->{'nodes'}{ $self->{'first'} }{'prev'} = undef;

   } elsif ($self->{'last'} eq $key) {
print ("last key\n") if $debug;
      $self->{'last'} = $self->{'nodes'}{$key}{'prev'};
      $self->{'nodes'}{ $self->{'last'} }{'next'} = undef;

   } else {
print ("middle key\n") if $debug;
      my $key_one = $self->{'nodes'}{$key}{'prev'};
      my $key_three = $self->{'nodes'}{$key}{'next'};
      $self->{'nodes'}{$key_one}{'next'} = $key_three;
      $self->{'nodes'}{$key_three}{'prev'} = $key_one;
   }
   
   return (delete $self->{'nodes'}{$key}, $self->reset)[0];
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

   my $three_key = $self->{'nodes'}{$one_key}{'next'};

   $self->{'nodes'}{$one_key}{'next'} = $two_key;

   $self->{'nodes'}{$two_key}{'prev'} = $one_key;
   $self->{'nodes'}{$two_key}{'next'} = $three_key;
   $self->{'nodes'}{$two_key}{'value'} = $two_value;
   
   if (defined $three_key) {
      $self->{'nodes'}{$three_key}{'prev'} = $two_key;
   }

   # If we're adding to the end of the hash, adjust the {last} pointer:
   if ($one_key eq $self->{'last'}) {
      $self->{'last'} = $two_key;
   }

   return $two_value;
}

sub first {
   my $self = shift;
   
   if (@_) { # Set it
      my $newkey = shift;
      my $newvalue = shift;

      croak ("'$newkey' already exists") if $self->EXISTS($newkey);
      
      # Create the new node
      $self->{'nodes'}{$newkey} =
      {
         'next'  => undef,
         'value' => $newvalue,
         'prev'  => undef,
      };
      
      # Put it in its relative place
      if (defined $self->{'first'}) {
         $self->{'nodes'}{$newkey}{'next'} = $self->{'first'};
         $self->{'nodes'}{ $self->{'first'} }{'prev'} = $newkey;
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
   
      # Create the new node
      $self->{'nodes'}{$newkey} =
      {
         'next'  => undef,
         'value' => $newvalue,
         'prev'  => undef,
      };

      # Put it in its relative place
      if (defined $self->{'last'}) {
         $self->{'nodes'}{$newkey}{'prev'} = $self->{'last'};
         $self->{'nodes'}{ $self->{'last'} }{'next'} = $newkey;
      }

      # Finally, make this node the last node
      $self->{'last'} = $newkey;

      # If this is an empty hash, make it the first node too
      $self->{'first'} = $newkey unless (defined $self->{'first'});
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
 tie (%hash2, "Tie::LLHash", "key1"=>$val1, "key2"=>$val2); # A new hash with stuff in it
 
 # Add some entries:
 (tied %hash)->first('the' => 'hash');
 (tied %hash)->insert('here' => 'now', 'the'); 
 (tied %hash)->first('All' => 'the');
 (tied %hash)->insert('are' => 'right', 'the');
 (tied %hash)->insert('things' => 'in', 'All');
 (tied %hash)->last('by' => 'gum');
 
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
 
 
=head1 ITERATION TECHNIQUES

Here is a smattering of ways you can iterate over the hash.  I include it here
simply because iteration is probably important to people who need ordered data.

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

=head1 WARNINGS

=over 4

=item * Don't add new elements to the hash by simple assignment, a 
la <$hash{$new_key} = $value>, because LLHash won't know where in
the order to put the new element.


=head1 TO DO

 I need to write documentation for all the functions here.
 
 I might make $hash{$new_key} = $new_value a synonym for 
 (tied %hash)->last($new_key, $new_value) when $new_key doesn't exist 
 already.  This behavior would be optional.  In some cases it could be
 dangerous, for example if you thought an element was already in the 
 hash but it wasn't, or vice versa.
 
 I could speed up the keys() routine in a scalar context if I kept
 track of how many entries were in the hash.
 
 I may also want to add a method for... um, I forgot.

=head1 AUTHOR

Ken Williams <ken@forum.swarthmore.edu>

Copyright (c) 1998 Swarthmore College. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut