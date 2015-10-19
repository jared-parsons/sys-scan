#!/usr/bin/perl

# search for pacnew/pacsave/pacorig files

use File::Find;
use Getopt::Long qw(:config gnu_getopt);

my $packageDirectory = "/var/cache/pacman/pkg";

sub verify_version {
	unless (-e '/etc/arch-release') {
		warn <<"STOP";
Operating system is not supported. Supported operating systems are:
- Arch Linux
STOP
		exit 1;
	}
}

my $packages = 0;
my $files = 0;
my $untrackedFiles = 0;

sub process_options {
	GetOptions(
		"packages" => \$packages,
		"files" => \$files,
		"untracked-files" => \$untrackedFiles,
	) or die "Failed processing options\n";

	if (!$packages and !$files and !$untrackedFiles) {
		# No options were specified. Use the defaults.
		$packages = 1;
		$files = 1;
	}
}

############
# Packages #
############
sub find_toplevel_dependency_packages {
	my @packages = `pacman -Qqdt`;
	my $result = $? >> 8;
	($result == 0 or $result == 1) or die "Failed running pacman.\n";
	for my $package (@packages) {
		chomp $package;
		print "Package $package was installed as a dependency but is no longer needed by any package.\n";
	}
}

sub find_foreign_packages {
	my @packages = `pacman -Qqm`;
	my $result = $? >> 8;
	($result == 0 or $result == 1) or die "Failed running pacman.\n";
	for my $package (@packages) {
		chomp $package;
		print "Package $package was not found in the sync database.\n";
	}
}

sub find_out_of_date_packages {
	my @packages = `pacman -Qqu`;
	my $result = $? >> 8;
	($result == 0 or $result == 1) or die "Failed running pacman.\n";
	for my $package (@packages) {
		chomp $package;
		print "Package $package is out of date.\n";
	}
}

#########
# Files #
#########
sub find_partially_downloaded_packages {
	my @files = glob "$packageDirectory/*.part";
	for my $file (@files) {
		print "File $file did not finish downloading.\n";
	}
}

sub find_config_files {
	my ($directory) = @_;

	find({wanted => sub {
		if ($_ =~ m/.*\.pacnew/) {
			print "File $_ is a new configuration file.\n";
		} elsif ($_ =~ m/.*\.pacsave/ or $_ =~ m/.*\.pacorig/) {
			print "File $_ is a configuration file from a removed package.\n";
		}
	}, no_chdir => 1}, $directory);
}

###################
# Untracked Files #
###################
my %pathsToSkip = (
	# thang : maybe don't hardcode these?
	'/home' => 1,
	'/var' => 1,
);

sub read_mounts {
	my $filename = '/proc/mounts';
	open my $input, '<', $filename or die "Failed to open '$filename' for reading.\n";

	my %known_filesystems = ( # thang : read this from /proc/filesystems?
		sysfs => 0,
		rootfs => 0,
		ramfs => 0,
		bdev => 0,
		proc => 0,
		cpuset => 0,
		cgroup => 0,
		tmpfs => 0,
		devtmpfs => 0,
		binfmt_misc => 0,
		configfs => 0,
		debugfs => 0,
		tracefs => 0,
		securityfs => 0,
		sockfs => 0,
		pipefs => 0,
		devpts => 0,
		hugetlbfs => 0,
		autofs => 0,
		pstore => 0,
		mqueue => 0,
		ext3 => 1,
		ext2 => 1,
		ext4 => 1,
	);

	for my $line (<$input>) {
		chomp $line;
		my @arguments = split ' ', $line; # thang : this can fail is there is a space in the path...
		die unless @arguments == 6;
		my $path = $arguments[1];
		my $filesystemType = $arguments[2];

		my $shouldScan = $known_filesystems{$filesystemType};
		if (!$shouldScan) {
			$pathsToSkip{$path} = 1;
			if (!defined($shouldScan)) {
				warn "Warning: Unknown filesystem type '$filesystemType'.\n";
			}
		}
	}

	close $input;
}

sub scan_directory_for_untracked_files {
	my ($directory, $package_database) = @_;

	find({wanted => sub {
		if ($pathsToSkip{$_}) {
			print "Skipping '$_'.\n"; # thang : only print this if the --verbose flag is set.
			$File::Find::prune = 1;
		} else {
			unless ($package_database->{$_}) {
				print "File $_ is not owned by any package.\n";
			}
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

	process_options;

	read_mounts();

	if ($packages) {
		find_toplevel_dependency_packages();

		find_foreign_packages();

		find_out_of_date_packages();
	}

	if ($files) {
		find_partially_downloaded_packages();

		find_config_files('/etc');
	}

	if ($untrackedFiles) {
		my $package_database = read_package_database();

		scan_directory_for_untracked_files('/', $package_database);
	}
}

main;
