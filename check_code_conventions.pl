#!/usr/bin/perl

# This script performs some basic checks regarding the coding conventions.
# It expects signatures and purpose statements BEFORE the function definition.

use strict;
use warnings;

my $lineCtr = 0; # line counter
my $checkPurpose = 0;
my $filename = "";

if ( @ARGV == 0 ) {
  print "Use: perl check_code_convention.pl [-p|p] file.rkt [line_ctr_offset]\n";
  exit
} else {
  my @fn= grep( /.*\.rkt/, @ARGV);
  if ( @fn != 0 ) {
    $filename = $fn[0];
  } else { 
    print "No .rkt file given";
    exit
  }
  my @offset = grep( /[0-9]+/, @ARGV);
  if ( @offset != 0 ) {
    $lineCtr = $offset[0];
  }
  if ( /^[\-]*p$/ ~~ @ARGV ) {
    $checkPurpose = 1;
  } 
}

print "Checking File $filename\n";

# Read in file
my @lines;
open(my $fh, "<", $filename)
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
my $pLocal = qr/^[ ]*\([ ]*local[ ]*\[/;

# List of function names
my @fun_names = ();
my @checks = ();
my @struct_args = ();
my @structs = ();

# Check variables
my $signature = 0; # Set to number of variables if "->" is found
my $purpose = 0; # Set to 1 if purpose is found
my $interpretation = 0; # Set to 1 if interpretation is found (for structs)
my $local = 0; # Set to 1 if local definitions

sub reset_checks {
  $signature = 0;
  $purpose = 0;
  $interpretation = 0;
  $local = 0;
  return;
}

sub get_number_arg_signature {
  # First remove "->" encapsulated in parentheses
  my $stripped_string = $_[0] =~ s{(\[ .*? \])}{$1 =~ y/\-\>//dr}gexr;
  # remove everything before : and after ->
  $stripped_string =~ s/\;|.*:|\-\>.*//g; 
  if ( $stripped_string =~ m/[\-_]/ ) {
    print "$_[1]: Illegal Character in signature (types should be camel case): $_[0]\n";
  }
  if ( $stripped_string =~ m/\b([A-Z0-9][a-z0-9]+)*/  ) {
    print "$_[1]: Illegal Character in signature (types should be camel case): $_[0]\n";
  }
  $stripped_string =~ s{(\[ .*? \])}{$1 =~ y/ //dr}gex;
  #print "get_number_arg_signature : Stripped_string $stripped_string\n\n";
  my $n = () = $stripped_string =~ /\S+/g;
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
    print "$_[1]: Illegal Character in function defintion (function names should be kebab case): $_[0]\n";
  }
  return;
}

sub check_coding_convention_const {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define[ ]+([\w\-_]+\b).*/$1/r;
  if ( $stripped_string =~ m/[a-z_]/ ) {
    print "$_[1]: Illegal Character in constant definition (constants should be all capitalized): $_[0]\n";
  }
  return;
}

sub check_coding_convention_struct {
  if ( $interpretation == 0 ) {
    print "$_[1]: Struct definition does not have an interpretation: $_[0]\n";
  }

  # Check whether it is CamelCase
  if ( $_[0] =~ m/[A-Z_]/  ) {
    print "$_[1]: Illegal Character struct definition (no caps or underscores): $_[0]\n";
  }
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*define-struct[ ]+(\S+\b)[ ]*\[.*/$1/r;
  push( @structs, $stripped_string);
  #print "check_coding_convention_type: Stripped_string $stripped_string\n\n";
  #if ( $stripped_string =~ m/[A-Z_]/  ) {
  #  print "$_[1]: Illegal Character struct definition: $_[0]\n";
  #}
  return;
}

sub get_fun_check {
  my $stripped_string = $_[0] =~ s/^[ ]*\([ ]*check-\w+[ ]+\([ ]*([a-zA-Z\-0-9\+]+).*/$1/r;
  push( @checks, $stripped_string);
}

sub check_code {
  my $l = $_[0];

  if ( $l =~ m/define/ ) {

    # Ignore line if either there is a local definition or a preceeding unclosed local definition
    # NB: does not recognize the corresponding braces but mere the next one. Nested expressions 
    # migh be problematic.
    if ( $local == 0 and $l =~ m/$pLocal/ and $l !~ m/\]/) {
      $local = 1;
      return;
    } elsif ( ($local == 1 and $l !~ m/\]/) or ($local == 0 and $l =~ m/$pLocal/ and $l =~ m/\]/ )) {
      return;
    } elsif ( $local == 1 and $l =~ m/\]/ ) {
      $local = 0;
      return;
    }

    # If line contains a function definition check for signature and purpose
    if ( $l =~ m/$pFun/ ) {

      # print "Function definition in $lineCtr\n$l\n";

      check_coding_convention_fun( $l, $lineCtr);

      if ( $purpose == 0 and $checkPurpose != 0 ) {
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

if ( @structs != 0 ) {
  my $local_str = "Defined structs: ";
  for my $s (@structs) {
    $local_str .= "$s, ";
  }
  print $local_str."\n";
}

