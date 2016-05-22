## [Unreleased][unreleased]

## [2.2.4] - 2016-05-21
- Add debug logging

## [2.2.3] - 2016-03-16
- Capture status code and raw body when response is not json.

## [2.2.2] - 2016-03-15
- Update dependencies

## [2.2.1] - 2016-01-01
- Improve MailChimpError logging

## [2.2.0] - 2015-12-01
- Adds support for proxies
- Adds support for faraday_adapters

## [2.1.3] - 2015-11-26
- Fixes issue #159, which prevented sending campaigns from working. Thanks to @q3-tech for the bug report.

## [2.1.2] - 2015-11-11
- Allow Faraday default\_connection\_options to be set

## [2.1.1] - 2015-11-05
- Fix surfacing unparseable Faraday request exception.

## [2.1.0] - 2015-10-12
- Upsert support

## [2.0.0] - 2015-7-28
- Support for API 3.0. Usage syntax has changed. Please check out the readme.
- Update MultiJSON dependency to 1.11.0
- Switch to Faraday
- Fix: Handle empty response payloads on delete

## [1.2.0] - 2015-07-16
- Same as 1.1.6 but rereleased because it's a breaking change
- Support for Ruby 2 streaming with Export API. Now returns an Array of Array of Strings instead of an Array of Strings.
- Fix a bug that caused calling methods statically on Gibbon::Export to fail

## [1.1.6] - 2015-06-04 (Yanked)
- Support for Ruby 2 streaming with Export API

## [1.1.5] - 2015-02-19
- Update MultiJSON dependency to 1.9.0
- Handle single empty space in Export API response

## [1.1.4] - 2012-11-04
- Fix JSON::ParserError on export calls that return blank results

[unreleased]: https://github.com/amro/gibbon/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/amro/gibbon/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/amro/gibbon/compare/v1.1.5...v1.2.0
[1.1.5]: https://github.com/amro/gibbon/compare/v1.1.5...v1.1.4
[1.1.4]: https://github.com/amro/gibbon/compare/v1.1.3...v1.1.4
