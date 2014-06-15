#!/usr/bin/perl

use File::Find;

sub verify_version {
	unless (-e '/etc/arch-release') {
		warn <<"STOP";
Operating system is not supported. Supported operating systems are:
- Arch Linux
STOP
		exit 1;
	}
}

sub scan_directory {
	my ($directory, $package_database) = @_;

	find({wanted => sub {
		unless ($package_database->{$_}) {
			print "File $_ is not owned by any package.\n";
		}
	}, no_chdir => 1}, $directory);
}

sub read_package_database {
	my %result;

	my @package_and_files = `pacman -Ql`;
	($? >> 8) == 0 or die "Failed running pacman.\n";
	for my $package_and_file (@package_and_files) {
		if (my ($package, $file) = $package_and_file =~ m/^([^ ]+) (.*)$/) {
			# Trim trailing slashes.
			$file =~ s[/$]{};
			$result{$file} = 1;
		} else {
			die "Invalid input: $package_and_file\n";
		}
	}

	return \%result;
}

sub main {
	verify_version;
	my @directories = ('/boot', '/etc', '/mnt', '/opt', '/usr');

	my $package_database = read_package_database();

	for my $directory (@directories) {
		scan_directory($directory, $package_database);
	}
}

main;
