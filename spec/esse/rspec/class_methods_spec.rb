require "spec_helper"

::RSpec.describe Esse::RSpec::ClassMethods do
  include described_class

  describe ".stub_esse_index" do
    it "creates an Esse::Index subclass" do
      index_class = stub_esse_index("test")
      expect(index_class).to be_a(Class)
      expect(index_class).to be < Esse::Index
      expect(TestIndex).to be(index_class)
    end

    it "removes the Index suffix from the class name" do
      index_class = stub_esse_index("test_index")
      expect(index_class.name).to eq("TestIndex")
    end

    it "yields the class to the block" do
      index_class = stub_esse_index(:test) do
        self.index_name = "my_test"
      end
      expect(index_class.index_name).to eq("my_test")
    end

    it "stub the index class with repository constant" do
      index_class = stub_esse_index(:projects) do
        repository(:project, const: true) do
        end
      end
      expect(index_class.repo_hash).to have_key("project")
      expect(index_class.repo_hash["project"]).to be(ProjectsIndex::Project)
    end
  end

  describe ".stub_esse_class" do
    it "creates an Esse class" do
      klass = stub_esse_class("test")
      expect(klass).to be_a(Class)
      expect(klass).to be < Object
      expect(Test).to be(klass)
    end

    it "yields the class to the block" do
      klass = stub_esse_class(:test) do
        def self.foo
          "bar"
        end
      end
      expect(klass.foo).to eq("bar")
    end
  end

  describe ".stub_esse_search" do
    it "stubs the search method of the cluster" do
      cluster = Esse.cluster(:default)
      expect(cluster).to receive(:search).with("test", {q: "*"}).and_call_original
      stub_esse_search(:default, "test", q: "*") do
        {"hits" => {"total" => {"value" => 1}}}
      end

      query = cluster.search("test", q: "*")
      expect(query).to be_a(Esse::Search::Query)
      expect(query.response.total).to eq(1)
    end
  end
end
