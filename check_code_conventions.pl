#!/usr/bin/perl

# This script performs some basic checks regarding the coding conventions.
# It expects signatures and purpose statements BEFORE the function definition.

use strict;
use warnings;

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

# Error messages 
my $errorStat = "; Comment: The name of you static object does not respect the coding convention";
my $errorFun = "; Comment: The name of you function does not respect the coding convention";

# Patterns
my $pSignature = qr/(?<!-)->/;
my $pFun = qr/^[ ]*\([ ]*define[ ]*\(\w+/;
my $pStat = qr/^[ ]*\([ ]*define[ ]+\w+/;
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
  return $n;
}

sub get_number_arg_fundef {
  my $stripped_string = $_[0] =~ s/.*define \([a-zA-Z\-0-9\+]+ ([a-zA-Z0-9_\- ]*)\).*/$1/r;
  #print "get_number_arg_fundef : Stripped_string $stripped_string\n\n";
  my $n = () = $stripped_string =~ /\S+/g;
  return $n;
}

# Checks whether the coding convention for functions is satisfied
# and add name to fun_names
sub check_coding_convention_fun {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define[ ]+\([ ]*([a-zA-Z\-0-9\+]+).*/$1/r;
  push( @fun_names, $stripped_string);
  if ( $stripped_string =~ m/[A-Z_]/ ) {
    print "$_[1]: Illegal Character in function defintion $_[0]\n";
  }
  return;
}

sub check_coding_convention_const {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define[ ]+(\w+\b).*/$1/r;
  if ( $stripped_string =~ m/[a-z_]/ ) {
    print "$_[1]: Illegal Character in constant definition in line: $_[0]\n";
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
        print "$lineCtr: Number of arguments (".get_number_arg_fundef($l).") does not match the number of arguments in the signature ($signature)\n";
      }
    }

    if ( $l =~ m/$pStat/ ) {
      check_coding_convention_const( $l, $lineCtr);
    }

    if ( $l =~ m/define-struct/ and  $interpretation == 0 ) {
      print "$lineCtr: Struct definition does not have an interpretation: $l\n";
    }

    reset_checks();
  }

  if ( $l =~ m/check-/ ) {
    get_fun_check( $l);
  }
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
      $signature = get_number_arg_signature( $l);
    } else {
      print "$lineCtr: Second signature: $l\n";
    }
  } 
}

for my $l (@lines) {
  $lineCtr++;

  # Skip empty lines and empty comments
  if ( $l =~ m/^[\;]*[ ]*$/ ) {
    next;
  }

  # If the line is not a comment: check for definition
  if ( $l !~ m/^\;/ ) {
    check_code( $l);
  } else {
    check_comments( $l);
  } 
}

#print( "@checks", ",");
#print "\n";
#print( "@fun_names", ",");

if ( @checks == 0 ) {
  print "No checks!\n";
} else {
  my $local_str = "";
  for my $f (@fun_names) {
    my @matches = grep { /$f/ } @checks;
    if ( @matches == 0  ) {
      $local_str .= "$f, ";
    }
  }
  if ( $local_str eq '' ) {
    print "Everything checked!\n"
  } else {
    print "No checks for: $local_str \n";
  }
}

