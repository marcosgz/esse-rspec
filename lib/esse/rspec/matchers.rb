# frozen_string_literal: true
module Esse
  module RSpec
    module Matchers

      class EsseReceiveRequest
        include ::RSpec::Matchers::Composable

        STATUS_ERRORS = {
          300 => Esse::Transport::MultipleChoicesError,
          301 => Esse::Transport::MovedPermanentlyError,
          302 => Esse::Transport::FoundError,
          303 => Esse::Transport::SeeOtherError,
          304 => Esse::Transport::NotModifiedError,
          305 => Esse::Transport::UseProxyError,
          307 => Esse::Transport::TemporaryRedirectError,
          308 => Esse::Transport::PermanentRedirectError,
          400 => Esse::Transport::BadRequestError,
          401 => Esse::Transport::UnauthorizedError,
          402 => Esse::Transport::PaymentRequiredError,
          403 => Esse::Transport::ForbiddenError,
          404 => Esse::Transport::NotFoundError,
          405 => Esse::Transport::MethodNotAllowedError,
          406 => Esse::Transport::NotAcceptableError,
          407 => Esse::Transport::ProxyAuthenticationRequiredError,
          408 => Esse::Transport::RequestTimeoutError,
          409 => Esse::Transport::ConflictError,
          410 => Esse::Transport::GoneError,
          411 => Esse::Transport::LengthRequiredError,
          412 => Esse::Transport::PreconditionFailedError,
          413 => Esse::Transport::RequestEntityTooLargeError,
          414 => Esse::Transport::RequestURITooLongError,
          415 => Esse::Transport::UnsupportedMediaTypeError,
          416 => Esse::Transport::RequestedRangeNotSatisfiableError,
          417 => Esse::Transport::ExpectationFailedError,
          418 => Esse::Transport::ImATeapotError,
          421 => Esse::Transport::TooManyConnectionsFromThisIPError,
          426 => Esse::Transport::UpgradeRequiredError,
          450 => Esse::Transport::BlockedByWindowsParentalControlsError,
          494 => Esse::Transport::RequestHeaderTooLargeError,
          497 => Esse::Transport::HTTPToHTTPSError,
          499 => Esse::Transport::ClientClosedRequestError,
          500 => Esse::Transport::InternalServerError,
          501 => Esse::Transport::NotImplementedError,
          502 => Esse::Transport::BadGatewayError,
          503 => Esse::Transport::ServiceUnavailableError,
          504 => Esse::Transport::GatewayTimeoutError,
          505 => Esse::Transport::HTTPVersionNotSupportedError,
          506 => Esse::Transport::VariantAlsoNegotiatesError,
          510 => Esse::Transport::NotExtendedError
        }

        def initialize(*args)
          @transport_method = args.shift
          unless Esse::Transport.instance_methods.include?(@transport_method)
            raise ArgumentError, "expected #{@transport_method.inspect} to be a Esse::Transport method"
          end

          @definition = {}
          if (hash = args.last).is_a?(Hash)
            @definition.merge!(hash.transform_keys(&:to_sym))
          end
        end

        def description
          "esse receive request"
        end

        def matches?(index_or_cluster)
          normalize_actual_args!(index_or_cluster)
          allow(@cluster).to receive(:api).and_return(transport)
          allow(transport).to receive_expected
          receive_expected.matches?(transport)
        end

        def with(**definition)
          @definition.update(definition)
          self
        end

        def with_status(status, response = nil)
          @error_class = STATUS_ERRORS[status] || Esse::Transport::ServerError
          @response = response if response
          self
        end

        def and_return(response)
          @response = response
          self
        end

        def and_raise(error_class, response = nil)
          @error_class = error_class
          @response = response if response
          self
        end

        def and_call_original
          @and_call_original = true
          self
        end

        def exactly(times)
          @times = times
          self
        end

        def once
          exactly(1)
        end

        def twice
          exactly(2)
        end

        def at_least(times)
          @at_least = times
          self
        end

        def at_most(times)
          @at_most = times
          self
        end

        def failure_message
          "expected that #{@cluster.id} cluster would receive `#{@transport_method}` with #{@definition}".tap do |str|
            if @error_class
              str << " and raise #{@error_class}"
              str << " with #{@response}" if @response
            elsif @response
              str << " and return #{@response}"
            end
          end
        end

        def failure_message_when_negated
          "expected that #{@cluster.id} cluster would not receive `#{@transport_method}` with #{@definition}".tap do |str|
            if @error_class
              str << " and raise #{@error_class}"
              str << " with #{@response}" if @response
            elsif @response
              str << " and return #{@response}"
            end
          end
        end

        private

        def transport
          @cluster.api
        end

        def normalize_actual_args!(index_or_cluster)
          if index_or_cluster.is_a?(Esse::Cluster)
            @cluster = index_or_cluster
          elsif index_or_cluster.is_a?(Class) && index_or_cluster < Esse::Index
            @definition[:index] ||= Esse::Search::Query.normalize_indices(index_or_cluster)
            @cluster ||= index_or_cluster.cluster
          elsif index_or_cluster.is_a?(Symbol) || index_or_cluster.is_a?(String)
            if Esse.config.cluster_ids.include?(index_or_cluster.to_sym)
              @cluster = Esse.cluster(index_or_cluster)
            end
          end
          raise ArgumentError, "expected #{index_or_cluster.inspect} to be an Esse::Index or Esse::Cluster" unless @cluster
        end

        def supports_block_expectations?
          false
        end

        private

        def allow(target)
          ::RSpec::Mocks::AllowanceTarget.new(target)
        end

        def receive(method_name)
          ::RSpec::Mocks::Matchers::Receive.new(method_name, nil)
        end

        def receive_expected
          @receive_expected ||= begin
            matcher = receive(@transport_method).with(**@definition)
            matcher = matcher.and_return(@response) if defined?(@response)
            matcher = matcher.and_raise(*[@error_class, @response].compact) if @error_class
            matcher = matcher.and_call_original if defined?(@and_call_original)
            if @times
              matcher = matcher.exactly(@times).times
            elsif @at_least
              matcher = matcher.at_least(@at_least).times
            elsif @at_most
              matcher = matcher.at_most(@at_most).times
            end
            matcher
          end
        end
      end

      def esse_receive_request(*args)
        EsseReceiveRequest.new(*args)
      end
      alias_method :receive_esse_request, :esse_receive_request
    end
  end
end
