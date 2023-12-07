package Interpreter::Info;

use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
use IPC::System::Options 'readpipe', 'system', -log=>1;

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(
                       get_interpreter_info

                       get_perl_info
                       get_python_info
                       get_nodejs_info
                       get_ruby_info
                       get_bash_info

                       get_rakudo_info
               );

our %SPEC;

our %argspecs_common = (
    path => {
        summary => 'Choose specific path for interpreter',
        schema => 'filename*',
    },
);

$SPEC{get_perl_info} = {
    v => 1.1,
    summary => 'Get information about perl interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_perl_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/perl perl5/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to perl";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find perl in PATH"] unless defined $p;
    }

    my $out = readpipe({shell=>0}, $path, "-V");
    return [500, "Can't run $path -V: $!"] if $!;
    return [500, "$path -V exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /revision (\d+) version (\d+) subversion (\d+)/ or do {
            warn "Can't extract perl version";
            last;
        };
        $info->{version} = "$1.$2.$3";
    };

    [200, "OK", $info];
}

$SPEC{get_python_info} = {
    v => 1.1,
    summary => 'Get information about python interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_python_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/python3 python2 python/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to python";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find python in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v", "-c1");
    return [500, "Can't run $path -v -c1: $!"] if $!;
    return [500, "$path -v -c1 exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /^Python (\d+(?:\.\d+)+) /m or do {
            warn "Can't extract Python version";
            last;
        };
        $info->{version} = $1;
    };

    [200, "OK", $info];
}

$SPEC{get_nodejs_info} = {
    v => 1.1,
    summary => 'Get information about nodejs interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_nodejs_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/nodejs node/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to nodejs";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find nodejs in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v");
    return [500, "Can't run $path -v: $!"] if $!;
    return [500, "$path -v exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /^v(\d+(?:\.\d+)+)/m or do {
            warn "Can't extract nodejs version";
            last;
        };
        $info->{version} = $1;
    };

    [200, "OK", $info];
}

$SPEC{get_ruby_info} = {
    v => 1.1,
    summary => 'Get information about Ruby interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_ruby_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/ruby/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to ruby";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find ruby in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v");
    return [500, "Can't run $path -v: $!"] if $!;
    return [500, "$path -v exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /^^ruby (\d+(?:\.\d+)+(?:p\d+)?) /m or do {
            warn "Can't extract version";
            last;
        };
        $info->{version} = $1;
        $out =~ / \((\d{4}-\d{2}-\d{2})/m or do {
            warn "Can't extract release date";
            last;
        };
        $info->{release_date} = $1;
    };

    [200, "OK", $info];
}

$SPEC{get_bash_info} = {
    v => 1.1,
    summary => 'Get information about bash interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_bash_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/bash/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to bash";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find bash in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "--version");
    return [500, "Can't run $path --version: $!"] if $!;
    return [500, "$path --version exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /version ((\d+(?:\.\d+)+)\S*) /m or do {
            warn "Can't extract version";
            last;
        };
        $info->{version} = $1;
        $info->{version_simple} = $2;
    };

    [200, "OK", $info];
}

$SPEC{get_rakudo_info} = {
    v => 1.1,
    summary => 'Get information about rakudo interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_rakudo_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/rakudo/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to rakudo";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find rakudo in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v");
    return [500, "Can't run $path -v: $!"] if $!;
    return [500, "$path -v exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /v(\d+(?:\.\d+)+)/m or do {
            warn "Can't extract version";
            last;
        };
        $info->{version} = $1;
        $out =~ /^Implementing.+ v(\d+\.\w)/m or do {
            warn "Can't extract spec_version";
            last;
        };
        $info->{spec_version} = $1;
    };

    [200, "OK", $info];
}

1;
# ABSTRACT:
