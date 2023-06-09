#!/usr/bin/env perl
#---------------
# Alex Lomsadze
# 2023, GerogiaTech 
#
# This script takes as input file with repeat coordinates from RepeatMasker
# and outputs repeat coordinates in GFF format for gene annotation pipeline MAKER
#    rmasker_out2maker_gff.pl < genome.fasta.out > rmasker4maker.gff
#---------------

use strict;
use warnings;

my $id = 1;

while(<>)
{
   my @arr = split(' ');

   next if /^\s*$/;
   next if ( $arr[0] eq "SW" );
   next if ( $arr[0] eq "score" );

   my $strand = "+";
   $strand = "-" if ( $arr[8] eq "C" );

   my $Lm = $arr[11];
   my $Rm = $arr[12];

   if ( $strand eq '-' )
   {
      $arr[11] =~ s/[()]//g;
      $Lm = $arr[11];
   }

   if ( $Lm > $Rm )
   {
      $Lm = $arr[12];
      $Rm = $arr[11];
   }

   if ( $Lm == 0 )
   {
      $Lm = 1;
   }

   my $ID1    = "ID=RM_".     $id ."_hit;";
   my $ID2    = "ID=RM_".     $id ."_hsp;";
   my $PARENT = "Parent=RM_". $id ."_hit;";
   my $NAME   = "Name=".   $arr[10] .";";
   my $TARGET = "Target=". $arr[10] . " ". $Lm ." ". $Rm ." ". "+";

   print $arr[4] ."\trepeatmasker\tmatch\t"     . $arr[5] ."\t". $arr[6] ."\t". $arr[0] ."\t". $strand ."\t.\t". $ID1 . $NAME   . $TARGET ."\n";
   print $arr[4] ."\trepeatmasker\tmatch_part\t". $arr[5] ."\t". $arr[6] ."\t". $arr[0] ."\t". $strand ."\t.\t". $ID2 . $PARENT . $TARGET ."\n";

   $id += 1;
}
