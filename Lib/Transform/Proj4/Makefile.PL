#
# Makefile.PL for PDL::Transform::Proj4
#
# Judd Taylor, USF IMaRS
# 18 March 2003
#

use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

BEGIN
{
    # Generic descripton of how to optionally add this package to the PDL Tree:
    $package_name = "PDL::Transform::Proj4";
    $lib_name = "Proj4";
    $find_libs = [ 'libproj.so', 'libproj.a' ];
    $find_incs = [ 'proj_api.h' ];
    $config_flag = 'WITH_PROJ';
    $config_libs = 'PROJ_LIBS';
    $config_incs = 'PROJ_INC';
    @lib_locations = (
        '/usr/lib64',
        '/usr/local/lib64',
        '/lib64',
        '/usr/lib',
        '/usr/local/lib',
        '/lib'
    );
    @inc_locations = (
        '/usr/include',
        '/usr/local/include'
    ); 
    
    #
    # You probably won't need to edit anything below here (until the very end):
    #

    $msg = "";
    $forcebuild=0;  # Note: forcebuild not used

    if (defined $PDL::Config{$config_flag} && $PDL::Config{$config_flag}==0) 
    {
        $msg = "\n   Will skip build of $package_name on this system   \n";
        goto skip;
    }
    
    if (defined $PDL::Config{$config_flag} && $PDL::Config{$config_flag}==1) 
    {
        print "\n   Will forcibly try and build $package_name on this system   \n\n";
        $forcebuild=1;
    }
    
    # Look for Proj4 includes/libs

    # get locations from perldl.conf, if specified there:
    @lib_locations = @{$PDL::Config{$config_libs}} 
        if( defined $PDL::Config{$config_libs} );
    @inc_locations = @{$PDL::Config{$config_incs}} 
        if( defined $PDL::Config{$config_incs} );

    #
    # Do the search:
    #
    # Look for the libs:
    foreach my $libdir ( @lib_locations ) 
    {
        my $found = 0;
        foreach my $find_lib ( @$find_libs )
        {
            if ( -e "$libdir/$find_lib" ) 
            {
                $lib_path = $libdir;
                $found = 1;
            }
            last if $found;
        }
        last if $found;
    } # foreach $libdir...

    unless( defined( $lib_path ) )
    {
        $msg .= "Cannot find $lib_name library, $find_lib.\n"
              . "Please add the correct library path to Makefile.PL or install $lib_name\n.";
    }

    # Look for the include files:
    foreach my $incdir ( @inc_locations ) 
    {
        foreach my $find_inc ( @$find_incs )
        {
            if ( -e "$incdir/$find_inc" ) 
            {
                $include_path = $incdir;
                last;
            }
        }
    }

    unless( defined( $include_path ) )
    {
        $msg .= "Cannot find $lib_name header file, $find_inc.\n"
              . "Please add the correct library path to Makefile.PL or install $lib_name.\n";
    }
    
    #
    # Make sure everything we wanted is found:
    #
    $donot = 1;
    if( defined( $include_path ) && defined( $lib_path ) )
    {
        $donot = 0;
    }
    
    if ( $donot )
    {
        $msg .= "\n Skipping build of $package_name.\n";
    }
    
skip:
    
    if ($msg ne "" && $forcebuild==0) 
    {
        warn $msg . "\n";
        $msg =~ s/\n//g;
        write_dummy_make( $msg );
        $donot = 1;
    } 
    else 
    {
        print "\n   Building $package_name. Turn off $config_flag if there are any problems\n\n";
    }

} # BEGIN...

return if $donot;

$ppfile = "Proj4.pd";
$package = [$ppfile, Proj4, $package_name];
%hash = pdlpp_stdargs($package);
$hash{VERSION_FROM} = $ppfile;
#$hash{TYPEMAPS} = [&PDL_TYPEMAP()];
$hash{LIBS} = ["-L$lib_path -lproj -lm"];
$hash{INC} = PDL_INCLUDE() . " -I$include_path";
WriteMakefile(%hash);

sub MY::postamble { pdlpp_postamble( $package ); }