# Smart Proxy Host Reports

Transforms configuration and security management reports into Foreman-friendly JSON and sends them to a Foreman instance. For more information about Foreman JSON report format, visit [foreman_host_reports](https://github.com/theforeman/foreman_host_reports).

## Usage

Send a POST HTTP call to `/host_reports/FORMAT` where FORMAT is one of the following formats.

## Puppet

Accepts Puppet Server YAML format:

* [Example input](test/fixtures/foreman-web.yaml)
* [Example output](test/snapshots/foreman-web.json)

## Contributing

Fork and send a Pull Request. Thanks!

## License

GNU GPLv3, see LICENSE file for more information.

## Copyright

Copyright (c) 2021 Red Hat, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
