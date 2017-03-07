#!/usr/bin/perl
# make a django project release
# e.g. ./makerelease.sh cdp cspace_django_project "latest BMU, other small improvements"

use strict;

if (scalar @ARGV != 3)  {
  die "Need three arguments: tag-prefix directory \"comment (can be empty)\"\n";
}

my ($TENANT, $PROJECT, $MSG) = @ARGV;

chdir $PROJECT or die("could not change to $PROJECT directory");
    
my @tags = `git tag --list ${TENANT}_*`;
if ($#tags < 0) {
   print "can't find tags for ${TENANT}_*\n";
   exit(1);
}

my (@parts, $revision, $branch, $last_revision, $revision);

foreach my $tag (@tags) {
    @parts = split(/[\-_]/, $tag);
    $revision = pop(@parts);
    $branch = join('_', @parts);

    if ($revision > $last_revision) {
        $last_revision = $revision;
    }
}

$last_revision++;
my $version_number = "$branch-$last_revision";
my $tag_message = "Release tag for django project $version_number.";
$tag_message .= ' ' . $MSG if $MSG;

print "verifying code is current...\n";
system "git pull -v";
print "creating changelog.txt...\n";
system "echo '$version_number $tag_message' > changelog.txt";
system "date >> changelog.txt ; echo >> changelog.txt";
system "git log --oneline --decorate >> changelog.txt";
system "git commit -a -m 'revise change log for version $version_number'";
print "git tag -a $version_number -m '$tag_message'\n";
system "git tag -a $version_number -m '$tag_message'";
system "git push --tags";

