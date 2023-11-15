# esse-rspec

RSpec and testing support for [esse](https://github.com/marcosgz/esse)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'esse-rspec'
```

And then execute:

```bash
$ bundle
```

## Usage

Require the `esse/rspec` file in your `spec_helper.rb` file:

```ruby
require 'esse/rspec'
```

### Stubbing Esse::Index classes

```ruby
before do
  stub_esse_index('products') do
    repository :product, const: true do
      # ...
    end
  end
end

it 'defines the ProductsIndex class' do
  expect(ProductsIndex).to be < Esse::Index
  expect(ProductsIndex::Product).to be < Esse::Index::Repository
end
```

### Stubbing search requests

```ruby
before do
  stub_esse_search(:default, "geos_*", body: {query: {match_all: {}}, size: 10}) do
    {
      "hits" => {
        "total" => {
          "value" => 1000
        },
        "hits" => [{}] * 20
      }
    }
  end
end

it 'returns a Query using the stubbed response' do
  query = ProductsIndex.search('geos_*', body: {query: {match_all: {}}, size: 10})
  expect(query.responsee.total).to eq(1000)
end
```
