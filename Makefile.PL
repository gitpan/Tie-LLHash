use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $name = 'Tie::LLHash';
my $file = ($name =~ /::(\w+)/)[0] . '.pm';

WriteMakefile(
    'NAME'	=> $name,
    'VERSION_FROM' => $file, # finds $VERSION
    'dist' => { COMPRESS=>'gzip',
		SUFFIX=>'gz',
		PREOP=>qq{rm -f Changes; cvs log $file | \$(PERL) -MCVS::Parse -e "prettylog" > Changes},
	      }

);
