# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.4 - 2023-11-15
* The `cluster_id` argument of `stub_esse_search` is useless when the given index is a Esse::Index. Cluster id is now optional.


## 0.0.3 - 2023-11-15
It should not automatically require `esse/rspec` anymore. You should require it manually in your `spec_helper.rb` file.

## 0.0.2 - 2023-11-15
* Whitelist rspec >= 3.0.0

## 0.0.1 - 2023-11-15
The first release of the Esse::RSpec
* stub_esse_class helper
* stub_esse_index helper
* stub_esse_search helper
