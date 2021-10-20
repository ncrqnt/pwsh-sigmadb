# CHANGELOG

# v0.3.0

General improvements towards export:
* Changed config file type to YAML
+ Added automatic import to elasticsearch's detection engine (disabled by default in config.yml)
+ Added normalization of all/provided fields (disabled by default in config.yml)
+ Added workaround for hex numbers not getting quoted (e.g. 0x100 --> '0x100')
+ Smaller changes and cosmetic improvements

# v0.2.0

+ Added CI capabilities with [Pester](https://pester.dev/), [InvokeBuild](https://github.com/nightroman/Invoke-Build)
  + Build / Dependency scripts
  + Tests (PS Script Analyzer and Pester)
  + GitHub Actions Workflows
+ Added PowerShell Script Analyzer Settings
+ Added changelog

# v0.0.1

Initial release with the basic functionality