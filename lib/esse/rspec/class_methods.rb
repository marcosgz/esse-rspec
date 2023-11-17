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

      def stub_esse_search(*cluster_and_indexes, **definition) # Let's deprecated this method
        target = cluster_and_indexes.shift
        if target.is_a?(Symbol) || target.is_a?(String) && Esse.config.cluster_ids.include?(target.to_sym)
          target = Esse.cluster(target)
          definition[:index] ||= Esse::Search::Query.normalize_indices(*cluster_and_indexes)
        elsif target.is_a?(String) || target.is_a?(Symbol)
          definition[:index] ||= Esse::Search::Query.normalize_indices(target.to_s)
          target = Esse.cluster
        end

        response = yield
        expect(target).to esse_receive_request(:search).with(**definition).and_return(response)
      end
    end
  end
end
