use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Ham::APRS::DeviceID',
    'VERSION_FROM'	=> 'DeviceID.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Test::More' => '0.1',
        'Ham::APRS::FAP' => '1.16',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM   => 'DeviceID.pm', # retrieve abstract from module
       AUTHOR          => 'Heikki Hannikainen <hessu@hes.iki.fi>',
       LICENSE        => 'perl',
      ) : ()
    ),
);
