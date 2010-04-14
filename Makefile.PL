use inc::Module::Install 0.95;

name     'Log-UDP-Server';
author   'Robin Smidsrød <robin@smidsrod.no>';
license  'perl';
all_from 'lib/Log/UDP/Server.pm';

requires 'MooseX::POE'        => 0;
requires 'IO::Socket::INET'   => 0;
requires 'Data::Serializable' => '0.03';

test_requires 'Test::More'    => 0;

WriteAll;

