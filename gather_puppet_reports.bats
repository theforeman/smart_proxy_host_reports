#!/usr/bin/env bats
#
# This file attempts to gather various reports by creating some conditions.
# From puppet agent --help for --detailed-exitcodes
# * --detailed-exitcodes:
#  Provide extra information about the run via exit codes; works only if '--test'
#  or '--onetime' is also specified. If enabled, 'puppet agent' uses the
#  following exit codes:
#
#  0: The run succeeded with no changes or failures; the system was already in
#  the desired state.
#
#  1: The run failed, or wasn't attempted due to another run already in progress.
#
#  2: The run succeeded, and some resources were changed.
#
#  4: The run succeeded, and some resources failed.
#
#  6: The run succeeded, and included both changes and failures.

ENV_DIR="/etc/puppetlabs/code/environments/production"
MANIFEST="${ENV_DIR}/manifests/site.pp"
REPORT_DIR="/opt/puppetlabs/server/data/puppetserver/reports/$HOSTNAME"
INDEX="/var/www/html/index.html"

# Needs at least bats 1.2.1 - Bats in EPEL7 is too old
setup_file() {
	. /etc/os-release

	# Install puppetserver
	yum -y install https://yum.puppet.com/puppet-release-el-${VERSION_ID}.noarch.rpm
	yum -y install puppetserver curl

	# Ensure puppet is in $PATH
	source /etc/profile.d/puppet-agent.sh

	# Ensure reports are stored
	puppet config set reports store

	# Configure the agent to talk to this master
	puppet config set server $HOSTNAME

	# Ensure the agent is stopped
	systemctl disable --now puppet

	# Clean out any reports
	rm -rf "$REPORT_DIR"

	# Enable & start the service
	systemctl enable --now puppetserver

	# Clean up the system
	yum -y remove httpd
	rm -f "$INDEX"
}

teardown_file() {
	cp -r "$BATS_RUN_TMPDIR"/test puppet-gather-$$
}

teardown() {
	mv "$REPORT_DIR"/*.yaml "$BATS_TEST_TMPDIR"
	puppet config set noop false
}

@test "initial run with empty manifest" {
	cat > "$MANIFEST" <<-EOF
	EOF

	puppet agent --test --detailed-exitcodes
}

@test "run with failure" {
	cat > "$MANIFEST" <<-EOF
	node "$HOSTNAME" {
	  # Will fail due to a typo in the package name
	  package { 'htttpd':
	    ensure => installed,
	  } ->
	  # Should be skipped since it requires htttpd
	  file { '$INDEX':
	    ensure => file,
	    content => "Hello World\\n",
	  } ~>
	  # Technically not really needed to restart Apache if it changes
	  # but it makes future testing easier
	  service { 'httpd':
	    ensure => running,
	    enable => true,
	  }
	}
	EOF

	run -4 puppet agent --test --detailed-exitcodes
}

@test "install apache" {
	cat > "$MANIFEST" <<-EOF
	node "$HOSTNAME" {
	  package { 'httpd':
	    ensure => installed,
	  } ->
	  file { '$INDEX':
	    ensure => file,
	    content => "Hello World\\n",
	  } ~>
	  # Technically not really needed to restart Apache if it changes
	  # but it makes future testing easier
	  service { 'httpd':
	    ensure => running,
	    enable => true,
	  }
	}
	EOF

	run -2 puppet agent --test --detailed-exitcodes

	curl http://$HOSTNAME | grep "Hello World"
}

@test "restart apache" {
	echo "This will trigger an Apache restart" > "$INDEX"

	run -2 puppet agent --test --detailed-exitcodes

	curl http://$HOSTNAME | grep "Hello World"
}

@test "unchanged" {
	puppet agent --test --detailed-exitcodes

	curl http://$HOSTNAME | grep "Hello World"
}

@test "unrelated failure" {
	cat > "$MANIFEST" <<-EOF
	node "$HOSTNAME" {
	  # Unrelated failure: puppet can't write to a file without the parent
	  file { '/path/that/does/not/exist/causes/failures':
	    ensure => file,
	  }

	  # This should still pass
	  package { 'httpd':
	    ensure => installed,
	  } ->
	  file { '$INDEX':
	    ensure => file,
	    content => "Hello World\\n",
	  } ~>
	  # Technically not really needed to restart Apache if it changes
	  # but it makes future testing easier
	  service { 'httpd':
	    ensure => running,
	    enable => true,
	  }
	}
	EOF

	run -4 puppet agent --test --detailed-exitcodes

	curl http://$HOSTNAME | grep "Hello World"
}

@test "full install again" {
	yum -y remove httpd
	rm -f "$INDEX"

	run -6 puppet agent --test --detailed-exitcodes

	curl http://$HOSTNAME | grep "Hello World"
}

@test "noop run" {
        yum -y remove httpd
        rm -f "$INDEX"

        puppet config set noop true
        puppet agent --test --detailed-exitcodes

        run -7 curl http://$HOSTNAME
}

@test "remove error again" {
	cat > "$MANIFEST" <<-EOF
	node "$HOSTNAME" {
	  package { 'httpd':
	    ensure => installed,
	  } ->
	  file { '$INDEX':
	    ensure => file,
	    content => "Hello World\\n",
	  } ~>
	  # Technically not really needed to restart Apache if it changes
	  # but it makes future testing easier
	  service { 'httpd':
	    ensure => running,
	    enable => true,
	  }
	}
	EOF

	run -2 puppet agent --test --detailed-exitcodes

	curl http://$HOSTNAME | grep "Hello World"
}

# vim: ft=bash
