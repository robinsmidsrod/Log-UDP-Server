use inc::Module::Install 0.87;

name     'Log-UDP-Server';
all_from 'lib/Log/UDP/Server.pm';
author   'Robin Smidsrød <robin@smidsrod.no>';
license  'perl';

requires 'MooseX::POE'        => 0;
requires 'IO::Socket::INET'   => 0;
requires 'Data::Serializable' => 0;

test_requires 'Test::More'    => 0;

WriteAll;

