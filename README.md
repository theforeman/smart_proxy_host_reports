# Smart Proxy Host Reports

Transforms configuration and security management reports into Foreman-friendly JSON and sends them to a Foreman instance. For more information about Foreman JSON report format, visit [foreman_host_reports](https://github.com/theforeman/foreman_host_reports).

## Usage

Send a POST HTTP call to `/host_reports/FORMAT` where FORMAT is one of the following formats.

## Supported formats

The following formats are currently implemented.

### Puppet

Accepts Puppet Server YAML format:

* [Example input](test/fixtures/foreman-web.yaml)
* [Example output](test/snapshots/foreman-web.json)

## License

GNU GPLv3, see LICENSE file for more information.