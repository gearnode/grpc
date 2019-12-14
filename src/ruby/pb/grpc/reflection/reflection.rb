require 'grpc'
require 'grpc/reflection/v1alpha/reflection_services_pb'
require 'grpc/errors'

module Grpc
  module Reflection
    class Reflect < V1alpha::Reflection::Service
      def initialize(server)
        @server = server
      end

      def server_reflection_info(call)
        out = ServerReflectionResponse.new
        call.each_remote_read do |req|
          out.valid_host = req.host
          out.original_request = req

          case req.message_request
          when :file_by_filename
            puts "file by name request"
          when :file_containing_symbol
            puts "file containing symbol request"
          when :file_containing_extension
            puts "file containing extension request"
          when :all_extension_numbers_of_type
            puts "all extension numbers of type request"
          when :list_services
            puts "list services request"
          else
            raise GRPC::InvalidArgument, "invalid message request"
          end
        end
      end
    end
  end
end
