use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'What',
    VERSION_FROM      => 'lib/What.pm', # finds $VERSION
    PREREQ_PM         => {
        Getopt::Euclid  => 0,
        Readonly        => 0,
        Term::ReadLine  => 0,
        Data::Dumper    => 0,
    }, # e.g., Module::Name => 1.1
    EXE_FILES           => [qw{
        scripts/album-scaffold 
        scripts/album-organize
        scripts/segregate-mp3
        scripts/convert-art
        scripts/convert-flac-release
    }],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM  => 'lib/What.pm', # retrieve abstract from module
       AUTHOR         => 'Bryan Matsuo <bryan.matsuo@gmail.com>') : ()),
);
