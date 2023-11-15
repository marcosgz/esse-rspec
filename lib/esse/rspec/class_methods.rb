# frozen_string_literal: true

# Helper methods to create Index classes
module Esse
  module RSpec
    module ClassMethods
      def stub_esse_index(name, superclass = nil, &block)
        superclass ||= ::Esse::Index
        klass_name = "#{::Esse::Hstring.new(name).camelize.sub(/Index$/, "")}Index"
        klass = stub_esse_class(klass_name, superclass)
        klass.class_eval(&block) if block
        klass
      end

      def stub_esse_class(name, superclass = nil, &block)
        klass = Class.new(superclass || Object, &block)
        stub_const(Esse::Hstring.new(name).camelize.to_s, klass)
      end

      def stub_esse_search(cluster_name, *indexes, **definition)
        cluster = Esse.cluster(cluster_name)
        transport = cluster.api
        definition[:index] ||= Esse::Search::Query.normalize_indices(*indexes)
        response = yield
        allow(cluster).to receive(:api).and_return(transport)
        allow(transport).to receive(:search).with(**definition).and_return(response)
      end
    end
  end
end
