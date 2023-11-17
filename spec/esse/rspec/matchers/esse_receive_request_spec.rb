# frozen_string_literal: true

require "spec_helper"

::RSpec.describe Esse::RSpec::Matchers::EsseReceiveRequest do
  describe "initialize" do
    it "raises an error if the argument is not a Esse::Transport method" do
      expect {
        described_class.new(:foo)
      }.to raise_error(ArgumentError, "expected :foo to be a Esse::Transport method")
    end

    it "initializes @transport_method" do
      expect(described_class.new(:search).instance_variable_get(:@transport_method)).to eq(:search)
    end

    it "initializes @definition with given args" do
      matcher = described_class.new(:search, :foo, bar: :baz)
      expect(matcher.instance_variable_get(:@definition)).to eq({bar: :baz})
    end

    it "symbolizes keys of the definition" do
      matcher = described_class.new(:search, "foo", "bar" => :baz)
      expect(matcher.instance_variable_get(:@definition)).to eq({bar: :baz})
    end
  end

  describe "#with" do
    it "initializes @definition with the given args" do
      matcher = described_class.new(:search).with(foo: :bar)
      expect(matcher.instance_variable_get(:@definition)).to eq({foo: :bar})
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.with(foo: :bar)).to be(matcher)
    end

    it "does not replace the initial definition" do
      matcher = described_class.new(:search, foo: :bar).with(bar: :baz)
      expect(matcher.instance_variable_get(:@definition)).to eq({foo: :bar, bar: :baz})
    end
  end

  describe "#with_status" do
    it "initializes @error_class with the given status" do
      matcher = described_class.new(:search).with_status(404)
      expect(matcher.instance_variable_get(:@error_class)).to eq(Esse::Transport::NotFoundError)
    end

    it "initializes @response with the given response" do
      matcher = described_class.new(:search).with_status(404, "foo")
      expect(matcher.instance_variable_get(:@response)).to eq("foo")
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.with_status(404)).to be(matcher)
    end
  end

  describe "#and_return" do
    it "initializes @response with the given response" do
      matcher = described_class.new(:search).and_return("foo")
      expect(matcher.instance_variable_get(:@response)).to eq("foo")
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.and_return("foo")).to be(matcher)
    end
  end

  describe "#and_raise" do
    it "initializes @error_class with the given error class" do
      matcher = described_class.new(:search).and_raise(Esse::Transport::NotFoundError)
      expect(matcher.instance_variable_get(:@error_class)).to eq(Esse::Transport::NotFoundError)
    end

    it "initializes @response with the given response" do
      matcher = described_class.new(:search).and_raise(Esse::Transport::NotFoundError, "foo")
      expect(matcher.instance_variable_get(:@response)).to eq("foo")
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.and_raise(Esse::Transport::NotFoundError)).to be(matcher)
    end
  end

  describe "#exactly" do
    it "initializes @times with the given number" do
      matcher = described_class.new(:search).exactly(2)
      expect(matcher.instance_variable_get(:@times)).to eq(2)
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.exactly(2)).to be(matcher)
    end
  end

  describe "#once" do
    it "initializes @times with 1" do
      matcher = described_class.new(:search).once
      expect(matcher.instance_variable_get(:@times)).to eq(1)
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.once).to be(matcher)
    end
  end

  describe "#twice" do
    it "initializes @times with 2" do
      matcher = described_class.new(:search).twice
      expect(matcher.instance_variable_get(:@times)).to eq(2)
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.twice).to be(matcher)
    end
  end

  describe "#at_least" do
    it "initializes @at_least with the given number" do
      matcher = described_class.new(:search).at_least(2)
      expect(matcher.instance_variable_get(:@at_least)).to eq(2)
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.at_least(2)).to be(matcher)
    end
  end

  describe "#at_most" do
    it "initializes @at_most with the given number" do
      matcher = described_class.new(:search).at_most(2)
      expect(matcher.instance_variable_get(:@at_most)).to eq(2)
    end

    it "returns self" do
      matcher = described_class.new(:search)
      expect(matcher.at_most(2)).to be(matcher)
    end
  end

  describe "#setup_expectation" do
    let(:raw_response) do
      {
        "hits" => {
          "total" => {
            "value" => 1,
            "relation" => "eq"
          },
          "max_score" => 1.0,
          "hits" => [
            {"_index" => "test", "_type" => "_doc", "_id" => "1", "_score" => 1.0, "_source" => {"title" => "Test"}}
          ]
        }
      }
    end
    let(:cluster) { Esse.cluster(:default) }

    before do
      stub_esse_index(:products)
    end

    it "returns a mock expectation with a cluster instance" do
      matcher = described_class.new(:search, index: "test", q: "*").and_return(raw_response)
      expect(matcher.matches?(cluster)).to be_an_instance_of(RSpec::Mocks::MessageExpectation)
      cluster.search("test", q: "*").response
    end

    it "returns a mock expectation with a given index class" do
      matcher = described_class.new(:search, index: "products", q: "*")
      expect(matcher.matches?(ProductsIndex)).to be_an_instance_of(RSpec::Mocks::MessageExpectation)
      ProductsIndex.search("*").response
    end

    it "returns a mock expectation with a given cluster id" do
      matcher = described_class.new(:search, index: "test", q: "*")
      expect(matcher.matches?(:default)).to be_an_instance_of(RSpec::Mocks::MessageExpectation)
      Esse.cluster(:default).search("test", q: "*").response
    end

    it "raises an error if the cluster is not found" do
      matcher = described_class.new(:search, index: "test", q: "*")
      expect {
        matcher.matches?(:foo)
      }.to raise_error(ArgumentError, "expected :foo to be an Esse::Index or Esse::Cluster")
    end

    context "when stubbing :api method" do
      let(:raw_response) do
        {"_id" => 1, "_source" => {"title" => "Test"}}
      end

      it "returns the mocked response" do
        expect(cluster).to esse_receive_request(:get, index: "test", id: 1).and_return(raw_response)
        expect(cluster.api.get(index: "test", id: 1)).to eq(raw_response)
      end
    end

    context "with rspec matcher" do
      it "returns the mocked response" do
        expect(cluster).to esse_receive_request(:search, index: "test", q: "*").and_return(raw_response)
        expect(resp = cluster.search("test", q: "*").response).to be_an_instance_of(Esse::Search::Response)
        expect(resp.raw_response).to eq(raw_response)
      end

      it "returns the mocked response with a given index class" do
        expect(ProductsIndex).to esse_receive_request(:search, index: "products", q: "*").and_return(raw_response)
        expect(resp = ProductsIndex.search("*").response).to be_an_instance_of(Esse::Search::Response)
        expect(resp.raw_response).to eq(raw_response)
      end

      it "raises the transport error according to the given status" do
        expect(cluster).to esse_receive_request(:search, index: "test", q: "*").with_status(404, error_msg = {"error" => "not found"})
        query = cluster.search("test", q: "*")
        expect {
          query.response
        }.to raise_error { |error|
          error.is_a?(Esse::Transport::NotFoundError) && error.message == error_msg
        }
      end

      it "mocks the transport but calls the real method" do
        expect(cluster).to esse_receive_request(:search, index: "test", q: "*").and_call_original
        expect {
          cluster.search("test", q: "*").response
        }.to raise_error(Esse::Error).with_message(/is not defined/)
      end

      it "mocks the transport but calls the real method with a given index class" do
        expect(ProductsIndex).to esse_receive_request(:search, index: "products", q: "*").and_call_original
        expect {
          ProductsIndex.search("*").response
        }.to raise_error(Esse::Error).with_message(/is not defined/)
      end

      it "allows to receive the request twice" do
        expect(cluster).to esse_receive_request(:search, index: "test", q: "*").twice.and_return(raw_response)
        expect(cluster.search("test", q: "*").response).to be_an_instance_of(Esse::Search::Response)
        expect(cluster.search("test", q: "*").response).to be_an_instance_of(Esse::Search::Response)
      end
    end
  end
end
