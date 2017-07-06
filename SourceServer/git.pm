# ------------------------------------------------------------------------
# git.pm
#
# Source Server module to handle adding version control information to
# PDB symbol files for source code that is stored in a Git repository.
#
# Copyright (c) 2009 ImaginaryRealities Software Company
# http://www.imaginaryrealities.com/post/2009/05/03/Indexing-source-code-in-Git-with-Source-Server.aspx
#
# With modifications by Jonathan Oliver (http://jonathan-oliver.blogspot.com)
# Forked 2017 by Per Hasselström to https://github.com/Perolus/SourceServer-GitExtensions
# ------------------------------------------------------------------------
package GIT;

require Exporter;
use strict;
use warnings;
use Cwd;
use Cwd 'abs_path';
use constant FILE_LOOKUP_TABLE => 'FILE_LOOKUP_TABLE';
 
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    
    $$self{FILE_LOOKUP_TABLE} = ();
    
    return($self);
}

sub GatherFileInformation {
    my $self = shift;
    my $sourcePath = shift;
	
	my $currentDirectory = getcwd();
	chdir($sourcePath);
	AddMatchingCandidatesToFileLookupTable($self); # TODO: try/catch
	chdir($currentDirectory);
	
    return(keys %{$$self{FILE_LOOKUP_TABLE}} != 0);
}
sub AddMatchingCandidatesToFileLookupTable {
	my $self = shift;
	
	my $repositoryPath = GetRootDirectoryOfRepository();
	foreach my $candidate (GetListOfCandidateFilesToBeIndexed()) {
		AddSourceIndexedCandidateToTable($self, $candidate, $repositoryPath);
    }
}
sub GetRootDirectoryOfRepository {
	my $commandToGetRelativeRepositoryRootDirectory = "git rev-parse --show-cdup";
	my $relativeRoot = ExecuteCommand($commandToGetRelativeRepositoryRootDirectory);
	
	if ($relativeRoot eq "") {
		$relativeRoot = ".";
	}
	
	my $fullPathToRoot = abs_path($relativeRoot) . "/";
	$fullPathToRoot = StandardizePathsToBackslash($fullPathToRoot);
	
	return($fullPathToRoot);
}
sub GetListOfCandidateFilesToBeIndexed {
	my $treeId = GetIdForRepositoryTree();

	my $candidates = `git --no-pager ls-tree -r --full-name $treeId`;
	return(split(/\n/, $candidates));
}
sub GetIdForRepositoryTree {
	return(ExecuteCommand("git --no-pager log -1 --pretty=format:\%T"));
}
sub AddSourceIndexedCandidateToTable {
	my $self = shift;
	my $lineToIndex = shift;
	my $repositoryPath = shift;
	
	if ($lineToIndex =~ m/^.*\s(.*)\t(.*)$/i) {
		my $objectId = $1;
		my $relativeFilePath = $2;
		my $localFile = StandardizeFilename($repositoryPath . $relativeFilePath);
		@{$$self{FILE_LOOKUP_TABLE}{$localFile}} = ( { }, "$localFile*$objectId" );
    }
}
sub StandardizeFilename {
	my $fileName = shift;
	
	$fileName = StandardizePathsToBackslash($fileName);
	$fileName = lc($fileName);
	
	return($fileName);
}
sub StandardizePathsToBackslash {
	my $path = shift;
	$path =~ s/\//\\/g;
	return ($path);
}

sub GetFileInfo {
    my $self = shift;
    my $localFile = shift;
	
	$localFile = StandardizeFilename($localFile);
	
    if (defined $$self{FILE_LOOKUP_TABLE}{$localFile}) {
        return(@{$$self{FILE_LOOKUP_TABLE}{$localFile}});
    }
	
	return(undef);
}

sub LongName {
    return("Git");
}

sub SourceStreamVariables {
    my $self = shift;
    my @stream;
	
	my $repositoryId  = GetRepositoryId();
	my $originNode = GetOriginRepository();
	my $gitBranch = GetGitBranch();
	
	push(@stream, "GIT_REPO_ID=$repositoryId");
	push(@stream, "GIT_ORIGIN_NODE=$originNode");
	push(@stream, "GIT_BRANCH=$gitBranch");
	push(@stream, "GIT_EXTRACT_TARGET=%targ%\\%GIT_REPO_ID%\\%var2%\\%fnfile%(%var1%)");
    push(@stream, "GIT_EXTRACT_CMD=gitcontents.bat \"%GIT_ORIGIN_NODE%\" \"%GIT_BRANCH%\" \"%targ%\\%GIT_REPO_ID%\\.localRepo\" %var2% \"%git_extract_target%\"");
    return (@stream);
}
sub GetRepositoryId {
	return(GetSha1OfFirstCommand());
}
sub GetSha1OfFirstCommand {
	my $result = `git rev-list --reverse --max-parents=0 HEAD`;
	my @ids = split(/\n/, $result);
	return($ids[0]);
}
sub GetOriginRepository {
	foreach my $repositoryToEvaluate(GetRemoteRepositories()) {
		if ($repositoryToEvaluate =~ m/^origin\s(.*)(\s\(fetch\)){0,1}$/i) {
			return($1);
		}
	}
	
	return(undef);
}
sub GetRemoteRepositories {
	my $remoteRepositories = `git --no-pager remote -v`;
	return(split(/\n/, $remoteRepositories));
}
sub GetGitBranch {
	my $returnBranch = `git rev-parse --abbrev-ref HEAD`;
	$returnBranch = RemoveTrailingLineBreakCharacter($returnBranch);
	return($returnBranch);
}

sub ExecuteCommand {
	my $commandToExecute = shift;
	
	my $commandOutput = `$commandToExecute`;
	
	if ($? < 0) {
		die "Execution of command \"$commandToExecute\" failed.";
	}
	
	$commandOutput = RemoveTrailingLineBreakCharacter($commandOutput);
	return($commandOutput);
}
sub RemoveTrailingLineBreakCharacter {
	my $valueToTrim = shift;
	$valueToTrim =~ s/[\n]+//g; # BUG: TOO GREEDY--only strip off the last line break
	return($valueToTrim);
}
