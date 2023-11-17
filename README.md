# esse-rspec

RSpec and testing support for [esse](https://github.com/marcosgz/esse)

## Installation

Add this line to your application's Gemfile:

```ruby
group :test do
  gem 'esse-rspec'
end
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

## Mock Requests

Stub a search request to specific index and return a response

```ruby
allow(ProductsIndex).to esse_receive_request(:search)
  .with(body: {query: {match_all: {}}, size: 10})
  .and_return('hits' => { 'total' => 0, 'hits' => [] })

query = ProductsIndex.search(query: {match_all: {}}, size: 10)
query.response.total # => 0
```

Stub a search request to an index with a non 200 response

```ruby
allow(ProductsIndex).to esse_receive_request(:search)
  .with(body: {query: {match_all: {}}, size: 10})
  .and_raise_http_status(500, {"error" => 'Something went wrong'})

begin
  ProductsIndex.search(query: {match_all: {}}, size: 10).response
rescue Esse::Transport::InternalServerError => e
  puts e.message # => {"error" => 'Something went wrong'}
end
```

Stub a cluster search request

```ruby

allow(Esse.cluster(:default)).to esse_receive_request(:search)
  .with(index: 'geos_*', body: {query: {match_all: {}}, size: 10})
  .and_return('hits' => { 'total' => 0, 'hits' => [] })

query = Esse.cluster(:default).search('geos_*', body: {query: {match_all: {}}, size: 10})
query.response.total # => 0
```

Stub a api/transport request

```ruby
allow(Esse.cluster).to esse_receive_request(:get)
  .with(id: '1', index: 'products')
  .and_return('_id' => '1', '_source' => {title: 'Product 1'})

Esse.cluster.api.get('1', index: 'products') # => { '_id' => '1', '_source' => {title: 'Product 1'} }
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
