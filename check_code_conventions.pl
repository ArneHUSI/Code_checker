#!/usr/bin/perl

# This script performs some basic checks regarding the coding conventions.
# It expects signatures and purpose statements BEFORE the function definition.

use strict;
use warnings;

if ( @ARGV == 0 ) {
  print "Use: perl check_code_convention.pl file.rkt [line_ctr_offset]\n";
  exit
}
print "Checking File $ARGV[0]\n";

# Read in file
my @lines;
open(my $fh, "<", $ARGV[0])
  or die "Failed to open file: $!\n";
while(<$fh>) { 
  chomp; 
  push @lines, $_;
} 
close $fh;

# Patterns
my $pSignature = qr/(?<!-)->/;
my $pFun = qr/^[ ]*\([ ]*define[ ]*\(\w+/;
my $pConst = qr/^[ ]*\([ ]*define[ ]+\w+/;
my $pStruct = qr/^[ ]*\([ ]*define-struct[ ]+\w/;
my $pPurpose = qr/(Purpose|purpose|.*Given.*return|given.*return|return.*given|Interpretation)/i;
my $pInterpretation = qr/(Interpretation|Interp)/i;

# List of function names
my @fun_names = ();
my @checks = ();
my @struct_args = ();

# Check variables
my $signature = 0; # Set to number of variables if "->" is found
my $purpose = 0; # Set to 1 if purpose is found
my $interpretation = 0; # Set to 1 if interpretation is found (for structs)

my $lineCtr = 0; # line counter
if ( scalar @ARGV == 2 ) {
  $lineCtr = $ARGV[1];
}

sub reset_checks {
  $signature = 0;
  $purpose = 0;
  $interpretation = 0;
  return;
}

sub get_number_arg_signature {
  my $stripped_string = $_[0] =~ s/\;|.*:|\-\>.*//gr; # remove everything before : and after ->
  #print "get_number_arg_signature : Stripped_string $stripped_string\n\n";
  my $n = () = $stripped_string =~ /\S+/g;
  if ( $stripped_string =~ m/[\-_]/ ) {
    print "$_[1]: Illegal Character in types of signature: $_[0]\n";
  }
  if ( $stripped_string =~ m/\b[a-z]+/  ) {
    print "$_[1]: Illegal Character in types of signature (CamelCase starts with capital): $_[0]\n";
  }
  return $n;
}

# \S ... match a non-whitespace character
sub get_number_arg_fundef {
  my $stripped_string = $_[0] =~ s/.*define \(\S+ ([a-zA-Z0-9_\- ]*)\).*/$1/r;
  #print "get_number_arg_fundef : Stripped_string $stripped_string\n\n";
  my $n = () = $stripped_string =~ /\S+/g;
  return $n;
}

# Checks whether the coding convention for functions is satisfied
# and add name to fun_names
sub check_coding_convention_fun {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define[ ]+\([ ]*(\S+) .*/$1/r;
  push( @fun_names, $stripped_string);
  if ( $stripped_string =~ m/[A-Z_]/ ) {
    print "$_[1]: Illegal Character in function defintion $_[0]\n";
  }
  return;
}

sub check_coding_convention_const {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define[ ]+([\w\-_]+\b).*/$1/r;
  if ( $stripped_string =~ m/[a-z_]/ ) {
    print "$_[1]: Illegal Character in constant definition: $_[0]\n";
  }
  return;
}

sub check_coding_convention_struct {
  if ( $interpretation == 0 ) {
    print "$_[1]: Struct definition does not have an interpretation: $_[0]\n";
  }

  # Check whether it is CamelCase
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define-struct[ ]+(\S+\b)[ ]*\[.*/$1/r;
  #print "check_coding_convention_type: Stripped_string $stripped_string\n\n";
  if ( $stripped_string =~ m/[A-Z_]/  ) {
    print "$_[1]: Illegal Character struct definition: $_[0]\n";
  }
  return;
}

sub get_fun_check {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*check-\w+[ ]+\([ ]*([a-zA-Z\-0-9\+]+).*/$1/r;
  push( @checks, $stripped_string);
}

sub check_code {
  my $l = $_[0];

  if ( $l =~ m/define/ ) {

    # If line contains a function definition check for signature and purpose
    if ( $l =~ m/$pFun/ ) {

      # print "Function definition in $lineCtr\n$l\n";

      check_coding_convention_fun( $l, $lineCtr);

      if ( $purpose == 0 ) {
        print "$lineCtr: Function does not have a purpose statement: $l\n";
      }

      #print "    Signature: $signature, Number of arguments :".get_number_arg_fundef($l)."\n";
      if ( $signature != get_number_arg_fundef( $l) ) {
        if ( $signature == 0 ) {
          print "$lineCtr: No signature for function: $l\n";
        } else {
          print "$lineCtr: Number of arguments (".get_number_arg_fundef($l).") does not match the number of arguments in the signature ($signature)\n";
        }
      }
    }

    if ( $l =~ m/$pConst/ ) {
      check_coding_convention_const( $l, $lineCtr);
    }

    if ( $l =~ m/$pStruct/ ) {
      check_coding_convention_struct( $l, $lineCtr);
    }

  }

  if ( $l =~ m/check-/ ) {
    get_fun_check( $l);
  }

  reset_checks();

}

sub check_comments {
  my $l = $_[0];

  if ( $l =~ m/$pPurpose/ and $purpose == 0 ) {
    $purpose = 1;
  }

  if ( $l =~ m/$pInterpretation/ ) {
    $interpretation = 1;
  }

  if ( $l =~ m/$pSignature/ ) {
    if ( $signature == 0 ) {
      $signature = get_number_arg_signature( $l, $lineCtr);
    } else {
      print "$lineCtr: Second signature: $l\n";
    }
  } 
}

for my $l (@lines) {
  $lineCtr++;

  # Skip empty lines and empty comments
  if ( $l =~ m/^[ ]*[\;]*[ ]*$/ ) {
    next;
  }

  # If the line is not a comment: check for definition
  if ( $l !~ m/^[ ]*\;/ ) {
    check_code( $l);
  } else {
    check_comments( $l);
  } 
}

#print( "@checks", ",");
#print "\n";
#print( "@fun_names", ",");

if ( @checks == 0 ) {
  print "No tests!\n";
} else {
  my $local_str = "";
  for my $f (@fun_names) {
    my @matches = grep { /$f/ } @checks;
    if ( @matches == 0  ) {
      $local_str .= "$f, ";
    }
  }
  if ( $local_str eq '' ) {
    print "Everything tested!\n"
  } else {
    print "No tests for: $local_str \n";
  }
}

