
# Slatec module

use ExtUtils::MakeMaker;
use Config;
PDL::Core::Dev->import();

# This mess sorts out the Fortran availability - KGB.
# Depends on ExtUtils::F77

BEGIN {
   $donot = 0;
   $msg = ""; $forcebuild=0;

   if (defined $PDL::Config{WITH_SLATEC} && $PDL::Config{WITH_SLATEC}==0) {
      $msg = "\n   Will skip build of PDL::Slatec on this system   \n";
      goto skip;
   }

   if (defined $PDL::Config{WITH_SLATEC} && $PDL::Config{WITH_SLATEC}==1) {
      print "\n   Will forcibly try and build PDL::Slatec on this system   \n\n";
      $forcebuild=1;
   }

   if (exists $PDL::Config{F77CONF} && -f $PDL::Config{F77CONF}) {
     print "loading F77 configuration from $PDL::Config{F77CONF}...\n";
     eval "require '$PDL::Config{F77CONF}'";
     if ($@ ne "") {
       $msg = "\n".$@.
	 "\n\tF77CONF file not loaded. Ought not build PDL::Slatec\n" ;
       goto skip unless $forcebuild;
     }
     $f77 = 'F77Conf';
   } else {
     eval "use ExtUtils::F77";  # Might want "use ExtUtils::F77 qw(generic f2c)"
     if ($@ ne "") {
       $msg = "\n".$@.
	 "\n\tExtUtils::F77 module not found. Ought not build PDL::Slatec\n" ;
       goto skip unless $forcebuild;
     } else {
       $f77 = 'ExtUtils::F77';
       print "(ExtUtils Version $ExtUtils::F77::VERSION)\n";
       if ($ExtUtils::F77::VERSION < 1.03 ) {
	 $msg = "\n\tneed a version of ExtUtils::F77 >= 1.03. Ought not build PDL::Slatec\n" ;
	 goto skip unless $forcebuild;
       }
     }  # end if ($@ ne "")
   } # if (exists $PDL::Config{F77CONF}...

   $compiler_available = $f77->testcompiler;

   if (!$compiler_available) {
      $msg = "\n   No f77 compiler found. Ought to skip PDL::Slatec on this system    \n";
      $PDL::Config{WITH_SLATEC} = 0;
   } else {
      $PDL::Config{WITH_SLATEC} = 1;
   }

   skip:

   if ($msg ne "" && $forcebuild==0) {
       warn $msg . "\n";
       $msg =~ s/\n//g;
       write_dummy_make( $msg );
       $PDL::Config{WITH_SLATEC} = 0;
       $donot = 1;
   } else {
      print "\n   Building PDL::Slatec. Turn off WITH_SLATEC if there are any problems\n\n";
      $PDL::Config{WITH_SLATEC} = 1;
   }
}

return if $donot;


@pack = (["slatec.pd",Slatec,PDL::Slatec]);
@slatecfiles = map {s/^slatec\///; s/\.f$//; $_} glob("slatec/*.f");

%hash = pdlpp_stdargs_int(@::pack);

$hash{OBJECT} .= join '', map {" slatec/${_}$Config{obj_ext} "} @slatecfiles;

if($Config{cc} eq 'cl') {
# Link to MinGW's libg2c.a and libgcc.a, if appropriate
# First check that ExtUtils::F77 is available
  eval{require ExtUtils::F77};
  unless($@) {
    my @f = ();

    my $drive = (split /:/, `gcc -v 2>&1`)[0];
    $drive = substr($drive, -1, 1);

    for(split ' ', ExtUtils::F77->runtime) {
       if($_ =~ /^\-L/) {
         $_ =~ s#^\-L##;
         unless($_ =~ /:/) {$_ = $drive . ':' . $_}
         if(-e $_ . '/libg2c.a') {push @f, $_ . '/libg2c.a'}
         if(-e $_ . '/libgcc.a') {push @f, $_ . '/libgcc.a'}
       }
    }
    $hash{LDFROM} = $hash{OBJECT};
    for(@f) {$hash{LDFROM} .= ' ' . $_}
  }
}

$hash{LIBS}[0] .= $f77->runtime ;
$hash{clean}{FILES} .= " SlatecProtos.h f77_underscore" .
  join '', map {" slatec/$_.o "} @slatecfiles;

# Handle multiple compilers

$f2cbased = ($f77->runtime =~ /-lf2c/);
$g2cbased = ($f77->runtime =~ /-lg2c/) unless $f2cbased;
$trail = $f77->trail_;

# no longer create the prototypes here - this is now handled
# by slatec.pd. In fact, with the current method, we no
# longer need the .P files
#

# Create flag file according to whether or not to use
# underscores (pretty hacky)

unlink("f77_underscore") if -e "f77_underscore";
if ($trail) {
   open OUT, ">f77_underscore" or die "unable to write scratch file";
   close OUT;
}

WriteMakefile(
 %hash,
 VERSION => "0.12",   # This is overridden by VERSION_FROM in %hash 
);

sub MY::postamble {
        $mycompiler     = $f77->compiler();
        $mycflags       = $f77->cflags();
	my $orig = pdlpp_postamble_int(@::pack);
	$hack_64bit = ($Config{archname}=~m/x86_64/ ?" -fPIC " : "");
	$orig =~ s/:\s*slatec\.pd/: slatec.pd/;
	$orig .join "\n",map {
("

slatec/$_\$(OBJ_EXT): slatec/$_.f 
	$mycompiler -c $hack_64bit -o slatec/$_\$(OBJ_EXT) $mycflags slatec/$_.f
" )} @slatecfiles;
 
}
