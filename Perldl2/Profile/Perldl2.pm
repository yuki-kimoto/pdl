package PDL::Perldl2::Profile::Perldl2;
#
# Created on: Sun 25 Apr 2010 03:09:34 PM
# Last saved: Sun 30 May 2010 01:21:45 PM
#

use Moose;
use namespace::clean -except => [ 'meta' ];

with 'Devel::REPL::Profile';

sub plugins {
   qw(
      Commands
      CompletionDriver::Globals
      CompletionDriver::INC
      CompletionDriver::Keywords
      CompletionDriver::LexEnv
      CompletionDriver::Methods
      DDS
      History
      LexEnv
      MultiLine::PPI
      Packages
      NiceSlice
      PrintControl
      ReadLineHistory
   ); # 
}

sub apply_profile {
   my ($self, $repl) = @_;

   # add PDL::Perldl2 for plugin search
   push @{$repl->_plugin_app_ns}, 'PDL::Perldl2';

   $repl->load_plugin($_) for $self->plugins;

   # these plugins don't work on win32
   unless ($^O =~ m/win32/i) {
      $repl->load_plugin('Interrupt');
   }

   # do perldl stuff here
   $repl->eval('package main');
   $repl->eval('use PDL');
   $repl->eval('use PDL::Dbg');
   $repl->eval('use PDL::Doc::Perldl');
   $repl->eval('use PDL::IO::Dumper');
   $repl->eval('use PDL::IO::FlexRaw');
   $repl->eval('use PDL::IO::Pic');
   $repl->eval('use PDL::Image2D');
   $repl->eval('use PDL::AutoLoader');
   $repl->eval('no strict qw(vars)');
   $repl->eval('sub p { local $, = " "; print @_, "\n" };');

   if ($repl->can('exit_repl')) {
      $repl->eval('sub quit { $_REPL->exit_repl(1) };');
   } else {
      $repl->eval('sub quit { $_REPL->print("Use Ctrl-D or exit to quit" };');
   }

   $repl->prompt("PDL> ");  # new prompt

   if ( defined $ENV{TERM} and $ENV{TERM} eq 'dumb' ) {
      $repl->print("\n");
      $repl->print("******************************************\n");
      $repl->print("* Warning: TERM type is dumb!            *\n");
      $repl->print("* Limited ReadLine functionality will be *\n");
      $repl->print("* available.  Please unset TERM or use a *\n");
      $repl->print("* different terminal type.               *\n");
      $repl->print("******************************************\n");
      $repl->print("\n");
   }

   $repl->print("perlDL shell v2.000
 PDL comes with ABSOLUTELY NO WARRANTY. For details, see the file
 'COPYING' in the PDL distribution. This is free software and you
 are welcome to redistribute it under certain conditions, see
 the same file for details.\n");

   $repl->print("Loaded plugins:\n");
   {
      my @plugins = ();
      foreach my $pl ( $repl->_plugin_locator->plugins ) {
         # print names of ones that have been loaded
         my $plug = $pl;
         $plug =~ s/^.*Plugin::/  /;
         push @plugins, $plug if $repl->does($pl);
      }
      $repl->print(join "\n", sort(@plugins));
      $repl->print("\n");
   }
           
   $repl->print("Type 'help' for online help\n");
   $repl->print("Type Ctrl-D or quit to exit\n");
   $repl->print("Loaded PDL v$PDL::VERSION\n");
}

1;

__END__

=head1 NAME

Devel::REPL::Profile::Perldl2 - profile for Perldl2 shell

=head1 SYNOPSIS

    system> re.pl --profile=Perldl2     # unixen shell
    system> re --profile=Perldl2        # win32 CMD shell

    perlDL shell v2.000
    PDL comes with ABSOLUTELY NO WARRANTY. For details, see the file
    'COPYING' in the PDL distribution. This is free software and you
    are welcome to redistribute it under certain conditions, see
    the same file for details.

    Loaded plugins:

      Commands
      Completion
      CompletionDriver::Globals
      CompletionDriver::INC
      CompletionDriver::Keywords
      CompletionDriver::LexEnv
      CompletionDriver::Methods
      DDS
      FindVariable
      History
      Interrupt
      LexEnv
      MultiLine::PPI
      NiceSlice
      Packages
      PrintControl
      ReadLineHistory
    Type 'help' for online help
    Type Ctrl-D or quit to exit
    Loaded PDL v2.4.6_007
    PDL> 


=head1 DESCRIPTION

This profile is for development of the new PDL shell version 2.
After development is complete, the C<Devel::REPL> implementation
will be folded into a script to start the shell directly.

=head1 SEE ALSO

C<Devel::REPL>, C<Devel::REPL::Profile>, and C<PDL::Perldl>.

=head1 AUTHOR

Chris Marshall, C<< <chm at cpan dot org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Christopher Marshall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut